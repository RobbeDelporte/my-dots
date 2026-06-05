#!/usr/bin/env bash
# Lock launcher (hypridle's lock_cmd). Captures the live wallpaper into the conf
# hyprlock sources, so the lock background always matches the current desktop —
# regardless of how the wallpaper was set (rofi picker or wayle GUI).
#
# Every lock path funnels here: Super+L / Super+Escape / idle-timeout /
# before-sleep all run `loginctl lock-session`, which hypridle turns into this.
set -euo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/wayle/hyprlock-wallpaper.conf"

# awww (swww fork) is the wallpaper daemon. `query` prints, per output:
#   "<name>: WxH, scale: S, currently displaying: image: /path/to/wall.png"
# Grab the path after the last "image: "; first line is enough (one wallpaper
# for all monitors here). `|| true` so a stopped daemon never blocks the lock.
wall=$(awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1 || true)

if [[ -n "${wall:-}" && -f "$wall" ]]; then
    mkdir -p "$(dirname "$state")"
    printf '$wallpaper = %s\n' "$wall" > "$state"
fi

# Replace this shell with hyprlock so it owns the session lock.
exec hyprlock
