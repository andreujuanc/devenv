set -eu

run_as_root() {
    if [ "${DEVENV_NEEDS_SUDO:-0}" = "1" ]; then
        sudo "$@"
    else
        "$@"
    fi
}

scope="${DEVENV_INSTALL_SCOPE:-environment}"
install_root="${DEVENV_INSTALL_ROOT:?DEVENV_INSTALL_ROOT is required}"
install_bin_dir="${DEVENV_INSTALL_BIN_DIR:?DEVENV_INSTALL_BIN_DIR is required}"
version="${DEVENV_FRESH_VERSION:?DEVENV_FRESH_VERSION is required}"

arch="$(uname -m)"
case "$arch" in
    x86_64|amd64)
        fresh_target="x86_64-unknown-linux-gnu"
        ;;
    aarch64|arm64)
        fresh_target="aarch64-unknown-linux-gnu"
        ;;
    *)
        echo "devenv: unsupported fresh ${scope} architecture: $arch" >&2
        exit 1
        ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

archive_name="fresh-editor-${fresh_target}.tar.xz"
archive_url="https://github.com/sinelaw/fresh/releases/download/v${version}/${archive_name}"
archive_path="$tmpdir/$archive_name"
extract_dir="$tmpdir/extract"

if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1 || ! command -v xz >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        run_as_root apt-get update
        run_as_root apt-get install -y curl xz-utils tar
    elif command -v dnf >/dev/null 2>&1; then
        run_as_root dnf install -y curl xz tar
    elif command -v pacman >/dev/null 2>&1; then
        run_as_root pacman -Sy --noconfirm curl xz tar
    elif command -v zypper >/dev/null 2>&1; then
        run_as_root zypper --non-interactive install curl xz tar
    elif command -v apk >/dev/null 2>&1; then
        run_as_root apk add --no-cache curl xz tar
    else
        echo "devenv: could not install curl/tar/xz for fresh installer in the ${scope}" >&2
        exit 1
    fi
fi

if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1 || ! command -v xz >/dev/null 2>&1; then
    echo "devenv: curl, tar, and xz are required to install fresh in the ${scope}" >&2
    exit 1
fi

run_as_root mkdir -p "$install_root" "$install_bin_dir"
curl -fsSL "$archive_url" -o "$archive_path"
mkdir -p "$extract_dir"
tar -xJf "$archive_path" -C "$extract_dir"

if [ -d "$extract_dir/fresh-editor-${fresh_target}" ]; then
    extract_dir="$extract_dir/fresh-editor-${fresh_target}"
fi

if [ ! -x "$extract_dir/fresh" ]; then
    echo "devenv: fresh binary not found in release archive for ${scope}" >&2
    exit 1
fi

run_as_root rm -rf "$install_root"
run_as_root mkdir -p "$install_root"
run_as_root cp -R "$extract_dir/." "$install_root/"
run_as_root ln -sf "$install_root/fresh" "$install_bin_dir/fresh"