#!/usr/bin/env bash
# Interactive drag-to-place editor for the wallpaper clock.
#
# Launches the GTK overlay editor (place.py), which lets you drag a proxy of the
# clock and prints the chosen top-left "<x> <y>" (output-local logical px) or
# "CANCEL". This script then persists the position PER WALLPAPER in
# positions.conf and applies it via the existing reposition.sh.
#
# Bound to Super+Ctrl+W (Hyprland). See
# docs/superpowers/specs/2026-06-24-eww-clock-drag-place-design.md.
set -uo pipefail

cfg="$HOME/.config/eww"
conf="$cfg/positions.conf"
editor="$cfg/place.py"
gen="$HOME/my-dots/generated/eww-colors.scss"

# Rewrite positions.conf, replacing the entry for <key> (basename) or appending
# it. Comments and all other entries pass through verbatim; missing file is
# created. $3 is the right-hand side, e.g. "top left | 740px 300px".
upsert_position() {
  local conf="$1" key="$2" rhs="$3"
  local tmp; tmp="$(mktemp)"
  local written=0 line lhs
  if [[ -f "$conf" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" =~ ^[[:space:]]*# ]]; then
        printf '%s\n' "$line" >> "$tmp"; continue
      fi
      lhs="${line%%=*}"
      lhs="${lhs#"${lhs%%[![:space:]]*}"}"   # ltrim
      lhs="${lhs%"${lhs##*[![:space:]]}"}"   # rtrim
      if [[ "$lhs" == "$key" ]]; then
        printf '%s = %s\n' "$key" "$rhs" >> "$tmp"; written=1
      else
        printf '%s\n' "$line" >> "$tmp"
      fi
    done < "$conf"
  fi
  (( written )) || printf '%s = %s\n' "$key" "$rhs" >> "$tmp"
  mv "$tmp" "$conf"
}

# Live wallpaper path (same parse as reposition.sh).
current_wallpaper() { awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1; }

# Echo "<x> <y>": the LOGICAL layout origin of the focused output, so the editor
# opens on (and seeds from) the screen the user is on. Matched against
# GdkMonitor geometry in place.py. Empty -> editor falls back to the default.
focused_origin() {
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
    hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | "\(.x) \(.y)"' | head -1
  fi
}

# Echo "anchor|xoff|yoff" for <basename> from positions.conf (defaults when
# absent: the same fallback reposition.sh uses).
current_entry() {
  local base="$1" anchor="center right" xoff=60 yoff=0 line spec off
  if [[ -f "$conf" ]]; then
    line=$(grep -v '^[[:space:]]*#' "$conf" 2>/dev/null | grep -F -- "$base =" | head -1 || true)
    if [[ -n "$line" ]]; then
      spec=${line#*=}
      if [[ "$spec" == *"|"* ]]; then
        anchor=$(echo "${spec%%|*}" | xargs)
        off=${spec#*|}
        xoff=$(echo "$off" | awk '{print $1}' | tr -dc '0-9-'); xoff=${xoff:-0}
        yoff=$(echo "$off" | awk '{print $2}' | tr -dc '0-9-'); yoff=${yoff:-0}
      else
        anchor=$(echo "$spec" | xargs); xoff=0; yoff=0
      fi
    fi
  fi
  printf '%s|%s|%s' "$anchor" "$xoff" "$yoff"
}

main() {
  command -v awww >/dev/null 2>&1 || { notify-send "Clock placer" "awww not found"; exit 1; }
  command -v python3 >/dev/null 2>&1 || { notify-send "Clock placer" "python3 not found"; exit 1; }

  local wall base
  wall="$(current_wallpaper)"
  base="$(basename "${wall:-}")"
  if [[ -z "$wall" || -z "$base" ]]; then
    notify-send "Clock placer" "No wallpaper loaded; nothing to place."
    exit 0
  fi

  # Clock footprint from eww.yuck (fallback 660x360) so the proxy can't drift.
  local W H
  W=$(grep -oP ':width\s+"\K[0-9]+' "$cfg/eww.yuck" 2>/dev/null | head -1); W=${W:-660}
  H=$(grep -oP ':height\s+"\K[0-9]+' "$cfg/eww.yuck" 2>/dev/null | head -1); H=${H:-360}

  # Accent from the matugen palette (fallback = launch.sh's static accent).
  local accent
  accent=$(grep -oP '\$clock-accent:\s*\K#[0-9a-fA-F]{6}' "$gen" 2>/dev/null | head -1)
  accent=${accent:-#8bd0f0}

  # Seed the editor from the current entry.
  local entry anchor xoff yoff
  entry="$(current_entry "$base")"
  anchor="${entry%%|*}"; entry="${entry#*|}"
  xoff="${entry%%|*}"; yoff="${entry#*|}"

  # Hide the live clock while editing; ALWAYS reopen on exit (--open forces a
  # reopen even on cancel; no path -> reposition.sh re-queries awww itself, which
  # also sidesteps the EXIT trap firing after main's locals are out of scope).
  trap '"$cfg/reposition.sh" --open >/dev/null 2>&1 || true' EXIT
  local w
  for w in $(eww active-windows 2>/dev/null | sed -n 's/^\(clock-[0-9]*\):.*/\1/p'); do
    eww close "$w" >/dev/null 2>&1 || true
  done

  # Open on the focused output (so the seed + drag coords match that screen).
  local origin monargs=()
  origin="$(focused_origin)"
  if [[ "$origin" =~ ^-?[0-9]+\ -?[0-9]+$ ]]; then
    monargs=(--mon-x "${origin%% *}" --mon-y "${origin##* }")
  fi

  # Run the editor; it prints "<x> <y>" or "CANCEL" on stdout.
  local out x y
  out="$(python3 "$editor" --anchor "$anchor" --xoff "$xoff" --yoff "$yoff" \
        --w "$W" --h "$H" --accent "$accent" "${monargs[@]}" 2>/dev/null)"
  if [[ "$out" =~ ^([0-9]+)\ ([0-9]+)$ ]]; then
    x="${BASH_REMATCH[1]}"; y="${BASH_REMATCH[2]}"
    upsert_position "$conf" "$base" "top left | ${x}px ${y}px"
    notify-send "Clock placed" "$base → top left | ${x}px ${y}px"
  fi
  # EXIT trap reopens the clock (new position if saved, old if cancelled).
}

# Only run when executed, not when sourced (the test sources this file).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
