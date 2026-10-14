# Hanabira OS

Hanabira OS is an independent Debian 13 (`trixie`) operating-system project.
Its custom Hanabira Desktop Environment (HDE) is being built with Rust/Smithay
and Qt Quick. The existing Plasma live image is retained as a rescue and
development environment while the native HDE backend is incomplete.
This repository contains the compositor, shell, shared motion/measurement
code, Debian packaging, installer integration and live-build recipe.

Hanabira OS is based on Debian and uses KDE software, but is not affiliated
with or endorsed by either project. See [ASSETS.md](ASSETS.md) for artwork and
third-party notices. [ภาษาไทย / Thai preview notes](PREVIEW-TH.md).

## Status

The original live prototype booted in QEMU via BIOS and UEFI into Plasma at
1280×800. The repository audit and exact baseline are in [docs/AUDIT.md](docs/AUDIT.md).
HDE is an early implementation, not a production desktop. Follow the
[acceptance ledger](docs/REQUIREMENTS.md) for verified capabilities and open
requirements, and [architecture](docs/ARCHITECTURE.md) for component boundaries.
The complete user specification is [docs/SPECIFICATION.md](docs/SPECIFICATION.md).

The project aims for a coherent light/dark anime-inspired desktop with
responsive layout and smooth effects. Performance targets, including 240 Hz,
require measurement on supported hardware; they are not promised by the
preview image. The ISO includes Debian `main` and `non-free-firmware` but no
proprietary NVIDIA driver. In particular, RTX 50-series support needs a
separate, tested driver path before this image is recommended for those GPUs.

## Build a local preview

Use a Debian 13 VM with enough free storage for the chroot and ISO. Install
`live-build`, `debootstrap`, `xorriso`, `squashfs-tools`, `syslinux`,
`grub-pc-bin`, `grub-efi-amd64-bin`, `mtools`, `dosfstools`, and
`ca-certificates`, then run:

```sh
sudo ./scripts/build.sh
./scripts/verify-iso.sh
```

On a Linux machine with rootless Podman, `./scripts/build-container.sh` uses a
Debian 13 build container. This container requires privileged mounts inside
Podman's user namespace for `live-build`. A clean build is the default; set
`HANABIRA_CLEAN=false` only when intentionally reusing generated build state.
Package downloads and the build can consume several gigabytes and take a while.

The expected binary is `hanabira-live-amd64.hybrid.iso`. A build also writes
`hanabira-live-build-recipe.tar.gz`, `BUILDINFO.txt`, `SHA256SUMS`, a package
manifest and `build.log`. The recipe tarball is **not** the corresponding source
archive for the Debian binaries in the ISO. Use the public-release procedure in
[docs/RELEASE.md](docs/RELEASE.md) before distributing an image.

For a first VM boot test without a writable disk:

```sh
qemu-system-x86_64 -enable-kvm -m 4G -cdrom hanabira-live-amd64.hybrid.iso
```

`-enable-kvm` can be omitted if virtualization is unavailable. Run
`./scripts/check-source.sh` for static source checks without building an ISO.

## Project layout

| Path | Purpose |
| --- | --- |
| `auto/config` | Debian `live-build` options and ISO identity |
| `config/package-lists/` | Explicit packages installed in the live system |
| `config/includes.chroot/` | Default Plasma settings and project artwork |
| `desktop/compositor/` | Custom Rust/Smithay Wayland compositor |
| `desktop/shell/` | Native Qt Quick HDE surfaces and controls |
| `desktop/core/` | Time-based motion and measured frame-time analysis |
| `packaging/`, `installer/` | Native Debian packages and installer configuration |
| `config/bootloaders/` | BIOS/UEFI menu artwork and templates |
| `scripts/` | Build, validation and artifact packaging |
| `docs/` | Roadmap, reproducibility and release process |

## Contributing and licensing

See [CONTRIBUTING.md](CONTRIBUTING.md) for changes and testing. The original
build recipe and scripts are MIT-licensed; the original wallpapers and boot
artwork are CC BY 4.0. Debian and KDE packages retain their own licenses.
The exact file scopes and credits are in [ASSETS.md](ASSETS.md).

The live ISO is built from current Debian 13 repositories, so two builds at
different times need not be byte-identical. See
[docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md) for the recorded provenance
and limits. The release plan is in [docs/ROADMAP.md](docs/ROADMAP.md).
