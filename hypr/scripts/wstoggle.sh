#!/usr/bin/env bash
set -euo pipefail

name="$1"; class="$2"; shift 2

if hyprctl -j clients | jq -e --arg c "$class" 'any(.[]; (.class // "") | test($c; "i"))' >/dev/null; then
    hyprctl dispatch togglespecialworkspace "$name"
elif (($#)); then
    # Quote each arg so spawn commands with spaces survive the dispatch.
    cmd=$(printf '%q ' "$@")
    hyprctl dispatch exec "[workspace special:$name silent] $cmd"
    # Brief settle so the freshly-spawned window is assigned before we reveal it.
    sleep 0.3
    hyprctl dispatch togglespecialworkspace "$name"
else
    hyprctl dispatch togglespecialworkspace "$name"
fi
