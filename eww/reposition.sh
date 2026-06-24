#!/usr/bin/env bash
# Resolve and apply the wallpaper clock's position for the current wallpaper.
#
# Position source: eww/positions.conf  ("<basename> = <anchor> [| <x> <y>]").
# Fallback: "center right | 60px 0px".
#
# Position is passed to the window as eww OPEN ARGS (--arg anchor/xoff/yoff),
# because eww evaluates window :geometry before global vars are in scope.
#
# Usage:
#   reposition.sh [--open|--reload] [<wallpaper-path>]
#     --open            force (re)opening every window (used by launch.sh)
#     --reload          force, AND re-parse styles while the windows are closed
#                       so new matugen colours apply in the SAME open animation
#                       (used by matugen's eww post_hook on every theme render)
#     <wallpaper-path>  explicit path (wallpicker passes this; race-free).
#                       Omitted -> read the live path from `awww query`.
#
# Without --open it reopens windows only when the resolved position actually
# changes (no flicker on colour-only matugen renders).
set -uo pipefail

cfg="$HOME/.config/eww"
conf="$cfg/positions.conf"
state="${XDG_STATE_HOME:-$HOME/.local/state}/eww-clock-pos"

force=0
reload=0
wall=""
for a in "$@"; do
  case "$a" in
    --open)   force=1 ;;
    --reload) force=1; reload=1 ;;
    *)        wall="$a" ;;
  esac
done

[[ -z "$wall" ]] && wall=$(awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1 || true)
base=$(basename "${wall:-}")

# Defaults (the fallback when nothing matches).
anchor="center right"; xoff="60px"; yoff="0px"

if [[ -n "$base" && -f "$conf" ]]; then
  # "<basename> = <anchor>[ | <x> <y>]"; skip # comments, take first match.
  line=$(grep -v '^[[:space:]]*#' "$conf" 2>/dev/null | grep -F -- "$base =" | head -1 || true)
  if [[ -n "$line" ]]; then
    spec=${line#*=}
    if [[ "$spec" == *"|"* ]]; then
      anchor=$(echo "${spec%%|*}" | xargs)
      off=${spec#*|}
      xoff=$(echo "$off" | awk '{print $1}')
      yoff=$(echo "$off" | awk '{print $2}')
    else
      anchor=$(echo "$spec" | xargs)
    fi
  fi
fi
[[ -n "$xoff" ]] || xoff="0px"
[[ -n "$yoff" ]] || yoff="0px"

command -v eww >/dev/null 2>&1 || exit 0

# Reopen only on an actual position change (or when forced by launch.sh).
new="$anchor|$xoff|$yoff"
prev=$(cat "$state" 2>/dev/null || true)
if [[ "$force" -eq 0 && "$new" == "$prev" ]]; then
  exit 0
fi
mkdir -p "$(dirname "$state")"; printf '%s' "$new" > "$state"

n=$(awww query 2>/dev/null | grep -c 'currently displaying' || true)
[[ "$n" =~ ^[0-9]+$ && "$n" -ge 1 ]] || n=1

# Close every clock FIRST, then (for --reload) re-parse styles while nothing is
# mapped, then open. `eww reload` recreates any OPEN layer surface -- an extra
# re-map/animation -- so reloading with the windows already closed lets the
# colour refresh and the reposition collapse into a single open animation
# instead of two (reload-recreate at the old spot, then reposition at the new).
for ((i = 0; i < n; i++)); do
  eww close "clock-$i" >/dev/null 2>&1 || true
done
if [[ "$reload" -eq 1 ]]; then
  eww reload >/dev/null 2>&1 || true
fi
for ((i = 0; i < n; i++)); do
  eww open clock --id "clock-$i" --screen "$i" \
    --arg anchor="$anchor" --arg xoff="$xoff" --arg yoff="$yoff" >/dev/null 2>&1 || true
done
