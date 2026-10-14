# Build provenance and reproducibility

The build recipe targets Debian 13 `trixie`, but currently resolves packages
from the live Debian repositories. Repository updates, firmware revisions,
build-tool versions and filesystem timestamps can change the ISO bytes even
when the project commit is unchanged. The project does not claim bit-for-bit
reproducible ISOs yet.

A successful build writes:

- `BUILDINFO.txt`: project version, source commit when Git is available, UTC
  build time, Debian suite, architecture, `live-build` version and whether a
  source image was requested.
- `hanabira-live-*.packages`: installed package names and versions generated
  by `live-build`.
- `SHA256SUMS`: checksums for the ISO, recipe, build information, package
  manifest and any detected source archives.
- `build.log`: full `live-build` log; inspect and archive it separately if
  needed, because logs can contain mirror details and large amounts of output.

Keep these files together with the release and record the exact Git tag. For
future byte-level reproducibility, pin Debian package snapshots and container
image digests, normalize timestamps, and compare independent builds. Do not
infer reproducibility merely from a matching package list.
