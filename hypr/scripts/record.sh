#!/usr/bin/env bash
# Screen recorder toggle for Hyprland (wf-recorder + slurp).
# Requires: sudo pacman -S wf-recorder   (slurp is already installed)
#
#   record.sh        full screen, no audio        (Ctrl+Alt+R)
#   record.sh -s     select a region, no audio    (Super+Alt+R)
#   record.sh -r     full screen, with audio      (Super+Shift+Alt+R)
#
# Any invocation while a recording is running STOPS it (and saves the file).
set -euo pipefail

out_dir="${XDG_VIDEOS_DIR:-$HOME/Videos}/Screenrecordings"
mkdir -p "$out_dir"

# Already recording? -> stop, save, notify.
if pgrep -x wf-recorder >/dev/null; then
	pkill -INT -x wf-recorder
	notify-send "Recording" "Stopped — saved to $out_dir" 2>/dev/null || true
	exit 0
fi

command -v wf-recorder >/dev/null || {
	notify-send "Recording" "wf-recorder not installed (sudo pacman -S wf-recorder)" 2>/dev/null || true
	exit 1
}

file="$out_dir/rec-$(date +%Y%m%d-%H%M%S).mp4"
args=(-f "$file")
case "${1:-}" in
	-s) geom=$(slurp) || exit 0; args+=(-g "$geom") ;;
	-r) args+=(--audio) ;;
esac

notify-send "Recording" "Started → $(basename "$file")" 2>/dev/null || true
exec wf-recorder "${args[@]}"
