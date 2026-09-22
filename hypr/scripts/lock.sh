#!/usr/bin/env bash
# Lock launcher. Captures the live wallpaper into the conf
# hyprlock sources, so the lock background always matches the current desktop —
# regardless of how the wallpaper was set (rofi picker or wayle GUI).
#
# Every lock path funnels here: Super+L and Super+Escape both exec it
# directly. There is no idle daemon -- locking is manual only.
set -euo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/wayle/hyprlock-wallpaper.conf"

# skwd-wall is the wallpaper engine. `skwd-helm current --json` prints, per
# output: { name, path, current, type: static|video|we, ... }. Take the first
# STATIC one -- hyprlock draws an image and cannot play a video or a Wallpaper
# Engine scene, so while one of those is up we leave the previous still in
# place rather than handing hyprlock something it cannot render.
# `|| true` so a stopped daemon never blocks the lock.
wall=$(skwd-helm current --json 2>/dev/null | jq -r 'first(.outputs[] | select(.type == "static") | .path) // empty' || true)

if [[ -n "${wall:-}" && -f "$wall" ]]; then
    mkdir -p "$(dirname "$state")"
    printf '$wallpaper = %s\n' "$wall" > "$state"
fi

# Replace this shell with hyprlock so it owns the session lock.
exec hyprlock
