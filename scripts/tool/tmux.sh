if ! command -v tmux >/dev/null 2>&1; then
    echo "devenv: tool 'tmux' requires tmux in the container image. Install tmux in this repo's devcontainer." >&2
    exit 127
fi

if [ "$#" -eq 0 ]; then
    if tmux has-session -t devenv 2>/dev/null; then
        exec tmux attach -t devenv
    else
        exec tmux new -s devenv
    fi
fi

exec tmux "$@"
