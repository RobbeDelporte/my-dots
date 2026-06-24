#!/usr/bin/env bash
# Integration test for place.sh main() glue. Fully mocked: no real display,
# clock, keyboard, or compositor are touched. Verifies that a successful editor
# result flows through to a positions.conf upsert, the clock is hidden then
# reopened, and a notification fires.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$here/.."

tmpd="$(mktemp -d)"
trap 'rm -rf "$tmpd"' EXIT
bin="$tmpd/bin"; fcfg="$tmpd/cfg"
mkdir -p "$bin" "$fcfg"

# --- fake external commands on PATH ---
cat > "$bin/awww" <<'X'
#!/usr/bin/env bash
[[ "$1" == query ]] && echo ": HDMI-A-1: 2560x1440, scale: 1, currently displaying: image: /home/robbe/Pictures/Wallpapers/crashed-spaceship.jpg"
exit 0
X
cat > "$bin/eww" <<'X'
#!/usr/bin/env bash
case "$1" in
  active-windows) printf 'clock-0: clock\nclock-1: clock\n' ;;
  close) echo "close $2" >> "$EWW_LOG" ;;
esac
X
cat > "$bin/hyprctl" <<'X'
#!/usr/bin/env bash
[[ "$1 $2" == "monitors -j" ]] && echo '[{"name":"HDMI-A-1","focused":true,"x":2400,"y":0}]'
X
cat > "$bin/notify-send" <<'X'
#!/usr/bin/env bash
echo "$*" >> "$NOTIFY_LOG"
X
chmod +x "$bin"/*

# --- fake config dir (cfg) ---
cat > "$fcfg/eww.yuck" <<'X'
:width "660px"
:height "360px"
X
cat > "$fcfg/reposition.sh" <<'X'
#!/usr/bin/env bash
echo "reposition $*" >> "$REPO_LOG"
X
chmod +x "$fcfg/reposition.sh"
# Fake editor: ignores args, returns a fixed result as the real one would.
cat > "$fcfg/place.py" <<'X'
#!/usr/bin/env python3
print("1780 320")
X
cat > "$fcfg/eww-colors.scss" <<'X'
$clock-accent: #a2cde2;
X

conf_file="$tmpd/positions.conf"
cat > "$conf_file" <<'X'
# header comment
crashed-spaceship.jpg = top right | 120px 320px
other.jpg = center | 0px 0px
X

# --- run main() with overridden globals + mocked env ---
source "$repo/eww/place.sh"
cfg="$fcfg"; conf="$conf_file"; editor="$fcfg/place.py"; gen="$fcfg/eww-colors.scss"
export PATH="$bin:$PATH"
export EWW_LOG="$tmpd/eww.log" NOTIFY_LOG="$tmpd/notify.log" REPO_LOG="$tmpd/repo.log"
export HYPRLAND_INSTANCE_SIGNATURE="test"   # route focused_origin through hyprctl
: > "$tmpd/eww.log"; : > "$tmpd/notify.log"; : > "$tmpd/repo.log"

( main ) >/dev/null 2>&1

pass=0; fail=0
ok() { if eval "$2"; then echo "PASS: $1"; ((pass++)); else echo "FAIL: $1"; ((fail++)); fi; }

ok "positions.conf upserted to top-left for the current wallpaper" \
   'grep -qx "crashed-spaceship.jpg = top left | 1780px 320px" "$conf_file"'
ok "header comment preserved" \
   'grep -qx "# header comment" "$conf_file"'
ok "other entry preserved" \
   'grep -qx "other.jpg = center | 0px 0px" "$conf_file"'
ok "live clock windows were closed" \
   'grep -q "close clock-0" "$tmpd/eww.log" && grep -q "close clock-1" "$tmpd/eww.log"'
ok "clock reopened on exit (reposition --open)" \
   'grep -q "reposition --open" "$tmpd/repo.log"'
ok "placement notification fired" \
   'grep -q "1780px 320px" "$tmpd/notify.log"'

echo "== $pass passed, $fail failed =="
[[ $fail -eq 0 ]]
