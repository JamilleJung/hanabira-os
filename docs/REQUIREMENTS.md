# Acceptance ledger

This records actual delivery state, not promises. Each phase must update its
evidence before being marked verified. The full request is SPECIFICATION.md.

| Requirement | Baseline / current gate |
| --- | --- |
| Debian foundation + BIOS/UEFI live boot | Original Plasma prototype verified; new HDE build pending |
| Custom Rust/Smithay compositor | Implementation started; nested backend first |
| Native DRM/KMS, independent outputs, fractional scaling | Pending |
| Real app windows, input, move/resize/focus | Compositor smoke acceptance pending |
| Custom layer-shell panel/dock/launcher/wallpaper | Implementation started; launch real apps and inspect screenshots |
| Three themes + motion + Thai typography | Assets retained; HDE theme acceptance pending |
| Desktop shortcuts/context menu, drag/drop, workspaces | Pending |
| Real control center/settings | Implement only backed controls; remaining sections pending |
| Notifications, media, history, DND | Pending integration |
| Secure lockscreen/PAM greeter | Pending; decorative windows are not secure locking |
| XWayland, clipboard, IME, portals, screen sharing, accessibility | Pending protocol acceptance |
| Native Debian HDE packages + build-iso entry point | Implementation started |
| Branded installer / disposable VM installation / installed boot | Backend integration started; installation unverified |
| First-run wizard | Pending |
| Intel/AMD/NVIDIA, hybrid, suspend/resume, Secure Boot | Physical hardware validation pending |
| 240 Hz and mixed-refresh performance | No claim; capture/analysis tools started |
| Source bundles, signing, reproducible bytes | Provenance tooling exists; full release/source/signing validation pending |

The fallback Plasma session is retained while HDE is incomplete. It is not the
final desktop architecture. Do not call the ISO production-ready while these
gates remain open.
