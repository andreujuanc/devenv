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
        delta_arch="x86_64"
        ;;
    aarch64|arm64)
        delta_arch="aarch64"
        ;;
    *)
        echo "devenv: unsupported delta ${scope} architecture: $arch" >&2
        exit 1
        ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        run_as_root apt-get update
        if ! command -v curl >/dev/null 2>&1; then
            run_as_root apt-get install -y curl
        fi
        if ! command -v tar >/dev/null 2>&1; then
            run_as_root apt-get install -y tar
        fi
    fi
fi

# Fetch latest version if not set
if [ -z "${DEVENV_DELTA_VERSION:-}" ]; then
    DEVENV_DELTA_VERSION=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
fi

delta_asset="delta-${DEVENV_DELTA_VERSION}-${delta_arch}-unknown-linux-gnu.tar.gz"

curl -fsSL "https://github.com/dandavison/delta/releases/download/${DEVENV_DELTA_VERSION}/${delta_asset}" -o "$tmpdir/delta.tar.gz"
tar -xzf "$tmpdir/delta.tar.gz" -C "$tmpdir"
run_as_root mkdir -p "${DEVENV_INSTALL_BIN_DIR:-/usr/local/bin}"
run_as_root install -m 0755 "$tmpdir/delta-${DEVENV_DELTA_VERSION}-${delta_arch}-unknown-linux-gnu/delta" "${DEVENV_INSTALL_BIN_DIR:-/usr/local/bin}/delta"
