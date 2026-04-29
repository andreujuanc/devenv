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
        gh_dash_arch="amd64"
        ;;
    aarch64|arm64)
        gh_dash_arch="arm64"
        ;;
    *)
        echo "devenv: unsupported gh-dash ${scope} architecture: $arch" >&2
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
fi

# Fetch latest version if not set
if [ -z "${DEVENV_GHDASH_VERSION:-}" ]; then
    DEVENV_GHDASH_VERSION=$(curl -s "https://api.github.com/repos/dlvhdr/gh-dash/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
fi

gh_dash_asset="gh-dash_v${DEVENV_GHDASH_VERSION}_linux-${gh_dash_arch}"

curl -fsSL "https://github.com/dlvhdr/gh-dash/releases/download/v${DEVENV_GHDASH_VERSION}/${gh_dash_asset}" -o "$tmpdir/gh-dash"
run_as_root mkdir -p "${DEVENV_INSTALL_BIN_DIR:-/usr/local/bin}"
run_as_root install -m 0755 "$tmpdir/gh-dash" "${DEVENV_INSTALL_BIN_DIR:-/usr/local/bin}/gh-dash"

# Initialize gh-dash config directory if run as regular user
if [ "$(id -u)" != "0" ]; then
    mkdir -p "$HOME/.config/gh-dash"
    mkdir -p "$HOME/.local/state/gh-dash"
fi
