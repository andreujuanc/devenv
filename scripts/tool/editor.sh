if command -v fresh >/dev/null 2>&1; then
    exec fresh "$@"
fi

if command -v micro >/dev/null 2>&1; then
    exec micro "$@"
fi

echo "devenv: tool 'editor' requires fresh or micro in the container image." >&2
echo "devenv: install one with 'devenv container-tool install fresh' or 'devenv container-tool install micro'." >&2
exit 127
