#!/usr/bin/env bash
set -euo pipefail

resolve_path() {
    local target="$1"
    local target_dir

    if command -v realpath >/dev/null 2>&1; then
        realpath -m "$target"
        return
    fi

    if [[ -d "$target" ]]; then
        (
            cd "$target" >/dev/null 2>&1 && pwd -P
        )
        return
    fi

    target_dir="$(cd "$(dirname "$target")" >/dev/null 2>&1 && pwd -P)"
    printf '%s/%s\n' "$target_dir" "$(basename "$target")"
}

project_root="${DEVENV_PROJECT_ROOT:-}"
editor_launcher="${DEVENV_EDITOR_LAUNCHER:-}"
selected_path="${1:-}"

[[ -n "$project_root" ]] || {
    echo "devenv: DEVENV_PROJECT_ROOT is required" >&2
    exit 1
}

[[ -n "$editor_launcher" ]] || {
    echo "devenv: DEVENV_EDITOR_LAUNCHER is required" >&2
    exit 1
}

[[ -n "$selected_path" ]] || exit 0

project_root="$(resolve_path "$project_root")"
selected_path="$(resolve_path "$selected_path")"

case "$selected_path" in
    "$project_root"|"$project_root"/*)
        ;;
    *)
        echo "devenv: refusing to open a path outside the project root: $selected_path" >&2
        exit 1
        ;;
esac

if [[ -d "$selected_path" ]]; then
    exit 0
fi

zellij action move-focus right >/dev/null 2>&1 || true

exec zellij action new-pane --in-place --cwd "$project_root" -- "$editor_launcher" "$selected_path"
