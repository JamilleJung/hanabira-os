#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if ! command -v podman >/dev/null 2>&1; then
    echo "Podman is required, or use scripts/build.sh in a Debian 13 VM." >&2
    exit 1
fi

# live-build mounts /proc, /sys and temporary filesystems inside its chroot.
# This container is privileged only inside rootless Podman's user namespace.
podman run --rm --privileged --security-opt label=disable \
    --mount "type=bind,source=$project_dir,destination=/workspace" \
    --workdir /workspace \
    --env HANABIRA_BUILD_SOURCES="${HANABIRA_BUILD_SOURCES:-false}" \
    --env HANABIRA_CLEAN="${HANABIRA_CLEAN:-true}" \
    --env DEBIAN_FRONTEND=noninteractive \
    docker.io/library/debian:trixie-slim \
    /bin/sh -ec 'apt-get update && apt-get install -y --no-install-recommends live-build debootstrap xorriso squashfs-tools syslinux-common syslinux grub-pc-bin grub-efi-amd64-bin mtools dosfstools ca-certificates wget git && exec ./scripts/build.sh'
