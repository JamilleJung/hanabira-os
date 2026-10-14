# Release procedure

This procedure is for maintainers preparing a **public** live ISO. A GitHub
repository or CI pass alone does not mean the image is ready for daily use.

1. Update `VERSION`, release notes, `README.md`, `PREVIEW-TH.md` and
   `ASSETS.md`. Review new artwork and third-party licenses. Tag the exact
   source commit only after tests pass.
2. Build from a clean Debian 13 environment with adequate disk space:
   `HANABIRA_CLEAN=true HANABIRA_BUILD_SOURCES=true ./scripts/build-container.sh`
   or run `./scripts/build.sh` as root in a Debian 13 VM with those variables.
   The source image is separate from the small build-recipe tarball.
3. Run `./scripts/verify-iso.sh` and inspect `BUILDINFO.txt`, the package
   manifest, `SHA256SUMS`, the source archive and `build.log`. Compare package
   licenses and notices against what is shipped. Debian packages normally
   carry notices at `/usr/share/doc/<package>/copyright`; firmware terms can
   differ. Preserve required notices and corresponding sources.
4. Boot the exact ISO in QEMU using BIOS and UEFI. Verify auto-login, desktop,
   wallpaper, networking, audio and shutdown. Test light/dark switching and
   multiple resolutions. Then test a release candidate on spare physical
   hardware before making claims about NVIDIA, mixed refresh, scaling or
   battery life.
5. Publish the ISO, source image, build recipe, package manifest,
   `BUILDINFO.txt`, `SHA256SUMS` and concise release notes together. Sign the
   checksums with a maintained project key before calling a release trusted.
   The tag and release assets must identify the same version.

Use a preview label for anything that has not completed this process. The
current project has no installer or update channel. Do not describe the ISO as
installable or as a replacement for a supported operating system.

The Debian live-build manual and `lb config` documentation explain why source
images matter for redistribution:
<https://manpages.debian.org/unstable/live-build/lb_config.1.en.html>.
