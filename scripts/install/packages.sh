set -eu

run_as_root() {
    if [[ "${DEVENV_NEEDS_SUDO:-0}" == "1" ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

scope="${DEVENV_INSTALL_SCOPE:-environment}"

if command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    run_as_root apt-get install -y ${DEVENV_PACKAGES}
elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y ${DEVENV_PACKAGES}
elif command -v pacman >/dev/null 2>&1; then
    run_as_root pacman -Sy --noconfirm ${DEVENV_PACKAGES}
elif command -v zypper >/dev/null 2>&1; then
    run_as_root zypper --non-interactive install ${DEVENV_PACKAGES}
elif command -v apk >/dev/null 2>&1; then
    run_as_root apk add --no-cache ${DEVENV_PACKAGES}
else
    echo "devenv: no supported package manager found in the ${scope}" >&2
    exit 1
fi
