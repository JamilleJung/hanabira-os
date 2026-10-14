#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_dir"

if [[ $EUID -ne 0 ]]; then
    echo "Run this inside a Debian 13 build VM/container as root." >&2
    exit 1
fi
if ! command -v lb >/dev/null 2>&1; then
    echo "Install live-build first: apt-get install live-build" >&2
    exit 1
fi

if [[ ${HANABIRA_CLEAN:-true} == true ]]; then
    if [[ -f config/common ]]; then
        lb clean --purge
    fi
    rm -f config/binary config/bootstrap config/chroot config/common config/source
fi

lb config
lb build 2>&1 | tee build.log

shopt -s nullglob
images=( ./hanabira-live-*.iso )
if (( ${#images[@]} != 1 )); then
    echo "Expected one Hanabira ISO after build, found ${#images[@]}" >&2
    exit 1
fi
echo "Built ${images[*]}"
./scripts/package-preview.sh
