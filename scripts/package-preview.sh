#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_dir"

shopt -s nullglob
images=( ./hanabira-live-*.iso )
if (( ${#images[@]} != 1 )); then
    echo "Expected exactly one Hanabira ISO, found ${#images[@]}." >&2
    exit 1
fi

recipe=hanabira-live-build-recipe.tar.gz
# This contains our build recipe and artwork, not all Debian package sources.
tar -czf "$recipe" \
    --exclude='config/package-lists/live.list.chroot' \
    --exclude='*/target' --exclude='*/build' --exclude='*/.build' \
    --exclude='packaging/out' --exclude='*/.git' \
    --transform='s,^,hanabira-os/,' \
    auto/config config/bootloaders config/includes.chroot config/package-lists \
    desktop packaging installer scripts docs .github README.md PREVIEW-TH.md \
    CHANGELOG.md CONTRIBUTING.md ASSETS.md LICENSE VERSION .gitignore .gitattributes

version=$(< VERSION)
commit=unavailable
source_state=unavailable
if command -v git >/dev/null 2>&1 && git -c "safe.directory=$project_dir" rev-parse --verify HEAD >/dev/null 2>&1; then
    commit=$(git -c "safe.directory=$project_dir" rev-parse HEAD)
    source_state=clean
    if [[ -n $(git -c "safe.directory=$project_dir" status --porcelain --untracked-files=normal) ]]; then
        source_state=dirty
    fi
fi
{
    printf 'Project: Hanabira OS\n'
    printf 'Version: %s\n' "$version"
    printf 'Git commit: %s\n' "$commit"
    printf 'Source tree: %s\n' "$source_state"
    printf 'Built (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'Build suite: Debian 13 (trixie)\n'
    printf 'Architecture: amd64\n'
    printf 'Source image requested: %s\n' "${HANABIRA_BUILD_SOURCES:-false}"
    if command -v dpkg-query >/dev/null 2>&1; then
        printf 'live-build version: '
        dpkg-query -W -f='${Version}\n' live-build
    fi
    printf 'ISO: %s\n' "${images[0]#./}"
} > BUILDINFO.txt

artifacts=( "${images[0]}" "$recipe" BUILDINFO.txt )
manifests=( ./hanabira-live-*.packages )
artifacts+=( "${manifests[@]}" )
if [[ ${HANABIRA_BUILD_SOURCES:-false} == true ]]; then
    source_archives=( ./hanabira-live-source.debian.tar* ./hanabira-live-source.live.tar* )
    if (( ${#source_archives[@]} != 2 )); then
        echo "Source image was requested, but its Debian and live tar archives were not both found." >&2
        exit 1
    fi
    artifacts+=( "${source_archives[@]}" )
fi

sha256sum "${artifacts[@]}" > SHA256SUMS
cat SHA256SUMS
