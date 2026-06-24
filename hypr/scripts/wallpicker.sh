#!/usr/bin/env bash
# Wallpaper picker (bound to Super+Shift+W).
# Shows thumbnails of $WALLPAPER_DIR in rofi's icon mode, then applies the
# chosen image via wayle. wayle re-runs matugen itself, so the whole palette
# re-themes — no separate matugen call needed here.
set -euo pipefail
shopt -s nullglob nocaseglob

wall_dir="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
[[ -d "$wall_dir" ]] || { notify-send "Wallpaper picker" "No directory: $wall_dir" 2>/dev/null || true; exit 1; }

files=("$wall_dir"/*.{jpg,jpeg,png,webp})
[[ ${#files[@]} -gt 0 ]] || { notify-send "Wallpaper picker" "No images in $wall_dir" 2>/dev/null || true; exit 1; }

chosen=$(
	for f in "${files[@]}"; do
		printf '%s\x00icon\x1f%s\n' "$(basename "$f")" "$f"
	done | rofi -dmenu -i -p "Wallpaper" -theme-str 'element-icon { size: 6em; }'
) || exit 0
[[ -n "${chosen:-}" ]] || exit 0

wayle wallpaper set -f fill "$wall_dir/$chosen"

# The desktop clock re-places itself from matugen's eww post_hook (wayle re-runs
# matugen on every wallpaper set, and that post_hook runs reposition.sh --reload).
# Don't call reposition.sh here too -- doing both double-triggered it and the
# clock faded in twice.
