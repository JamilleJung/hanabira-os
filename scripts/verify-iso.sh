#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_dir"

if ! command -v xorriso >/dev/null 2>&1; then
    echo "xorriso is required to inspect the ISO boot records." >&2
    exit 1
fi
if [[ ! -f SHA256SUMS ]]; then
    echo "SHA256SUMS is missing; build the ISO first." >&2
    exit 1
fi

sha256sum --check SHA256SUMS
shopt -s nullglob
images=( ./hanabira-live-*.iso )
if (( ${#images[@]} != 1 )); then
    echo "Expected exactly one ISO, found ${#images[@]}." >&2
    exit 1
fi

iso=${images[0]}
live_report=$(xorriso -indev "$iso" -ls /live 2>&1)
grep -F "'filesystem.squashfs'" <<< "$live_report" >/dev/null
boot_report=$(xorriso -indev "$iso" -report_el_torito plain 2>&1)
printf '%s\n' "$boot_report"
grep -E 'El Torito boot img .* BIOS ' <<< "$boot_report" >/dev/null
grep -E 'El Torito boot img .* UEFI ' <<< "$boot_report" >/dev/null
echo "ISO filesystem and boot catalog are present: $iso"
