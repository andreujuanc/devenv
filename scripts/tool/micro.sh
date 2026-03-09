if ! command -v micro >/dev/null 2>&1; then
    echo "devenv: tool 'micro' requires micro in the container image." >&2
    echo "devenv: install it with 'devenv container-tool install micro'." >&2
    exit 127
fi

exec micro "$@"
