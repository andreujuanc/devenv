#!/usr/bin/env bash
set -euo pipefail

if command -v hx >/dev/null 2>&1; then
    exec hx "$@"
fi

if command -v nvim >/dev/null 2>&1; then
    exec nvim "$@"
fi

if command -v micro >/dev/null 2>&1; then
    exec micro "$@"
fi

if command -v vim >/dev/null 2>&1; then
    exec vim "$@"
fi

if command -v vi >/dev/null 2>&1; then
    exec vi "$@"
fi

echo "devenv: no host editor found (tried hx, nvim, micro, vim, vi)." >&2
exec "${SHELL:-bash}" -il
