#!/usr/bin/env bash
# Window switcher for Hyprland (bound to Super+Tab).
# rofi's built-in `-show window` mode lists windows over X11/EWMH and can't see
# native Wayland toplevels, so we feed the list from the compositor (hyprctl)
# and focus the chosen one. App icons come from each window's class (resolved
# against the icon theme set in config.rasi). `-format i` -> select by row index,
# so duplicate titles are safe.
set -euo pipefail

mapfile -t rows < <(
	hyprctl clients -j \
		| jq -r '.[] | select(.mapped and .title != "") | "\(.address)\t\(.class)\t\(.title)"'
)
[[ ${#rows[@]} -gt 0 ]] || exit 0

idx=$(
	for r in "${rows[@]}"; do
		IFS=$'\t' read -r _addr class title <<<"$r"
		# rofi extended-dmenu row:  display-text \0 icon \x1f <icon-name>
		printf '%s — %s\x00icon\x1f%s\n' "$class" "$title" "$class"
	done | rofi -dmenu -i -p "Windows" -show-icons -format i
) || exit 0
[[ -n "${idx:-}" ]] || exit 0

addr=$(printf '%s\n' "${rows[idx]}" | cut -f1)
hyprctl dispatch "hl.dsp.focus({ window = \"address:${addr}\" })"
