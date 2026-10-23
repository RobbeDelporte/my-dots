#!/usr/bin/env bash
# Switch to a normal workspace, first collapsing any special workspace that is
# open on the focused monitor. Hyprland has no native option for this, so we
# query the focused monitor and toggle its special off before switching.
#   usage: ws.sh <workspace-arg>   e.g. ws.sh 3 | ws.sh e+1 | ws.sh e-1
set -euo pipefail

sp=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .specialWorkspace.name // empty')
if [[ -n "$sp" ]]; then
    # .specialWorkspace.name looks like "special:files"; toggle wants "files".
    hyprctl dispatch togglespecialworkspace "${sp#special:}"
fi
hyprctl dispatch workspace "$@"
