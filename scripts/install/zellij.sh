set -eu

arch="$(uname -m)"
case "$arch" in
    x86_64|amd64)
        zellij_asset="zellij-x86_64-unknown-linux-musl.tar.gz"
        ;;
    aarch64|arm64)
        zellij_asset="zellij-aarch64-unknown-linux-musl.tar.gz"
        ;;
    *)
        echo "devenv: unsupported zellij host architecture: $arch" >&2
        exit 1
        ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "${DEVENV_INSTALL_BIN_DIR}"
curl -fsSL "https://github.com/zellij-org/zellij/releases/download/v${DEVENV_ZELLIJ_VERSION}/${zellij_asset}" -o "$tmpdir/zellij.tar.gz"
tar -xzf "$tmpdir/zellij.tar.gz" -C "$tmpdir"
install -m 0755 "$tmpdir/zellij" "${DEVENV_INSTALL_BIN_DIR}/zellij"
