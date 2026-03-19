if command -v copilot >/dev/null 2>&1; then
    exec copilot "$@"
fi

if command -v opencode >/dev/null 2>&1; then
    exec opencode "$@"
fi

if command -v gemini >/dev/null 2>&1; then
    exec gemini "$@"
fi

if command -v gemini-cli >/dev/null 2>&1; then
    exec gemini-cli "$@"
fi

echo "devenv: tool 'ai' requires copilot, opencode, or gemini in the container image." >&2
echo "devenv: install one with 'devenv container-tool install copilot' or 'devenv container-tool install opencode', or add gemini to the image." >&2
exec "${SHELL:-sh}" -i
