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
        eza_asset="eza_x86_64-unknown-linux-musl.tar.gz"
        ;;
    aarch64|arm64)
        eza_asset="eza_aarch64-unknown-linux-gnu_no_libgit.tar.gz"
        ;;
    *)
        echo "devenv: unsupported eza ${scope} architecture: $arch" >&2
        exit 1
        ;;
esac

if command -v apt-get >/dev/null 2>&1 && [[ "${DEVENV_ALLOW_APT_RELEASE:-0}" == "1" ]]; then
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT
    run_as_root mkdir -p "${DEVENV_INSTALL_BIN_DIR}"
    run_as_root apt-get update
    if ! command -v curl >/dev/null 2>&1; then
        run_as_root apt-get install -y curl
    fi
    if ! command -v tar >/dev/null 2>&1; then
        run_as_root apt-get install -y tar
    fi
    curl -fsSL "https://github.com/eza-community/eza/releases/download/v${DEVENV_EZA_VERSION}/${eza_asset}" -o "$tmpdir/${eza_asset}"
    tar -xzf "$tmpdir/${eza_asset}" -C "$tmpdir"
    run_as_root install -m 0755 "$tmpdir/eza" "${DEVENV_INSTALL_BIN_DIR}/eza"
elif command -v dnf >/dev/null 2>&1 && [[ "${DEVENV_ALLOW_DNF_PACKAGE:-0}" == "1" ]]; then
    run_as_root dnf install -y eza
elif command -v pacman >/dev/null 2>&1 && [[ "${DEVENV_ALLOW_PACMAN_PACKAGE:-0}" == "1" ]]; then
    run_as_root pacman -Sy --noconfirm eza
elif command -v zypper >/dev/null 2>&1 && [[ "${DEVENV_ALLOW_ZYPPER_PACKAGE:-0}" == "1" ]]; then
    run_as_root zypper --non-interactive install eza
elif command -v apk >/dev/null 2>&1 && [[ "${DEVENV_ALLOW_APK_PACKAGE:-0}" == "1" ]]; then
    run_as_root apk add --no-cache eza
else
    echo "devenv: no supported eza install flow found in the ${scope}" >&2
    exit 1
fi
