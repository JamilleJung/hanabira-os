# Verified baseline — 2026-10-15

The user specification is preserved in [SPECIFICATION.md](SPECIFICATION.md).
This audit precedes the custom HDE implementation.

## Repository and build

- Existing remote: `JamilleJung/hanabira-os`, `main`, initial README commit
  `d48c83f`. The local branch now retains that parent; no history was deleted.
- Debian 13 `trixie`, amd64, official `main` and `non-free-firmware`, systemd,
  live-build, hybrid ISO with Syslinux BIOS and GRUB EFI boot records.
- Original Sakura prototype ISO SHA-256:
  `fe7fd1fd136dcad71d5a970919b38a7a4b62d2c4d6b084c1e08aa1e3facfeb21`.
  Checksum and both boot records were rechecked. Prior QEMU BIOS/UEFI tests
  reached Plasma automatically at 1280×800. The artifact is preserved outside
  the source tree in `../sakura-preview-archive/`.
- `./scripts/check-source.sh` passed. The newly branded Hanabira configuration
  had not been built or boot-tested at this baseline.
- Existing work includes original wallpapers, SVG icons, licensed fonts,
  Plasma Day/Night themes, boot art, static CI and build/release documentation.
  It is retained as a fallback and asset source.

## Missing at baseline

There was no HDE compositor, shell, native Debian package, installer, secure
Hanabira lock screen, first-run app, custom settings backend or performance
capture. Plasma owned window management and desktop interactions. The Global
Theme layout script and new SDDM/GTK defaults had only static checks. Source
bundles are optional and the live recipe follows mutable Debian repositories;
byte-identical reproducibility is not established.

## Architecture decision

Start a real vertical slice using Rust/Smithay for a nested Wayland compositor
and Qt Quick for the layer-shell UI. This lets real Wayland applications run
under Hanabira's window manager without replacing the host session. The next
backend is native DRM/KMS/libinput. An unavailable backend must fail explicitly.
Plasma remains a labelled rescue session while native HDE startup is incomplete.
No production, installation or 240 FPS claim follows from a nested smoke test.
