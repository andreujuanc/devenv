if [ "$#" -eq 0 ]; then
    set -- .
fi

if command -v yazi >/dev/null 2>&1; then
    explorer_config="$PWD/.config/yazi/explorer"
    if [ -f "$explorer_config/yazi.toml" ]; then
        export YAZI_CONFIG_HOME="$explorer_config"
    fi
    exec yazi "$@"
fi

if command -v lf >/dev/null 2>&1; then
    exec lf "$@"
fi

if command -v ranger >/dev/null 2>&1; then
    exec ranger "$@"
fi

if command -v eza >/dev/null 2>&1; then
    exec eza -la --group-directories-first "$@"
fi

exec ls -la "$@"
