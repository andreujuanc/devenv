if ! command -v fresh >/dev/null 2>&1; then
    echo "devenv: tool 'fresh' requires fresh in the container image." >&2
    echo "devenv: install it with 'devenv container-tool install fresh'." >&2
    exit 127
fi

exec fresh "$@"