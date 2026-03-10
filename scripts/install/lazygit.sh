set -eu

run_as_root() {
    if [ "${DEVENV_NEEDS_SUDO:-0}" = "1" ]; then
        sudo "$@"
    else
        "$@"
    fi
}

scope="${DEVENV_INSTALL_SCOPE:-environment}"
arch="$(uname -m)"
case "$arch" in
    x86_64|amd64)
        lazygit_asset="lazygit_${DEVENV_LAZYGIT_VERSION}_linux_x86_64.tar.gz"
        ;;
    aarch64|arm64)
        lazygit_asset="lazygit_${DEVENV_LAZYGIT_VERSION}_linux_arm64.tar.gz"
        ;;
    *)
        echo "devenv: unsupported lazygit ${scope} architecture: $arch" >&2
        exit 1
        ;;
esac

if command -v apt-get >/dev/null 2>&1 && [ "${DEVENV_ALLOW_APT_RELEASE:-0}" = "1" ]; then
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
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${DEVENV_LAZYGIT_VERSION}/${lazygit_asset}" -o "$tmpdir/${lazygit_asset}"
    tar -xzf "$tmpdir/${lazygit_asset}" -C "$tmpdir"
    run_as_root install -m 0755 "$tmpdir/lazygit" "${DEVENV_INSTALL_BIN_DIR}/lazygit"
elif command -v dnf >/dev/null 2>&1 && [ "${DEVENV_ALLOW_DNF_COPR:-0}" = "1" ]; then
    run_as_root dnf copr enable dejan/lazygit -y
    run_as_root dnf install -y lazygit
elif command -v dnf >/dev/null 2>&1 && [ "${DEVENV_ALLOW_DNF_PACKAGE:-0}" = "1" ]; then
    run_as_root dnf install -y lazygit
elif command -v pacman >/dev/null 2>&1 && [ "${DEVENV_ALLOW_PACMAN_PACKAGE:-0}" = "1" ]; then
    run_as_root pacman -Sy --noconfirm lazygit
elif command -v zypper >/dev/null 2>&1 && [ "${DEVENV_ALLOW_ZYPPER_PACKAGE:-0}" = "1" ]; then
    run_as_root zypper --non-interactive install lazygit
elif command -v apk >/dev/null 2>&1 && [ "${DEVENV_ALLOW_APK_PACKAGE:-0}" = "1" ]; then
    run_as_root apk add --no-cache lazygit
else
    echo "devenv: no supported lazygit install flow found in the ${scope}" >&2
    exit 1
fi
