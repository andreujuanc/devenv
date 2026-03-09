#!/usr/bin/env bash
set -euo pipefail

project_root="${DEVENV_PROJECT_ROOT:-}"
open_script="${DEVENV_OPEN_FILE_SCRIPT:-}"
current_dir="$project_root"
filter_text=""
show_hidden=0
cursor_index=0
scroll_offset=0

declare -a entry_labels=()
declare -a entry_paths=()

[[ -n "$project_root" ]] || {
    echo "devenv: DEVENV_PROJECT_ROOT is required" >&2
    exit 1
}

[[ -n "$open_script" ]] || {
    echo "devenv: DEVENV_OPEN_FILE_SCRIPT is required" >&2
    exit 1
}

sanitize_dir() {
    local candidate="$1"

    candidate="$(tr -d '\000' <<< "$candidate")"
    candidate="$(realpath -m "$candidate")"

    case "$candidate" in
        "$project_root"|"$project_root"/*)
            printf '%s\n' "$candidate"
            ;;
        *)
            printf '%s\n' "$project_root"
            ;;
    esac
}

load_entries() {
    local -a paths=()
    local -a dir_names=()
    local -a file_names=()
    local name lowered filter_lower
    local path

    entry_labels=()
    entry_paths=()

    shopt -s nullglob
    if [[ $show_hidden -eq 1 ]]; then
        paths=("$current_dir"/* "$current_dir"/.*)
    else
        paths=("$current_dir"/*)
    fi
    shopt -u nullglob

    filter_lower="$(printf '%s' "$filter_text" | tr '[:upper:]' '[:lower:]')"

    for path in "${paths[@]}"; do
        name="${path##*/}"
        [[ "$name" == "." || "$name" == ".." ]] && continue

        if [[ -n "$filter_lower" ]]; then
            lowered="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
            [[ "$lowered" == *"$filter_lower"* ]] || continue
        fi

        if [[ -d "$path" ]]; then
            dir_names+=("$name")
        else
            file_names+=("$name")
        fi
    done

    if [[ ${#dir_names[@]} -gt 0 ]]; then
        mapfile -t dir_names < <(printf '%s\n' "${dir_names[@]}" | LC_ALL=C sort)
    fi

    if [[ ${#file_names[@]} -gt 0 ]]; then
        mapfile -t file_names < <(printf '%s\n' "${file_names[@]}" | LC_ALL=C sort)
    fi

    for name in "${dir_names[@]}"; do
        entry_labels+=("$name/")
        entry_paths+=("$current_dir/$name")
    done

    for name in "${file_names[@]}"; do
        entry_labels+=("$name")
        entry_paths+=("$current_dir/$name")
    done

    if [[ ${#entry_labels[@]} -eq 0 ]]; then
        cursor_index=0
        scroll_offset=0
        return
    fi

    if (( cursor_index >= ${#entry_labels[@]} )); then
        cursor_index=$(( ${#entry_labels[@]} - 1 ))
    fi

    if (( cursor_index < 0 )); then
        cursor_index=0
    fi
}

draw_picker() {
    local rows cols list_height rel_dir hidden_label total visible_end idx display width

    rows="$(tput lines 2>/dev/null || printf '24')"
    cols="$(tput cols 2>/dev/null || printf '80')"
    [[ "$rows" =~ ^[0-9]+$ ]] || rows=24
    [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
    list_height=$(( rows - 5 ))
    (( list_height < 5 )) && list_height=5
    width=$(( cols - 4 ))
    (( width < 12 )) && width=12

    if (( cursor_index < scroll_offset )); then
        scroll_offset=$cursor_index
    elif (( cursor_index >= scroll_offset + list_height )); then
        scroll_offset=$(( cursor_index - list_height + 1 ))
    fi

    rel_dir="${current_dir#$project_root/}"
    [[ "$rel_dir" == "$current_dir" ]] && rel_dir='.'
    [[ $show_hidden -eq 1 ]] && hidden_label='on' || hidden_label='off'

    printf '\033[H\033[2J'
    printf 'Explorer  %s\n' "$rel_dir"
    printf 'Filter: %s   Hidden: %s\n' "${filter_text:-<none>}" "$hidden_label"
    printf 'Keys: j/k or arrows move, Enter open, h/back up, / filter, . hidden, q quit\n'
    printf '\n'

    total=${#entry_labels[@]}
    if (( total == 0 )); then
        if [[ -n "$filter_text" ]]; then
            printf '  no matches\n'
        else
            printf '  empty\n'
        fi
        return
    fi

    visible_end=$(( scroll_offset + list_height ))
    (( visible_end > total )) && visible_end=$total

    for (( idx = scroll_offset; idx < visible_end; idx++ )); do
        display="${entry_labels[idx]}"
        if (( ${#display} > width )); then
            display="${display:0:width-1}~"
        fi

        if (( idx == cursor_index )); then
            printf '  \033[7m%-*s\033[0m\n' "$width" "$display"
        else
            printf '  %-*s\n' "$width" "$display"
        fi
    done
}

prompt_filter() {
    printf '\033[?25h'
    printf '\nfilter: '
    IFS= read -r filter_text || filter_text=''
    printf '\033[?25l'
    cursor_index=0
    scroll_offset=0
}

go_parent() {
    current_dir="$(sanitize_dir "$(dirname "$current_dir")")"
    filter_text=''
    cursor_index=0
    scroll_offset=0
}

open_current_entry() {
    local selected_path

    (( ${#entry_paths[@]} > 0 )) || return
    selected_path="${entry_paths[cursor_index]}"

    if [[ -d "$selected_path" ]]; then
        current_dir="$(sanitize_dir "$selected_path")"
        filter_text=''
        cursor_index=0
        scroll_offset=0
        return
    fi

    "$open_script" "$selected_path" || true
}

printf '\033[?25l'
trap 'printf "\033[?25h"' EXIT

while :; do
    load_entries
    draw_picker

    IFS= read -rsn1 key || exit 0

    case "$key" in
        q)
            exit 0
            ;;
        j)
            if (( cursor_index + 1 < ${#entry_labels[@]} )); then
                cursor_index=$(( cursor_index + 1 ))
            fi
            ;;
        k)
            if (( cursor_index > 0 )); then
                cursor_index=$(( cursor_index - 1 ))
            fi
            ;;
        h)
            go_parent
            ;;
        /)
            prompt_filter
            ;;
        .)
            if [[ $show_hidden -eq 1 ]]; then
                show_hidden=0
            else
                show_hidden=1
            fi
            cursor_index=0
            scroll_offset=0
            ;;
        '')
            open_current_entry
            ;;
        $'\177')
            go_parent
            ;;
        $'\033')
            IFS= read -rsn2 -t 0.01 rest || rest=''
            case "$rest" in
                '[A')
                    if (( cursor_index > 0 )); then
                        cursor_index=$(( cursor_index - 1 ))
                    fi
                    ;;
                '[B')
                    if (( cursor_index + 1 < ${#entry_labels[@]} )); then
                        cursor_index=$(( cursor_index + 1 ))
                    fi
                    ;;
                '[D')
                    go_parent
                    ;;
                '[C')
                    open_current_entry
                    ;;
            esac
            ;;
    esac
done
