# Acceptance ledger

This records actual delivery state, not promises. Each phase must update its
evidence before being marked verified. The full request is SPECIFICATION.md.

| Requirement | Baseline / current gate |
| --- | --- |
| Debian foundation + BIOS/UEFI live boot | Original Plasma prototype verified; new HDE build pending |
| Custom Rust/Smithay compositor | Nested EGL backend builds on Rust 1.85.1; real Wayland clients and shell render |
| Native DRM/KMS, independent outputs, fractional scaling | Pending |
| Real app windows, input, move/resize/focus | Protocols implemented; real app smoke passed; full interaction journey still pending |
| Custom layer-shell panel/dock/launcher/wallpaper | Native UI and real nested rendering passed; desktop-entry search/launch tested |
| Three themes + motion + Thai typography | Dream/Midnight/Celestial render at several sizes; font assets licensed; full accessibility QA pending |
| Desktop shortcuts/context menu, drag/drop, workspaces | Pending |
| Real control center/settings | Implement only backed controls; remaining sections pending |
| Notifications, media, history, DND | MPRIS metadata and async controls implemented; notifications/history/DND pending |
| Secure lockscreen/PAM greeter | Pending; decorative windows are not secure locking |
| XWayland, clipboard, IME, portals, screen sharing, accessibility | Pending protocol acceptance |
| Native Debian HDE packages + build-iso entry point | Five packages built on Debian 13; complete build-iso command produced checked 1735 MiB ISO |
| Branded installer / disposable VM installation / installed boot | Branded Calamares UI loads; installation/installed boot pending |
| First-run wizard | Pending |
| Intel/AMD/NVIDIA, hybrid, suspend/resume, Secure Boot | Physical hardware validation pending |
| 240 Hz and mixed-refresh performance | No claim; capture/analysis tools started |
| Source bundles, signing, reproducible bytes | Provenance tooling exists; full release/source/signing validation pending |

The fallback Plasma session is retained while HDE is incomplete. It is not the
final desktop architecture. Do not call the ISO production-ready while these
gates remain open.
