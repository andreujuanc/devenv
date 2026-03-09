if ! command -v hx >/dev/null 2>&1; then
    echo "devenv: tool 'helix' requires hx in the container image. Install Helix in this repo's devcontainer." >&2
    exit 127
fi

if [ "$#" -eq 0 ]; then
    set -- .
fi

exec hx "$@"
