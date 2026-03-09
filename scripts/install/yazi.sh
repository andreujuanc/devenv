set -eu

run_as_root() {
    if [[ "${DEVENV_NEEDS_SUDO:-0}" == "1" ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

scope="${DEVENV_INSTALL_SCOPE:-environment}"
arch="$(uname -m)"
case "$arch" in
    x86_64|amd64)
        yazi_asset="yazi-x86_64-unknown-linux-musl.deb"
        ;;
    aarch64|arm64)
        yazi_asset="yazi-aarch64-unknown-linux-musl.deb"
        ;;
    *)
        echo "devenv: unsupported yazi ${scope} architecture: $arch" >&2
        exit 1
        ;;
esac

if command -v apt-get >/dev/null 2>&1 && [[ "${DEVENV_ALLOW_APT_RELEASE:-0}" == "1" ]]; then
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT
    run_as_root apt-get update
    if ! command -v curl >/dev/null 2>&1; then
        run_as_root apt-get install -y curl
    fi
    curl -fsSL "https://github.com/sxyazi/yazi/releases/download/v${DEVENV_YAZI_VERSION}/${yazi_asset}" -o "$tmpdir/${yazi_asset}"
    run_as_root apt-get install --reinstall -y "$tmpdir/${yazi_asset}"
elif command -v dnf >/dev/null 2>&1 && [[ "${DEVENV_ALLOW_DNF_PACKAGE:-0}" == "1" ]]; then
    run_as_root dnf install -y yazi
elif command -v pacman >/dev/null 2>&1 && [[ "${DEVENV_ALLOW_PACMAN_PACKAGE:-0}" == "1" ]]; then
    run_as_root pacman -Sy --noconfirm yazi
elif command -v zypper >/dev/null 2>&1 && [[ "${DEVENV_ALLOW_ZYPPER_PACKAGE:-0}" == "1" ]]; then
    run_as_root zypper --non-interactive install yazi
elif command -v apk >/dev/null 2>&1 && [[ "${DEVENV_ALLOW_APK_PACKAGE:-0}" == "1" ]]; then
    run_as_root apk add --no-cache yazi
else
    echo "devenv: no supported yazi install flow found in the ${scope}" >&2
    exit 1
fi
