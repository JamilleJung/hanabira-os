# Hanabira compositor

This is the first **working, nested** Wayland compositor for Hanabira Desktop Environment (HDE). It runs inside an existing Wayland or X11 session and creates a new Wayland socket for the HDE shell and ordinary applications. It uses Smithay 0.7.0 with EGL/GLES rendering. It is not yet a native login session: `--backend drm` exits with an error until a DRM/KMS + libinput backend is built.

The compositor currently implements `xdg-shell` toplevels and popups, `zwlr_layer_shell_v1` for the wallpaper, top panel, dock and launcher, pointer and keyboard input, window move and resize requests, maximize and fullscreen, SHM and Linux DMA-BUF buffers, clipboard data devices, and xdg-output. It maps window surfaces below the top/overlay layers and above the background layer. Clients receive configure and frame callbacks. Redraws are requested by commits, input and host resize, with Smithay output damage tracking; there is no unconditional 60 Hz render loop. The nested output reports its host monitor's refresh rate when available (or unknown/0 otherwise).

The Super key invokes the shell's `org.hanabira.Shell.ToggleLauncher` D-Bus method through `gdbus`; the image needs the GLib command-line tools for this shortcut. Other input goes to the focused client. The launcher overlay can request exclusive keyboard focus.

## Build and run

On a Debian 13 build host install Rust 1.85.1 or newer, `pkg-config`, Wayland development headers, EGL/GLES development headers and xkbcommon development headers. Then run:

```sh
cargo +1.85.1 build --release --locked --manifest-path desktop/compositor/Cargo.toml
desktop/compositor/target/release/hanabira-compositor \
  --backend nested \
  --shell /usr/bin/hanabira-shell \
  --command /usr/bin/alacritty
```

`XDG_RUNTIME_DIR` and a working host `WAYLAND_DISPLAY` or `DISPLAY` are required for the nested backend. `--shell` and `--command` accept executable paths and launch them against the newly created Wayland socket. They may be omitted when connecting a client manually to the printed socket. The shell binary must have LayerShellQt available at runtime.

For compositor output QA, add `--screenshot /absolute/path.png`. After two seconds it reads back one rendered GLES frame, waiting for three shell layer surfaces when `--shell` is set and an app when `--command` is set. This captures the compositor's actual image, rather than the shell's preview mode.

For performance analysis, add `--frame-log /absolute/path.csv` or set `HANABIRA_FRAME_LOG`. The CSV contains `timestamp_ns,kind`, with `kind=submitted`. Timestamps are monotonic nanoseconds since compositor startup. Each row marks a successful EGL buffer **submission**, not hardware presentation or scanout. It must not be interpreted as measured display FPS.

## Verification and current limits

`cargo +1.85.1 test --locked --manifest-path desktop/compositor/Cargo.toml` checks the CLI parser. A nested smoke test with LayerShellQt HDE shell and Alacritty has also confirmed actual output, layer stacking, xdg configure, window content, GPU frame submission, and the launcher's D-Bus method. The latest local output captures are in `.build/qa/` (ignored from Git).

Native DRM/KMS, libinput device and hotplug handling, Xwayland, multi-output management, presentation-time feedback, and a compositor-drawn hardware cursor are still outstanding. The nested backend depends on its host compositor for scanout and cannot claim direct 240 Hz presentation. On some NVIDIA nested-Wayland drivers, querying `EGL_EXT_buffer_age` returns `EGL_BAD_SURFACE`; Hanabira detects this once and uses full repaint on subsequent redraws while retaining event-driven idle behavior. A later native backend should use real page-flip timing and presentation feedback.

The initial Wayland state, event-loop structure and pointer-grab code were adapted from the MIT-licensed [Smithay Smallvil example](https://github.com/Smithay/smithay/tree/v0.7.0/smallvil) at Smithay v0.7.0 (`a166cf4c94b5aedc332a65aa1dd753e8148829c3`), then extended for HDE. See [SMITHAY-LICENSE.txt](SMITHAY-LICENSE.txt). This repository's compositor changes are also MIT licensed.
