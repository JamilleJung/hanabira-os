# Contributing to Hanabira OS

Hanabira OS is an early live-image project. Small, testable changes are easiest
to review. Open an issue with a screenshot or hardware details for visual or
performance problems; include the ISO version, GPU, display resolution and
scaling, session type, steps to reproduce, and what actually happened. Please
omit private data from logs and screenshots.

For a code change, run `./scripts/check-source.sh`. For changes to the package
list, bootloader, wallpaper defaults or live-session behavior, make a fresh ISO
with `HANABIRA_CLEAN=true`, run `./scripts/verify-iso.sh`, and boot both BIOS
and UEFI QEMU paths if possible. State which checks you actually performed in
the pull request. Do not claim a hardware or frame-rate result from a VM test.

Keep the source tree free of generated `binary/`, `chroot/`, `cache/`, ISO and
log files; `.gitignore` excludes them. If adding fonts, icons, audio, images,
firmware or software from elsewhere, include provenance, license, required
attribution and redistribution information. Keep license notices with the
work. The project has no installer yet, so changes should not write to the
host's disks during a normal live boot.

Project-authored code and documentation contributions are accepted under MIT;
original artwork contributions need an explicit compatible license and credit
entry in `ASSETS.md`. Package sources retain their upstream licenses.
