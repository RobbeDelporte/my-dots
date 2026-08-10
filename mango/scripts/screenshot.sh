#!/usr/bin/env bash
# Screenshot capture for mango: grab a target with grim/slurp, open it in a
# floating satty window to annotate, then copy-to-clipboard or save from satty.
# Save path, copy command, and early-exit live in satty's config.toml
# (~/.config/satty/config.toml), shared with the Hyprland path.
#
# grimblast is NOT usable here -- it hard-requires hyprctl in its dependency
# check -- so this is the mango twin of hypr/scripts/screenshot.sh.
#
#   screenshot.sh screen    all outputs            (Print)
#   screenshot.sh region    region select          (Super+Shift+S)
#   screenshot.sh window    focused window         (Super+Shift+Alt+S)
set -euo pipefail

target="${1:-}"
case "$target" in
	screen|region|window) ;;
	*) echo "usage: screenshot.sh screen|region|window" >&2; exit 1 ;;
esac

# satty saves here (see satty/config.toml output-filename); make sure it exists.
mkdir -p "$HOME/Pictures/Screenshots"

# Capture to a temp file first: a cancelled selection (Escape during slurp) then
# exits cleanly via "|| exit 0" instead of launching satty with empty input.
tmp=$(mktemp --suffix=.png)
trap 'rm -f "$tmp"' EXIT

case "$target" in
	screen)
		grim "$tmp"
		;;
	region)
		geom=$(slurp) || exit 0
		grim -g "$geom" "$tmp"
		;;
	window)
		# mmsg is mango's IPC client. The focused client reports its position and
		# size, which grim takes as an "X,Y WxH" geometry string.
		geom=$(mmsg get focusing-client \
			| jq -r 'if .x == null then empty else "\(.x),\(.y) \(.width)x\(.height)" end') || exit 0
		[[ -n "$geom" ]] || exit 0
		grim -g "$geom" "$tmp"
		;;
esac

# --resize smart: satty sizes its own window to the image, so a multi-monitor
# capture would otherwise open wider than one screen.
satty --resize smart --filename "$tmp"
