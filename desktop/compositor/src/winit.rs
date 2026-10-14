use std::{
    cell::RefCell,
    fs::File,
    io::{BufWriter, Write},
    path::Path,
    rc::Rc,
    time::Duration,
};

use smithay::{
    backend::{
        allocator::Fourcc,
        egl::EGLDevice,
        renderer::{
            damage::OutputDamageTracker,
            element::surface::WaylandSurfaceRenderElement,
            gles::{GlesMapping, GlesRenderer},
            ExportMem, ImportDma, ImportEgl, ImportMemWl,
        },
        winit::{self, WinitEvent},
    },
    output::{Mode, Output, PhysicalProperties, Subpixel},
    reexports::calloop::EventLoop,
    utils::{Physical, Size, Transform},
    wayland::dmabuf::DmabufFeedbackBuilder,
};

use crate::{CalloopData, Hanabira};

pub fn init_winit(
    event_loop: &mut EventLoop<CalloopData>,
    data: &mut CalloopData,
) -> Result<(), Box<dyn std::error::Error>> {
    let display_handle = &mut data.display_handle;
    let state = &mut data.state;

    let (mut backend, winit) = winit::init::<GlesRenderer>()?;

    let refresh = backend
        .window()
        .current_monitor()
        .and_then(|monitor| monitor.refresh_rate_millihertz())
        .unwrap_or(0)
        .min(i32::MAX as u32) as i32;

    let mode = Mode {
        size: backend.window_size(),
        refresh,
    };

    let output = Output::new(
        "winit".to_string(),
        PhysicalProperties {
            size: (0, 0).into(),
            subpixel: Subpixel::Unknown,
            make: "Smithay".into(),
            model: "Winit".into(),
        },
    );
    let _global = output.create_global::<Hanabira>(display_handle);
    output.change_current_state(
        Some(mode),
        Some(Transform::Flipped180),
        None,
        Some((0, 0).into()),
    );
    output.set_preferred(mode);

    state.space.map_output(&output, (0, 0));
    let formats = backend.renderer().dmabuf_formats();
    let feedback = EGLDevice::device_for_display(backend.renderer().egl_context().display())
        .ok()
        .and_then(|device| device.try_get_render_node().ok().flatten())
        .and_then(|node| {
            DmabufFeedbackBuilder::new(node.dev_id(), formats.clone())
                .build()
                .ok()
        });
    if let Some(feedback) = feedback {
        state
            .dmabuf_state
            .create_global_with_default_feedback::<Hanabira>(display_handle, &feedback);
    } else {
        state
            .dmabuf_state
            .create_global::<Hanabira>(display_handle, formats);
    }
    if let Err(error) = backend.renderer().bind_wl_display(display_handle) {
        tracing::warn!(
            ?error,
            "EGL wl_drm binding unavailable; DMA-BUF remains enabled"
        );
    }
    state
        .shm_state
        .update_formats(backend.renderer().shm_formats());
    state.backend = Some(Rc::new(RefCell::new(backend)));
    state.request_redraw();

    let mut damage_tracker = OutputDamageTracker::from_output(&output);
    let mut buffer_age_supported = true;

    std::env::set_var("WAYLAND_DISPLAY", &state.socket_name);

    event_loop.handle().insert_source(winit, move |event, _, data| {
        let display = &mut data.display_handle;
        let state = &mut data.state;

        match event {
            WinitEvent::Resized { size, .. } => {
                let refresh = state.backend.as_ref().and_then(|backend| {
                    backend.borrow().window().current_monitor()
                        .and_then(|monitor| monitor.refresh_rate_millihertz())
                }).unwrap_or(0).min(i32::MAX as u32) as i32;
                output.change_current_state(
                    Some(Mode {
                        size,
                        refresh,
                    }),
                    None,
                    None,
                    None,
                );
                output.set_preferred(Mode { size, refresh });
                smithay::desktop::layer_map_for_output(&output).arrange();
                state.request_redraw();
            }
            WinitEvent::Input(event) => state.process_input_event(event),
            WinitEvent::Redraw => {
                let layer_count = smithay::desktop::layer_map_for_output(&output).layers().count();
                let app_count = state.space.elements().filter(|window| {
                    let size = window.geometry().size;
                    size.w > 0 && size.h > 0
                }).count();
                let capture_path = if state.screenshot_ready
                    && (!state.screenshot_needs_layer || layer_count >= 3)
                    && (!state.screenshot_needs_app || app_count > 0) {
                    state.screenshot.take()
                } else { None };
                let backend = state.backend.as_ref().unwrap().clone();
                let mut backend = backend.borrow_mut();
                // Query after bind, then remember if this driver rejects the
                // extension. NVIDIA nested Wayland EGL can return BAD_SURFACE;
                // age zero is Smithay's correct full repaint fallback.
                let age = if buffer_age_supported {
                    let _ = backend.bind().unwrap();
                    match backend.buffer_age() {
                        Some(age) => age,
                        None => {
                            buffer_age_supported = false;
                            tracing::warn!("EGL buffer age unavailable; using full repaint on redraw");
                            0
                        }
                    }
                } else { 0 };
                let size = backend.window_size();
                let (render_result, screenshot_mapping) = {
                    let (renderer, mut framebuffer) = backend.bind().unwrap();
                    let result = smithay::desktop::space::render_output::<
                        _,
                        WaylandSurfaceRenderElement<GlesRenderer>,
                        _,
                        _,
                    >(
                        &output,
                        renderer,
                        &mut framebuffer,
                        1.0,
                        age,
                        [&state.space],
                        &[],
                        &mut damage_tracker,
                        [0.1, 0.1, 0.1, 1.0],
                    )
                    .unwrap();
                    let mapping = capture_path.as_ref().and_then(|path| {
                        let region = smithay::utils::Rectangle::new((0, 0).into(), (size.w, size.h).into());
                        match renderer.copy_framebuffer(&framebuffer, region, Fourcc::Abgr8888) {
                            Ok(mapping) => Some(mapping),
                            Err(error) => {
                                tracing::error!(?error, path = %path.display(), "output readback failed");
                                None
                            }
                        }
                    });
                    (result, mapping)
                };
                if let Some(damage) = render_result.damage {
                    match backend.submit(Some(damage)) {
                        Ok(()) => {
                            if let Some(log) = &mut state.frame_log {
                                let _ = writeln!(log, "{},submitted", state.start_time.elapsed().as_nanos());
                            }
                        }
                        Err(error) => {
                            tracing::error!(?error, "nested EGL frame submission failed");
                            state.loop_signal.stop();
                        }
                    }
                }
                if let (Some(path), Some(mapping)) = (capture_path, screenshot_mapping) {
                    match save_mapping_png(backend.renderer(), &mapping, size, &path) {
                        Ok(()) => eprintln!("Hanabira output screenshot: {}", path.display()),
                        Err(error) => tracing::error!(?error, path = %path.display(), "output screenshot failed"),
                    }
                }
                drop(render_result);
                drop(backend);

                state.space.elements().for_each(|window| {
                    window.send_frame(
                        &output,
                        state.start_time.elapsed(),
                        Some(Duration::ZERO),
                        |_, _| Some(output.clone()),
                    )
                });
                let map = smithay::desktop::layer_map_for_output(&output);
                for layer in map.layers() {
                    layer.send_frame(
                        &output,
                        state.start_time.elapsed(),
                        Some(Duration::ZERO),
                        |_, _| Some(output.clone()),
                    );
                }

                state.space.refresh();
                state.popups.cleanup();
                let _ = display.flush_clients();

                // Commits and input request the next frame; an idle desktop never loops here.
            }
            WinitEvent::CloseRequested => {
                state.loop_signal.stop();
            }
            _ => (),
        };
    })?;

    Ok(())
}

fn save_mapping_png(
    renderer: &mut GlesRenderer,
    mapping: &GlesMapping,
    size: Size<i32, Physical>,
    path: &Path,
) -> Result<(), Box<dyn std::error::Error>> {
    let width = u32::try_from(size.w)?;
    let height = u32::try_from(size.h)?;
    let pixels = renderer.map_texture(mapping)?;
    let row_bytes = width as usize * 4;
    let mut top_down = Vec::with_capacity(pixels.len());
    for row in pixels.chunks_exact(row_bytes).rev() {
        top_down.extend_from_slice(row);
    }
    let mut encoder = png::Encoder::new(BufWriter::new(File::create(path)?), width, height);
    encoder.set_color(png::ColorType::Rgba);
    encoder.set_depth(png::BitDepth::Eight);
    encoder.write_header()?.write_image_data(&top_down)?;
    Ok(())
}
