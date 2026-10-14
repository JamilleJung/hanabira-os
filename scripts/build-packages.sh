#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_dir"

component=${1:-all}
case "$component" in
    all|compositor|shell|session|installer|tools) ;;
    *) echo "Usage: $0 [all|compositor|shell|session|installer|tools]" >&2; exit 2 ;;
esac

# Build against the same Debian release as the live image. A binary compiled
# against the CachyOS host's newer glibc is not safe to install in Debian 13.
if [[ ${HANABIRA_PACKAGE_CONTAINER:-0} != 1 ]]; then
    if ! command -v podman >/dev/null 2>&1; then
        echo "Podman is required to build Debian 13 packages on this host." >&2
        exit 1
    fi
    podman run --rm --security-opt label=disable \
        --mount "type=bind,source=$project_dir,destination=/workspace" \
        --workdir /workspace \
        --env HANABIRA_PACKAGE_CONTAINER=1 \
        --env DEBIAN_FRONTEND=noninteractive \
        docker.io/library/debian:trixie-slim \
        /bin/sh -ec '
            apt-get update -qq
            requested=$1
            set -- dpkg-dev ca-certificates
            case "$requested" in
                all|compositor)
                    set -- "$@" cargo rustc pkg-config clang cmake libwayland-dev libxkbcommon-dev libudev-dev libinput-dev libseat-dev libgbm-dev libegl1-mesa-dev libgles2-mesa-dev libdrm-dev
                    ;;
                tools)
                    set -- "$@" cargo rustc
                    ;;
            esac
            case "$requested" in
                all|shell)
                    set -- "$@" cmake g++ pkg-config qt6-base-dev qt6-declarative-dev qt6-wayland-dev qt6-svg-dev libglib2.0-dev liblayershellqtinterface-dev
                    ;;
            esac
            case "$requested" in
                all|installer)
                    set -- "$@" librsvg2-bin
                    ;;
            esac
            apt-get install -y -qq --no-install-recommends "$@"
            exec ./scripts/build-packages.sh "$requested"
        ' sh "$component"
    exit
fi

for program in dpkg-deb dpkg-shlibdeps dpkg; do
    command -v "$program" >/dev/null 2>&1 || { echo "Missing build tool: $program" >&2; exit 1; }
done
if [[ $(dpkg --print-architecture) != amd64 ]]; then
    echo "Current Hanabira binary build supports amd64 only." >&2
    exit 1
fi

version=$(< VERSION)
deb_version="$(printf '%s' "$version" | sed 's/-/~/')-1"
dpkg --compare-versions "$deb_version" gt 0 || { echo "Invalid Debian version: $deb_version" >&2; exit 1; }

work_dir="$project_dir/packaging/.build"
out_dir="$project_dir/packaging/out"
mkdir -p "$work_dir/debian" "$out_dir"
printf 'Source: hanabira-os\n' > "$work_dir/debian/control"

prepare_stage() {
    local stage=$1
    mkdir -p "$stage"
    find "$stage" -mindepth 1 -delete
}

write_control() {
    local stage=$1 name=$2 architecture=$3 depends=$4 summary=$5 details=$6
    install -d "$stage/DEBIAN"
    cat > "$stage/DEBIAN/control" <<EOF
Package: $name
Version: $deb_version
Section: x11
Priority: optional
Architecture: $architecture
Maintainer: Hanabira OS contributors <noreply@github.com>
Homepage: https://github.com/JamilleJung/hanabira-os
Depends: $depends
Description: $summary
 $details
EOF
}

elf_depends() {
    local binary=$1 result
    result=$(cd "$work_dir" && dpkg-shlibdeps -O -e"$binary")
    result=${result#shlibs:Depends=}
    if [[ -z $result || $result == shlibs:Depends=* ]]; then
        echo "Could not resolve shared-library dependencies for $binary" >&2
        return 1
    fi
    printf '%s' "$result"
}

finish_package() {
    local name=$1 arch=$2 stage=$3 output
    output="$out_dir/${name}_${deb_version}_${arch}.deb"
    dpkg-deb --build --root-owner-group "$stage" "$output"
    [[ $(dpkg-deb --field "$output" Package) == "$name" ]]
    [[ $(dpkg-deb --field "$output" Version) == "$deb_version" ]]
    dpkg-deb --contents "$output" >/dev/null
    printf 'Verified %s\n' "$output"
}

install_notices() {
    local stage=$1 name=$2
    install -Dm 0644 LICENSE "$stage/usr/share/doc/$name/copyright"
    install -Dm 0644 ASSETS.md "$stage/usr/share/doc/$name/ASSETS.md"
}

build_compositor() {
    local manifest="$project_dir/desktop/compositor/Cargo.toml"
    [[ -f $manifest && -f "$project_dir/desktop/compositor/Cargo.lock" ]] || {
        echo "Compositor source or Cargo.lock is missing." >&2; return 1;
    }
    command -v cargo >/dev/null 2>&1 || { echo "cargo is required." >&2; return 1; }
    cargo build --release --locked --manifest-path "$manifest" --target-dir "$work_dir/cargo"
    local stage="$work_dir/pkg-compositor" binary="$work_dir/cargo/release/hanabira-compositor"
    [[ -x $binary ]] || { echo "Compositor build produced no executable." >&2; return 1; }
    prepare_stage "$stage"
    install -d "$stage/usr/bin"
    install -m 0755 "$binary" "$stage/usr/bin/hanabira-compositor"
    install_notices "$stage" hanabira-compositor
    install -Dm 0644 desktop/compositor/SMITHAY-LICENSE.txt \
        "$stage/usr/share/doc/hanabira-compositor/SMITHAY-LICENSE.txt"
    [[ -f desktop/compositor/third-party-notices/LICENSES.txt && \
       -f desktop/compositor/third-party-notices/manifest.json ]] || {
        echo "Compositor third-party notices are missing." >&2; return 1;
    }
    install -Dm 0644 desktop/compositor/third-party-notices/LICENSES.txt \
        "$stage/usr/share/doc/hanabira-compositor/THIRD-PARTY-LICENSES.txt"
    install -Dm 0644 desktop/compositor/third-party-notices/manifest.json \
        "$stage/usr/share/doc/hanabira-compositor/THIRD-PARTY-MANIFEST.json"
    local depends
    depends=$(elf_depends "$stage/usr/bin/hanabira-compositor")
    write_control "$stage" hanabira-compositor amd64 "$depends" \
        "Hanabira experimental Wayland compositor" \
        "Smithay-based compositor; current runnable backend is nested and does not own DRM outputs."
    finish_package hanabira-compositor amd64 "$stage"
}

build_shell() {
    [[ -f "$project_dir/desktop/shell/CMakeLists.txt" ]] || {
        echo "Shell CMake source is missing." >&2; return 1;
    }
    command -v cmake >/dev/null 2>&1 || { echo "cmake is required." >&2; return 1; }
    cmake -S "$project_dir/desktop/shell" -B "$work_dir/shell" \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
        -DHANABIRA_REQUIRE_LAYER_SHELL=ON
    cmake --build "$work_dir/shell" --parallel "${HANABIRA_BUILD_JOBS:-2}"
    local stage="$work_dir/pkg-shell"
    prepare_stage "$stage"
    DESTDIR="$stage" cmake --install "$work_dir/shell"
    [[ -x "$stage/usr/bin/hanabira-shell" ]] || {
        echo "Shell build produced no executable." >&2; return 1;
    }
    install_notices "$stage" hanabira-shell
    local depends
    depends=$(elf_depends "$stage/usr/bin/hanabira-shell")
    depends+=', qt6-wayland, qml6-module-qtquick, qml6-module-qtquick-controls, qml6-module-qtquick-layouts, qml6-module-qtquick-window, qml6-module-org-kde-layershell, layer-shell-qt'
    write_control "$stage" hanabira-shell amd64 "$depends" \
        "Hanabira desktop shell preview" \
        "Qt Quick desktop surfaces for the Hanabira nested compositor preview."
    finish_package hanabira-shell amd64 "$stage"
}

build_session() {
    local stage="$work_dir/pkg-session"
    prepare_stage "$stage"
    install -Dm 0755 packaging/session/hanabira-session "$stage/usr/bin/hanabira-session"
    install -Dm 0644 packaging/session/hanabira-nested.desktop \
        "$stage/usr/share/xsessions/hanabira-nested.desktop"
    install -Dm 0644 packaging/session/hanabira-rescue.desktop \
        "$stage/usr/share/wayland-sessions/hanabira-rescue.desktop"
    install_notices "$stage" hanabira-session
    write_control "$stage" hanabira-session all \
        "hanabira-compositor (= $deb_version), hanabira-shell (= $deb_version), dbus, dbus-user-session, plasma-workspace" \
        "Hanabira experimental session and Plasma rescue entry" \
        "Selectable nested HDE session; Plasma remains the working recovery path."
    finish_package hanabira-session all "$stage"
}

build_installer() {
    local stage="$work_dir/pkg-installer" target="$work_dir/pkg-installer/etc/hanabira/calamares"
    local branding="$work_dir/pkg-installer/etc/calamares/branding/hanabira"
    prepare_stage "$stage"
    install -Dm 0755 installer/hanabira-installer "$stage/usr/bin/hanabira-installer"
    install -Dm 0644 installer/hanabira-installer.desktop \
        "$stage/usr/share/applications/hanabira-installer.desktop"
    install -Dm 0644 installer/hide-debian-installer.desktop \
        "$stage/usr/share/applications/calamares-install-debian.desktop"
    install -Dm 0644 installer/hide-debian-desktop-icon.desktop \
        "$stage/etc/xdg/autostart/calamares-desktop-icon.desktop"
    install -Dm 0644 installer/calamares/settings.conf "$target/settings.conf"
    install -Dm 0644 installer/calamares/modules/packages.conf "$target/modules/packages.conf"
    install -Dm 0644 installer/calamares/modules/welcome.conf "$target/modules/welcome.conf"
    install -d "$target/modules" "$branding" "$target/branding"
    ln -s /etc/calamares/branding/hanabira "$target/branding/hanabira"
    ln -s /usr/share/calamares/qml "$target/qml"
    local module
    for module in bootloader displaymanager finished fstab luksopenswaphookcfg machineid mount unpackfs users; do
        ln -s "/etc/calamares/modules/$module.conf" "$target/modules/$module.conf"
    done
    install -m 0644 installer/calamares/branding/hanabira/branding.desc \
        "$branding/branding.desc"
    install -m 0644 installer/calamares/branding/hanabira/show.qml \
        "$branding/show.qml"
    local wallpaper="$project_dir/config/includes.chroot/usr/share/wallpapers/Hanabira/contents/images/2560x1600.png"
    local launcher_icon="$project_dir/config/includes.chroot/usr/share/icons/HanabiraDay/scalable/apps/hanabira-launcher.svg"
    [[ -f $wallpaper && -f $launcher_icon ]] || {
        echo "Installer artwork is missing." >&2; return 1;
    }
    install -m 0644 "$wallpaper" "$branding/welcome.png"
    command -v rsvg-convert >/dev/null 2>&1 || { echo "rsvg-convert is required." >&2; return 1; }
    rsvg-convert -w 256 -h 256 "$launcher_icon" > "$branding/logo.png"
    install_notices "$stage" hanabira-installer
    write_control "$stage" hanabira-installer all \
        "calamares (>= 3.3), calamares-settings-debian (>= 13), pkexec, x11-xserver-utils, rsync, qml6-module-qtquick-window" \
        "Hanabira-branded Calamares installer for live media" \
        "Uses the Debian Calamares backend and only launches from a live session."
    sed -i '/^Depends:/i Replaces: calamares-settings-debian' "$stage/DEBIAN/control"
    finish_package hanabira-installer all "$stage"
}

build_tools() {
    local manifest="$project_dir/desktop/core/Cargo.toml"
    [[ -f $manifest && -f "$project_dir/desktop/core/Cargo.lock" ]] || {
        echo "Core source or Cargo.lock is missing." >&2; return 1;
    }
    command -v cargo >/dev/null 2>&1 || { echo "cargo is required." >&2; return 1; }
    cargo build --release --locked --manifest-path "$manifest" --target-dir "$work_dir/core-cargo"
    local stage="$work_dir/pkg-tools" binary="$work_dir/core-cargo/release/hanabira-perf"
    [[ -x $binary ]] || { echo "Core build produced no executable." >&2; return 1; }
    prepare_stage "$stage"
    install -Dm 0755 "$binary" "$stage/usr/bin/hanabira-perf"
    install_notices "$stage" hanabira-tools
    local depends
    depends=$(elf_depends "$stage/usr/bin/hanabira-perf")
    write_control "$stage" hanabira-tools amd64 "$depends" \
        "Hanabira frame-time analysis tools" \
        "Analyzes timestamp captures to report frame pacing; bundled as native Debian binaries."
    finish_package hanabira-tools amd64 "$stage"
}

case "$component" in
    all) build_compositor; build_shell; build_session; build_installer; build_tools ;;
    compositor) build_compositor ;;
    shell) build_shell ;;
    session) build_session ;;
    installer) build_installer ;;
    tools) build_tools ;;
esac
