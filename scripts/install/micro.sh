set -eu

run_as_root() {
    if [[ "${DEVENV_NEEDS_SUDO:-0}" == "1" ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

if command -v curl >/dev/null 2>&1; then
    downloader='curl -fsSL https://getmic.ro'
elif command -v wget >/dev/null 2>&1; then
    downloader='wget -O- https://getmic.ro'
else
    if command -v apt-get >/dev/null 2>&1; then
        run_as_root apt-get update
        run_as_root apt-get install -y curl
    elif command -v dnf >/dev/null 2>&1; then
        run_as_root dnf install -y curl
    elif command -v pacman >/dev/null 2>&1; then
        run_as_root pacman -Sy --noconfirm curl
    elif command -v zypper >/dev/null 2>&1; then
        run_as_root zypper --non-interactive install curl
    elif command -v apk >/dev/null 2>&1; then
        run_as_root apk add --no-cache curl
    else
        echo "devenv: could not install curl or wget for micro installer" >&2
        exit 1
    fi
    downloader='curl -fsSL https://getmic.ro'
fi

mkdir -p "${DEVENV_INSTALL_BIN_DIR}"
cd "${DEVENV_INSTALL_BIN_DIR}"
eval "$downloader" | bash
