# Hanabira binary packages

`scripts/build-packages.sh` builds the compositor and shell inside a Debian 13
container, then creates five installable Debian binary packages:
`hanabira-compositor`, `hanabira-shell`, `hanabira-session`, and
`hanabira-installer`, plus `hanabira-tools` for the `hanabira-perf` frame-time
analyzer. Generated files stay in `packaging/out/` and are copied
into `config/packages.chroot/` by `scripts/build-iso.sh`.

The compositor and shell packages contain actual compiled binaries. The
session package supplies a selectable **nested experimental** HDE session and
an explicit Plasma rescue entry. It does not make HDE the default until a
native DRM backend has passed boot and input tests. The installer package
uses Debian 13's Calamares backend with Hanabira-specific configuration and
branding; it can only launch from live media. No installer invocation occurs
during package or ISO builds.

These are Debian `.deb` binary packages, built with `dpkg-deb` and runtime ELF
dependencies determined by `dpkg-shlibdeps`. A public package repository still
needs signed APT metadata and complete Debian source packages; local
`packages.chroot` is a development integration path, not an update channel.

Each package is checked with `dpkg-deb --field` and `dpkg-deb --contents` after
construction. Build only metadata packages for a quick plumbing test with
`./scripts/build-packages.sh session` or `installer`; a full ISO uses all five.
