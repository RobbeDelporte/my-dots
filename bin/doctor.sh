#!/usr/bin/env bash
# doctor.sh — read-only health check for my-dots symlinks. No mutation.
# Reports each expected link as ok / DANGLING / WRONG / MISSING.
# Exit non-zero if any problem. Run: bin/doctor.sh
set -uo pipefail

REPO="${MYDOTS:-$HOME/my-dots}"
CFG="$HOME/.config"
fail=0

# "<link path>|<target relative to repo>"
# Whole-dir links by default. Per-file only where ~/.config/<app> is shared with
# app-generated/runtime files AND the app never rewrites the tracked file
# (gtk settings.ini). wayle is whole-dir: wayle atomically rewrites runtime.toml,
# which would break a per-file symlink — so the whole dir is linked and the
# generated files inside are gitignored.
links=(
  "$CFG/hypr|hypr"
  "$CFG/kitty|kitty"
  "$CFG/matugen|matugen"
  "$CFG/nvim|nvim"
  "$CFG/yazi|yazi"
  "$CFG/rofi|rofi"
  "$CFG/wayle|wayle"
  "$CFG/starship.toml|starship.toml"
  "$CFG/mimeapps.list|mimeapps.list"
  "$CFG/gtk-3.0/settings.ini|gtk/settings.ini"
  "$CFG/gtk-4.0/settings.ini|gtk/settings.ini"
  "$HOME/.zshrc|zsh/.zshrc"
  "$HOME/.zprofile|zsh/.zprofile"
)

red=$'\033[31m'; grn=$'\033[32m'; ylw=$'\033[33m'; rst=$'\033[0m'

check() {
  local link="$1" rel="$2"
  local want="$REPO/$rel"
  if [[ ! -L "$link" ]]; then
    if [[ -e "$link" ]]; then
      printf '  %s✘ WRONG%s    %s is a real file, expected symlink -> %s\n' "$red" "$rst" "$link" "$want"
    else
      printf '  %s✘ MISSING%s  %s (expected -> %s)\n' "$red" "$rst" "$link" "$want"
    fi
    fail=1; return
  fi
  if [[ ! -e "$link" ]]; then
    printf '  %s✘ DANGLING%s %s -> %s (target missing)\n' "$red" "$rst" "$link" "$(readlink "$link")"
    fail=1; return
  fi
  if [[ "$(readlink -f "$link")" != "$(readlink -f "$want")" ]]; then
    printf '  %s✘ WRONG%s    %s -> %s (expected -> %s)\n' "$ylw" "$rst" "$link" "$(readlink "$link")" "$want"
    fail=1; return
  fi
  printf '  %s✔ ok%s       %s\n' "$grn" "$rst" "$link"
}

echo "my-dots symlink doctor ($REPO)"
for entry in "${links[@]}"; do
  check "${entry%%|*}" "${entry##*|}"
done

if [[ "$fail" -eq 0 ]]; then
  echo "All links healthy."
else
  echo "Problems found (see above). Fix manually, then re-run."
fi
exit "$fail"
