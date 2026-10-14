# Hanabira Desktop shell

`hanabira-shell` is the native Qt 6 Quick user interface for HDE. It renders a static wallpaper, interactive desktop shortcuts, a floating panel and dock, a searchable application launcher, and quick settings as Wayland layer-shell surfaces. Qt Quick renders through the graphics backend selected by Qt and the compositor; idle wallpaper and panels have no animation loop.

## Build and run

The release build needs Qt 6 Core, Gui, Qml, Quick, QuickControls2, DBus, GIO (`gio-2.0` and `gio-unix-2.0`), and LayerShellQt. On Debian 13, install the corresponding development packages, including `libglib2.0-dev` and `liblayershellqtinterface-dev`.

```sh
cmake -S desktop/shell -B build/hde-shell -DHANABIRA_REQUIRE_LAYER_SHELL=ON
cmake --build build/hde-shell -j4
```

Run `build/hde-shell/hanabira-shell` in a Wayland session whose compositor advertises `zwlr_layer_shell_v1`. The HDE session starts the compositor and shell together. The shell owns the D-Bus service `org.hanabira.Shell`, object `/Shell`, with `ToggleLauncher`, `ShowLauncher`, and `HideLauncher` methods for compositor key bindings.

For development without LayerShellQt or a Wayland session, omit `HANABIRA_REQUIRE_LAYER_SHELL` and use a single-window preview:

```sh
cmake -S desktop/shell -B build/hde-shell-preview
cmake --build build/hde-shell-preview -j4
build/hde-shell-preview/hanabira-shell --preview
build/hde-shell-preview/hanabira-shell --preview-launcher --preview-query Terminal --capture /tmp/hanabira-launcher.png
build/hde-shell-preview/hanabira-shell --self-test
```

`--preview-size 800x600`, `--preview-quick-settings`, and `--theme dream|midnight|celestial` help inspect responsive layouts. `--search-apps QUERY` prints matching desktop IDs; `--launch-desktop ID` launches one installed entry for integration tests.

## Real controls and current scope

Application search and launch use GIO desktop entries. The dock resolves its pinned entries to installed apps; defaults are Browser, Files, Terminal, and Editor when available. Desktop files and folders come from the user's Desktop directory. Double-clicking an executable shortcut owned by the user, or a symlink to `/usr/share/applications`, launches it; other files open through the system's default handler. These checks prevent an arbitrary untrusted `.desktop` file from executing on a double-click.

Quick Settings persists the three appearance choices and changes the wallpaper, icon theme, and UI palette together. Volume and mute invoke `wpctl` asynchronously when PipeWire's command is available. Media title, artist, cover, playback status, and Play/Pause/Previous/Next come from MPRIS over D-Bus. The battery readout comes from `/sys/class/power_supply`. Unavailable controls are hidden or labelled as unavailable; buttons shown in the shell have real handlers.

Each monitor gets independently sized layer surfaces. The primary monitor presents desktop shortcuts; changes to monitor geometry resize its wallpaper, overlays, panel, and dock. Layer-shell exclusive zones reserve space above and below application windows. Wallpaper rendering is static; hover transitions run only during interaction.

This first slice does not yet have a task/window list, pinning UI, notification center, network or Bluetooth controls, power-session actions, drag placement for desktop icons, or a lock screen. Those require compositor/session integration or privileged system services. Native DRM login and display management are tracked in the compositor project. Screenshot preview mode uses Qt's offscreen renderer; it does not measure GPU performance in a real Wayland session.

Artwork and font credits are in the repository's `ASSETS.md`.
