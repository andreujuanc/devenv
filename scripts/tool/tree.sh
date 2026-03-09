if [ "$#" -eq 0 ]; then
    set -- .
fi

if command -v eza >/dev/null 2>&1; then
    exec eza --tree --all --level=3 --group-directories-first --icons=never "$@"
fi

if command -v tree >/dev/null 2>&1; then
    exec tree -a -L 3 "$@"
fi

if command -v find >/dev/null 2>&1; then
    root="$1"
    find "$root" -maxdepth 3 \( -path "*/.git" -o -path "*/node_modules" \) -prune -o -print | sed "s#^$root#.#"
    exec "${SHELL:-sh}" -i
fi

exec ls -la "$@"
