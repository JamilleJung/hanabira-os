#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_dir"

if (( $# != 0 )); then
    echo "Usage: $0" >&2
    exit 2
fi

case "${HANABIRA_BUILD_SOURCES:-false}" in
    false) ;;
    true)
        if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
            echo "A committed Git checkout is required for a source-image build." >&2
            exit 1
        fi
        if [[ -n $(git status --porcelain --untracked-files=normal) ]]; then
            echo "Commit all source changes before HANABIRA_BUILD_SOURCES=true." >&2
            exit 1
        fi
        ;;
    *) echo "HANABIRA_BUILD_SOURCES must be true or false." >&2; exit 2 ;;
esac

# Build all native Hanabira components against Debian 13, then hand them to
# live-build through its documented local-package directory.
./scripts/build-packages.sh all

version=$(< VERSION)
deb_version="$(printf '%s' "$version" | sed 's/-/~/')-1"
out_dir="$project_dir/packaging/out"
packages=(
    "$out_dir/hanabira-compositor_${deb_version}_amd64.deb"
    "$out_dir/hanabira-shell_${deb_version}_amd64.deb"
    "$out_dir/hanabira-session_${deb_version}_all.deb"
    "$out_dir/hanabira-installer_${deb_version}_all.deb"
    "$out_dir/hanabira-tools_${deb_version}_amd64.deb"
)
for package in "${packages[@]}"; do
    [[ -f $package ]] || { echo "Missing native package: $package" >&2; exit 1; }
done

local_package_dir="$project_dir/config/packages.chroot"
mkdir -p "$local_package_dir"
find "$local_package_dir" -maxdepth 1 -type f -name 'hanabira-*.deb' -delete
for package in "${packages[@]}"; do
    install -m 0644 "$package" "$local_package_dir/"
done

# The live image remains Plasma-first while HDE is a nested experimental
# session. The installer is present, but nothing in the build invokes it.
if command -v podman >/dev/null 2>&1; then
    ./scripts/build-container.sh
elif [[ $EUID -eq 0 ]] && command -v lb >/dev/null 2>&1; then
    ./scripts/build.sh
else
    echo "Need rootless Podman or a Debian 13 root build environment." >&2
    exit 1
fi

if command -v xorriso >/dev/null 2>&1; then
    ./scripts/verify-iso.sh
elif command -v podman >/dev/null 2>&1; then
    podman run --rm --security-opt label=disable \
        --mount "type=bind,source=$project_dir,destination=/workspace,readonly" \
        --workdir /workspace docker.io/library/debian:trixie-slim \
        /bin/sh -ec 'apt-get update && apt-get install -y --no-install-recommends xorriso ca-certificates && exec ./scripts/verify-iso.sh'
else
    echo "ISO built, but xorriso is unavailable for boot catalog verification." >&2
    exit 1
fi
