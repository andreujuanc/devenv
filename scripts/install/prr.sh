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
        prr_arch="amd64"
        ;;
    aarch64|arm64)
        prr_arch="arm64"
        ;;
    *)
        echo "devenv: unsupported prr ${scope} architecture: $arch" >&2
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
if [ -z "${DEVENV_PRR_VERSION:-}" ]; then
    DEVENV_PRR_VERSION=$(curl -s "https://api.github.com/repos/andreujuanc/prr/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
fi

prr_asset="prr_linux_${prr_arch}.tar.gz"

curl -fsSL "https://github.com/andreujuanc/prr/releases/download/v${DEVENV_PRR_VERSION}/${prr_asset}" -o "$tmpdir/${prr_asset}"
tar -xzf "$tmpdir/${prr_asset}" -C "$tmpdir"
run_as_root mkdir -p "${DEVENV_INSTALL_BIN_DIR:-/usr/local/bin}"
run_as_root install -m 0755 "$tmpdir/prr" "${DEVENV_INSTALL_BIN_DIR:-/usr/local/bin}/prr"
