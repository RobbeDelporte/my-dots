#!/usr/bin/env bash
# Screenshot capture for Hyprland: grab a target with grimblast, open it in a
# floating satty window to annotate, then copy-to-clipboard or save from satty.
# Save path, copy command, and early-exit live in satty's config.toml
# (~/.config/satty/config.toml) so the swayimg "e -> satty" path behaves the same.
#
#   screenshot.sh screen    all outputs            (Print)
#   screenshot.sh region    frozen region select   (Super+Shift+S)
#   screenshot.sh window    active window          (Super+Shift+Alt+S)
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
	screen) grimblast save screen "$tmp" ;;
	region) grimblast --freeze save area "$tmp" ;;
	window) grimblast save active "$tmp" ;;
esac || exit 0

satty --filename "$tmp"
