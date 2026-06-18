#!/usr/bin/env bash
# Start the eww daemon and open the wallpaper clock on every output.
# Autostarted on Hyprland (execs.conf) and niri (autostart.kdl); idempotent.
set -uo pipefail

cfg="$HOME/.config/eww"
gen="$HOME/my-dots/generated/eww-colors.scss"

# eww.scss @imports the matugen palette by absolute path and the Sass engine
# hard-errors if it is missing (fresh checkout, before the first matugen render).
# Drop a static fallback so styles always compile; the next render overwrites it.
if [[ ! -f "$gen" ]]; then
  mkdir -p "$(dirname "$gen")"
  cat > "$gen" <<'EOF'
$clock-month: #cfcfcf;
$clock-accent: #8bd0f0;
$clock-fg: #e8e8e8;
EOF
fi

command -v eww >/dev/null 2>&1 || { echo "launch.sh: eww not installed" >&2; exit 1; }

# Wait for the wallpaper daemon to report outputs so we open on the right screens
# (awww comes up via wayle at session start; give it a few seconds).
for _ in $(seq 1 25); do
  awww query >/dev/null 2>&1 && break
  sleep 0.2
done

eww daemon >/dev/null 2>&1 || true

# Open + place all windows for the current wallpaper (reposition passes the
# per-output --arg anchor/x/y and forces the open).
"$cfg/reposition.sh" --open
