# Roadmap

The roadmap states intended work, not guarantees or released features.

## 0.1 — live foundation

- Rebrand the verified Debian/Plasma live recipe as Hanabira OS.
- Boot-test the new ISO through BIOS and UEFI, validate checksums and document
  the package set, artwork and build provenance.
- Keep local disks untouched by the default live session.

## 0.2 — desktop design system

- Ship coherent light and dark palettes, wallpapers, icon treatment, fonts,
  dock/panel sizing, launcher treatment and app defaults.
- Test that color-mode changes affect the full desktop; ensure desktop icons,
  launcher icons and media controls remain usable.
- Check layouts at laptop and external-display sizes with fractional scaling.

## 0.3 — hardware and performance

- Verify compositor behavior, animations and power use at idle and under load.
- Measure real frame pacing on 60/120/144/240 Hz displays instead of claiming
  a fixed frame rate. Test mixed-refresh and multi-monitor setups.
- Add a compatible and redistributable NVIDIA driver path only after testing
  supported hardware, including RTX 50-series, plus Intel/AMD fallbacks.

## 0.4 — installation and public release

- Design and test an installer with explicit disk selection, recovery and
  rollback. Do not add unattended partitioning.
- Provide a corresponding source image, upstream notices, signed release
  artifacts and a supported update plan.
- Test a release candidate in VMs and on spare physical hardware before
  describing it as suitable for daily use.
