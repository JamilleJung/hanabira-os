use std::{
    cell::RefCell, collections::HashMap, ffi::OsString, fs::File, path::PathBuf, rc::Rc, sync::Arc,
};

use smithay::{
    backend::{
        allocator::dmabuf::Dmabuf,
        renderer::{gles::GlesRenderer, ImportDma},
        winit::WinitGraphicsBackend,
    },
    desktop::{layer_map_for_output, PopupManager, Space, Window, WindowSurfaceType},
    input::{Seat, SeatState},
    reexports::{
        calloop::{generic::Generic, EventLoop, Interest, LoopSignal, Mode, PostAction},
        wayland_server::{
            backend::{ClientData, ClientId, DisconnectReason},
            protocol::wl_surface::WlSurface,
            Display, DisplayHandle,
        },
    },
    utils::{Logical, Point, Rectangle},
    wayland::{
        compositor::{CompositorClientState, CompositorState},
        dmabuf::{DmabufGlobal, DmabufHandler, DmabufState, ImportNotifier},
        output::OutputManagerState,
        selection::data_device::DataDeviceState,
        shell::{
            wlr_layer::{Layer, WlrLayerShellState},
            xdg::XdgShellState,
        },
        shm::ShmState,
        socket::ListeningSocketSource,
    },
};

use crate::CalloopData;

pub struct Hanabira {
    pub start_time: std::time::Instant,
    pub socket_name: OsString,
    pub display_handle: DisplayHandle,

    pub space: Space<Window>,
    pub loop_signal: LoopSignal,

    // Smithay State
    pub compositor_state: CompositorState,
    pub xdg_shell_state: XdgShellState,
    pub layer_shell_state: WlrLayerShellState,
    pub shm_state: ShmState,
    pub output_manager_state: OutputManagerState,
    pub seat_state: SeatState<Hanabira>,
    pub data_device_state: DataDeviceState,
    pub popups: PopupManager,

    pub seat: Seat<Self>,
    pub backend: Option<Rc<RefCell<WinitGraphicsBackend<GlesRenderer>>>>,
    pub dmabuf_state: DmabufState,
    pub frame_log: Option<File>,
    pub screenshot: Option<PathBuf>,
    pub screenshot_ready: bool,
    pub screenshot_needs_layer: bool,
    pub screenshot_needs_app: bool,
    pub super_held: bool,
    pub restore_geometry: HashMap<WlSurface, Rectangle<i32, Logical>>,
}

impl Hanabira {
    pub fn new(event_loop: &mut EventLoop<CalloopData>, display: Display<Self>) -> Self {
        let start_time = std::time::Instant::now();

        let dh = display.handle();

        let compositor_state = CompositorState::new::<Self>(&dh);
        let xdg_shell_state = XdgShellState::new::<Self>(&dh);
        let layer_shell_state = WlrLayerShellState::new::<Self>(&dh);
        let shm_state = ShmState::new::<Self>(&dh, vec![]);
        let output_manager_state = OutputManagerState::new_with_xdg_output::<Self>(&dh);
        let mut seat_state = SeatState::new();
        let data_device_state = DataDeviceState::new::<Self>(&dh);
        let popups = PopupManager::default();

        // A seat is a group of keyboards, pointer and touch devices.
        // A seat typically has a pointer and maintains a keyboard focus and a pointer focus.
        let mut seat: Seat<Self> = seat_state.new_wl_seat(&dh, "winit");

        // Notify clients that we have a keyboard, for the sake of the example we assume that keyboard is always present.
        // You may want to track keyboard hot-plug in real compositor.
        seat.add_keyboard(Default::default(), 200, 25).unwrap();

        // Notify clients that we have a pointer (mouse)
        // Here we assume that there is always pointer plugged in
        seat.add_pointer();

        // A space represents a two-dimensional plane. Windows and Outputs can be mapped onto it.
        //
        // Windows get a position and stacking order through mapping.
        // Outputs become views of a part of the Space and can be rendered via Space::render_output.
        let space = Space::default();

        let socket_name = Self::init_wayland_listener(display, event_loop);

        // Get the loop signal, used to stop the event loop
        let loop_signal = event_loop.get_signal();

        Self {
            start_time,
            display_handle: dh,

            space,
            loop_signal,
            socket_name,

            compositor_state,
            xdg_shell_state,
            layer_shell_state,
            shm_state,
            output_manager_state,
            seat_state,
            data_device_state,
            popups,
            seat,
            backend: None,
            dmabuf_state: DmabufState::new(),
            frame_log: None,
            screenshot: None,
            screenshot_ready: false,
            screenshot_needs_layer: false,
            screenshot_needs_app: false,
            super_held: false,
            restore_geometry: HashMap::new(),
        }
    }

    fn init_wayland_listener(
        display: Display<Hanabira>,
        event_loop: &mut EventLoop<CalloopData>,
    ) -> OsString {
        // Creates a new listening socket, automatically choosing the next available `wayland` socket name.
        let listening_socket = ListeningSocketSource::new_auto().unwrap();

        // Get the name of the listening socket.
        // Clients will connect to this socket.
        let socket_name = listening_socket.socket_name().to_os_string();

        let loop_handle = event_loop.handle();

        loop_handle
            .insert_source(listening_socket, move |client_stream, _, state| {
                // Inside the callback, you should insert the client into the display.
                //
                // You may also associate some data with the client when inserting the client.
                state
                    .display_handle
                    .insert_client(client_stream, Arc::new(ClientState::default()))
                    .unwrap();
            })
            .expect("Failed to init the wayland event source.");

        // You also need to add the display itself to the event loop, so that client events will be processed by wayland-server.
        loop_handle
            .insert_source(
                Generic::new(display, Interest::READ, Mode::Level),
                |_, display, state| {
                    // Safety: we don't drop the display
                    unsafe {
                        display
                            .get_mut()
                            .dispatch_clients(&mut state.state)
                            .unwrap();
                        // Wayland replies must be flushed after dispatch. Relying on the
                        // renderer's next frame deadlocks clients on an idle desktop.
                        display.get_mut().flush_clients().unwrap();
                    }
                    Ok(PostAction::Continue)
                },
            )
            .unwrap();

        socket_name
    }

    pub fn surface_under(
        &self,
        pos: Point<f64, Logical>,
    ) -> Option<(WlSurface, Point<f64, Logical>)> {
        let output = self.space.output_under(pos).next()?;
        let output_geo = self.space.output_geometry(output)?;
        let layers = layer_map_for_output(output);
        let relative = pos - output_geo.loc.to_f64();
        for layer in [Layer::Overlay, Layer::Top] {
            if let Some(hit) = layers.layer_under(layer, relative).and_then(|surface| {
                let location = layers.layer_geometry(surface)?.loc;
                surface
                    .surface_under(relative - location.to_f64(), WindowSurfaceType::ALL)
                    .map(|(surface, point)| (surface, (point + location + output_geo.loc).to_f64()))
            }) {
                return Some(hit);
            }
        }
        self.space
            .element_under(pos)
            .and_then(|(window, location)| {
                window
                    .surface_under(pos - location.to_f64(), WindowSurfaceType::ALL)
                    .map(|(s, p)| (s, (p + location).to_f64()))
            })
            .or_else(|| {
                for layer in [Layer::Bottom, Layer::Background] {
                    if let Some(hit) = layers.layer_under(layer, relative).and_then(|surface| {
                        let location = layers.layer_geometry(surface)?.loc;
                        surface
                            .surface_under(relative - location.to_f64(), WindowSurfaceType::ALL)
                            .map(|(surface, point)| {
                                (surface, (point + location + output_geo.loc).to_f64())
                            })
                    }) {
                        return Some(hit);
                    }
                }
                None
            })
    }

    pub fn request_redraw(&self) {
        if let Some(backend) = &self.backend {
            backend.borrow().window().request_redraw();
        }
    }
}

impl DmabufHandler for Hanabira {
    fn dmabuf_state(&mut self) -> &mut DmabufState {
        &mut self.dmabuf_state
    }

    fn dmabuf_imported(
        &mut self,
        _global: &DmabufGlobal,
        dmabuf: Dmabuf,
        notifier: ImportNotifier,
    ) {
        let imported = self
            .backend
            .as_ref()
            .map(|backend| {
                backend
                    .borrow_mut()
                    .renderer()
                    .import_dmabuf(&dmabuf, None)
                    .is_ok()
            })
            .unwrap_or(false);
        if imported {
            let _ = notifier.successful::<Hanabira>();
        } else {
            notifier.failed();
        }
    }
}

smithay::delegate_dmabuf!(Hanabira);

#[derive(Default)]
pub struct ClientState {
    pub compositor_state: CompositorClientState,
}

impl ClientData for ClientState {
    fn initialized(&self, _client_id: ClientId) {}
    fn disconnected(&self, _client_id: ClientId, _reason: DisconnectReason) {}
}
