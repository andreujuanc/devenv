if command -v lazygit >/dev/null 2>&1; then
    exec lazygit
fi

if command -v gitui >/dev/null 2>&1; then
    exec gitui
fi

git status --short --branch || true
echo
echo "devenv: install lazygit in the container for a richer git pane." >&2
exec "${SHELL:-sh}" -i
