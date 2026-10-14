use smithay::{
    delegate_layer_shell,
    desktop::{layer_map_for_output, LayerSurface, WindowSurfaceType},
    output::Output,
    reexports::wayland_server::protocol::{wl_output, wl_surface::WlSurface},
    utils::SERIAL_COUNTER,
    wayland::{
        compositor::with_states,
        shell::wlr_layer::{
            KeyboardInteractivity, Layer, LayerSurface as WlrLayerSurface, LayerSurfaceData,
            WlrLayerShellHandler, WlrLayerShellState,
        },
    },
};

use crate::Hanabira;

impl WlrLayerShellHandler for Hanabira {
    fn shell_state(&mut self) -> &mut WlrLayerShellState {
        &mut self.layer_shell_state
    }

    fn new_layer_surface(
        &mut self,
        surface: WlrLayerSurface,
        wl_output: Option<wl_output::WlOutput>,
        _layer: Layer,
        namespace: String,
    ) {
        let output = wl_output
            .as_ref()
            .and_then(Output::from_resource)
            .or_else(|| self.space.outputs().next().cloned());
        if let Some(output) = output {
            let mut map = layer_map_for_output(&output);
            if map
                .map_layer(&LayerSurface::new(surface, namespace))
                .is_ok()
            {
                self.request_redraw();
            }
        }
    }

    fn layer_destroyed(&mut self, surface: WlrLayerSurface) {
        if let Some((mut map, layer)) = self.space.outputs().find_map(|output| {
            let map = layer_map_for_output(output);
            let layer = map
                .layers()
                .find(|layer| layer.layer_surface() == &surface)
                .cloned();
            layer.map(|layer| (map, layer))
        }) {
            map.unmap_layer(&layer);
            self.request_redraw();
        }
    }
}

delegate_layer_shell!(Hanabira);

/// Apply size/exclusive-zone changes before first configure and after every commit.
pub fn handle_commit(state: &mut Hanabira, surface: &WlSurface) {
    let Some(output) = state
        .space
        .outputs()
        .find(|output| {
            layer_map_for_output(output)
                .layer_for_surface(surface, WindowSurfaceType::TOPLEVEL)
                .is_some()
        })
        .cloned()
    else {
        return;
    };

    let initial_configure_sent = with_states(surface, |states| {
        states
            .data_map
            .get::<LayerSurfaceData>()
            .map(|data| data.lock().unwrap().initial_configure_sent)
            .unwrap_or(false)
    });
    let mut map = layer_map_for_output(&output);
    map.arrange();
    let layer = map
        .layer_for_surface(surface, WindowSurfaceType::TOPLEVEL)
        .cloned();
    drop(map);

    if let Some(layer) = layer {
        if !initial_configure_sent {
            layer.layer_surface().send_configure();
        }
        if matches!(layer.layer(), Layer::Top | Layer::Overlay)
            && layer.cached_state().keyboard_interactivity == KeyboardInteractivity::Exclusive
        {
            if let Some(keyboard) = state.seat.get_keyboard() {
                keyboard.set_focus(
                    state,
                    Some(layer.wl_surface().clone()),
                    SERIAL_COUNTER.next_serial(),
                );
            }
        }
        state.request_redraw();
    }
}
