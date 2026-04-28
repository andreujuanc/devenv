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
        gh_arch="amd64"
        ;;
    aarch64|arm64)
        gh_arch="arm64"
        ;;
    *)
        echo "devenv: unsupported gh ${scope} architecture: $arch" >&2
        exit 1
        ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

if command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    if ! command -v curl >/dev/null 2>&1; then
        run_as_root apt-get install -y curl
    fi
    if ! command -v tar >/dev/null 2>&1; then
        run_as_root apt-get install -y tar
    fi
fi

# Fetch latest version if not set
if [ -z "${DEVENV_GH_VERSION:-}" ]; then
    DEVENV_GH_VERSION=$(curl -s "https://api.github.com/repos/cli/cli/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
fi

gh_asset="gh_${DEVENV_GH_VERSION}_linux_${gh_arch}.tar.gz"

curl -fsSL "https://github.com/cli/cli/releases/download/v${DEVENV_GH_VERSION}/${gh_asset}" -o "$tmpdir/${gh_asset}"
tar -xzf "$tmpdir/${gh_asset}" -C "$tmpdir"
run_as_root mkdir -p "${DEVENV_INSTALL_BIN_DIR:-/usr/local/bin}"
run_as_root install -m 0755 "$tmpdir/gh_${DEVENV_GH_VERSION}_linux_${gh_arch}/bin/gh" "${DEVENV_INSTALL_BIN_DIR:-/usr/local/bin}/gh"
