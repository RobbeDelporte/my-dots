#!/usr/bin/env bash
# Screen recorder toggle for mango (wf-recorder + slurp).
# Requires: wf-recorder, slurp, jq, mmsg (mango's IPC client).
#
#   record.sh        full screen, no audio        (Ctrl+Alt+R)
#   record.sh -s     select a region, no audio    (Super+Alt+R)
#   record.sh -r     full screen, with audio      (Super+Shift+Alt+R)
#
# Any invocation while a recording is running STOPS it (and saves the file).
# mango twin of hypr/scripts/record.sh: identical except the focused-output
# lookup, which uses mmsg instead of hyprctl.
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

# With >1 monitor, wf-recorder prompts for an output on stdin and dies instantly
# when launched from a keybind (no tty). Pin full-screen captures to the focused
# monitor via -o; region (-g) auto-detects its output from the geometry.
focused=$(mmsg get all-monitors 2>/dev/null \
	| jq -r 'if type == "array" then .[] else . end | select(.is_focused // .focused // false) | .name' \
	| head -1 || true)

# Built once, in `if` form: a bare `[[ ... ]] && ...` as the last command of a
# case branch would return 1 and abort the script under `set -e`.
out_args=()
if [[ -n "$focused" ]]; then
	out_args=(-o "$focused")
fi

file="$out_dir/rec-$(date +%Y%m%d-%H%M%S).mp4"
args=(-f "$file")
case "${1:-}" in
	-s) geom=$(slurp) || exit 0; args+=(-g "$geom") ;;   # region: output auto-detected
	-r) args+=("${out_args[@]}" --audio) ;;              # full screen, with audio
	*)  args+=("${out_args[@]}") ;;                      # full screen, no audio
esac

notify-send "Recording" "Started → $(basename "$file")" 2>/dev/null || true
exec wf-recorder "${args[@]}"
