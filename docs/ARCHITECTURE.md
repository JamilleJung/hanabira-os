# HDE architecture

Hanabira's user-facing desktop is developed in `desktop/`, separately from the
Debian live-build recipe. Original assets and the earlier Plasma rescue
configuration remain under `config/includes.chroot`.

| Component | Implementation / boundary |
| --- | --- |
| `hanabira-compositor` | Rust + Smithay; owns Wayland protocols, input, window placement, focus and output rendering. Nested EGL starts the development path; native DRM/KMS is a subsequent acceptance gate. |
| `hanabira-shell` | Qt Quick native scene graph; one process hosts wallpaper, panel, dock, launcher and supported controls using layer-shell surfaces. It does not own authentication or privileged storage operations. |
| `hanabira-core` | Dependency-free Rust spring motion and frame-time analysis; no background thread or network telemetry. |
| `hanabira-session` | Environment and process supervision, installed as a Debian package. Only verified backends become default sessions. |
| `hanabira-installer` | Branded Calamares configuration with its proven storage backend. Installation acceptance uses disposable VM disks. |

## IPC and privilege boundaries

Wayland `xdg-shell` hosts applications. `zwlr_layer_shell_v1` hosts shell
surfaces with exclusive zones, so application input does not get swallowed by
a fullscreen overlay. The launcher resolves installed desktop entries and
launches programs as the session user. System controls use existing D-Bus
services such as NetworkManager, UPower and login1 where implemented; no root
shell commands or decorative successful toggles substitute for a real backend.

Locking requires the Wayland session-lock protocol and PAM. Until it is
implemented and tested, no Hanabira decorative window is advertised as a
secure lock screen. Portals, accessibility, XWayland and secure authentication
are separate compatibility gates recorded in REQUIREMENTS.md.

## Rendering and measurement

Animations use elapsed time, with reduced motion completing immediately.
Static surfaces should stop scheduling frames when no damage or animation is
pending. Nested backend measurements describe submission timing in the host
session; hardware presentation and input latency need DRM presentation data.
The 240 Hz target has a 4.167 ms interval and must be checked against measured
P95/P99 intervals, utilization and idle power. The measurement tool does not
infer physical refresh rates or hardware support from a configuration value.

Primary implementation references: [Smithay backends](https://smithay.github.io/smithay/smithay/backend/index.html),
[Smithay shell protocols](https://smithay.github.io/smithay/smithay/wayland/shell/index.html),
[Qt Quick scene graph](https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph.html).
