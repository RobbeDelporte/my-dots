# my-dots

Hyprland + mangowm + wayle dotfiles. Symlinked into `~/.config` **manually** (no installer).
Hyprland is the daily driver; mangowm is a second session picked at login (see [mango](#mango)).

## Symlink map

| Source (in repo) | Link | Type | Why |
|---|---|---|---|
| `hypr/` | `~/.config/hypr` | whole-dir | only hand-authored files |
| `mango/` | `~/.config/mango` | whole-dir | only hand-authored files |
| `kitty/` | `~/.config/kitty` | whole-dir | only hand-authored files |
| `matugen/` | `~/.config/matugen` | whole-dir | only hand-authored files |
| `nvim/` | `~/.config/nvim` | whole-dir | vendored config (~140 files) |
| `yazi/` | `~/.config/yazi` | whole-dir | `theme.toml` generated here (gitignored) |
| `rofi/` | `~/.config/rofi` | whole-dir | colors live in `generated/`, so dir stays clean |
| `wayle/` | `~/.config/wayle` | whole-dir | wayle atomically rewrites `runtime.toml`; generated files gitignored |
| `starship.toml` | `~/.config/starship.toml` | per-file | single file |
| `mimeapps.list` | `~/.config/mimeapps.list` | per-file | single file |
| `gtk/settings.ini` | `~/.config/gtk-3.0/settings.ini` & `gtk-4.0/settings.ini` | per-file | dir shared with generated `gtk.css` + GTK `bookmarks`; GTK never rewrites `settings.ini` |
| `zsh/.zshrc` | `~/.zshrc` | per-file | home dotfile |
| `zsh/.zprofile` | `~/.zprofile` | per-file | home dotfile |

**Linking rule:**
- **Whole-dir symlink by default.**
- **Per-file symlink** only when the target `~/.config/<app>` dir is shared with app-generated/runtime files **and the app never rewrites the tracked file** (gtk's `settings.ini`).
- If the app *atomically rewrites* a file you want tracked (wayle's `runtime.toml` — write-temp + rename, which would replace a per-file symlink with a real file), use a **whole-dir symlink and gitignore the generated files** (the yazi/wayle pattern).

Run `bin/doctor.sh` (read-only) to verify every link is healthy. Adding a new tracked app or per-file link means updating the `links` array in that script.

## matugen output flow

matugen renders templates (`matugen/templates/`) to **`generated/`** (gitignored), then post_hooks reload the apps. Consumers read from there:
- `generated/hypr-colors.conf` ← `hypr/hyprland.conf` sources it
- `generated/mango-colors.conf` ← `mango/config.conf` sources it (`source-optional`)
- `generated/kitty.conf` ← `kitty/kitty.conf` includes it (SIGUSR1 reload)
- `generated/hyprlock-colors.conf` ← `hypr/hyprlock.conf` sources it
- `generated/rofi-colors.rasi` ← `rofi/config.rasi` `@import`s it
- `yazi/theme.toml` (in the symlinked yazi dir, gitignored) and `~/.config/gtk-{3,4}.0/gtk.css` (real GTK dirs) stay in their app dirs by necessity.

## wayle

`~/.config/wayle` is a whole-dir symlink to `wayle/`. This setup is **GUI-driven**: you change settings in the wayle settings app, which writes **`runtime.toml`** — the **single tracked source of truth** (`my-dots/wayle/runtime.toml`). Because the whole dir is symlinked, those GUI writes land in the tracked file automatically, so your changes show up in `git status`.

wayle layers config as `defaults → config.toml → runtime.toml`; since everything lives in `runtime.toml`, **`config.toml` is intentionally empty and gitignored** (it's wayle's optional hand-edit layer, unused here). Everything else in the dir (`schema.json`, `config.toml.example`, `themes/`, `styles/`, `tombi.toml`) is wayle-generated and gitignored too — so `wayle/` tracks exactly one file. **`styling.theme-provider` must stay `"matugen"`** (self-theme from the wallpaper).

Note: wayle reformats `runtime.toml` (strips comments, reorders, expands floats) whenever the GUI writes it — expected. If the live bar ever ignores GUI edits right after a dotfiles change, run `wayle panel restart` (the daemon needs to re-attach to the dir).

**Do not remove the `awww` package** — it is wayle's wallpaper backend daemon (`wayle wallpaper set` drives `awww-daemon`). Removing it breaks wallpapers and the matugen self-theming chain.

## mango

[mangowm](https://github.com/mangowm/mango) (AUR `mangowm`) is a **second Wayland session**, not a replacement. Nothing in `hypr/` is shared or modified.

**Selecting it:** `zsh/.zprofile` runs `uwsm select` on tty1, which lists `/usr/share/wayland-sessions/*.desktop`; the package installs `mango.desktop`, so Mango just appears in that menu. Install with `yay -S mangowm`.

**`exec-once=uwsm finalize` in `mango/execs.conf` is load-bearing** and must stay first: mango has no native uwsm support, so without it `WAYLAND_DISPLAY` never reaches the systemd user session and every `uwsm app --` / `app2unit` launch (wayle, ydotoold, the Super+T terminal) silently fails.

**Config layering** mirrors `hypr/`: `config.conf` sources the tracked `colors.conf` fallback, then `generated/mango-colors.conf` (matugen override, `source-optional` so a fresh checkout parses), then `appearance/input/monitors/rules/keybinds/execs.conf`. Colours are `0xRRGGBBAA` — mango does not understand `rgba()`. Validate the whole tree without starting a session:

    mango -c ~/.config/mango/config.conf -p

`mmsg` is mango's IPC client (`mmsg get all-clients`, `mmsg dispatch <func>,<args>`) — the matugen post_hook uses `mmsg dispatch reload_config`.

**Differences from the Hyprland keymap** (deliberate, mango has no equivalent):
- **Tags, not workspaces:** 9 tags, so Super+1‑9 / Super+Alt+1‑9 work but Super+0 is gone.
- **Named scratchpads replace special workspaces:** Super+E, Super+D, Super+M and Ctrl+Shift+Escape use `toggle_named_scratchpad`, so `ws.sh`/`wstoggle.sh` are not needed. The appids in `rules.conf` must match the binds in `keybinds.conf`.
- **Dropped:** window groups/groupbar, `pin`, touchpad `gesture =` lines, and the negative pointer sensitivity (mango exposes no equivalent).
- `quit` is Ctrl+Alt+Delete (mango's stock Super+M would collide with the music scratchpad); `reload_config` is Super+Shift+R.

**Scripts:** `mango/scripts/{screenshot,record}.sh` exist because `grimblast` hard-requires `hyprctl` — they use `grim`/`slurp`/`mmsg` into the same satty hub and output dirs. `hypr/scripts/lock.sh` (awww + hyprlock) and `hypr/scripts/wallpicker.sh` (rofi + wayle) are protocol-generic and reused in place, so the mango binds point at `~/.config/hypr/scripts/`.

**Known gaps:**
- wayle's `hyprland-workspaces` module is Hyprland-only and `wayle/runtime.toml` is a single shared source of truth, so mango's bar has a dead spot in the left cluster. Every other module, plus the wallpaper and matugen chain, is compositor-agnostic.
- Screen sharing needs the **`xdg-desktop-portal-wlr`** package (installed 2026-08-10); `xdg-desktop-portal-hyprland` does not work outside Hyprland. No dotfiles config is needed: mangowm ships `/usr/share/xdg-desktop-portal/mango-portals.conf` (`ScreenCast`/`Screenshot` → `wlr`), which applies because the session sets `XDG_CURRENT_DESKTOP=mango`. Hyprland is unaffected — `hyprland-portals.conf` pins `default=hyprland;gtk`.
  Optional, if multi-monitor screencasts pick the wrong output: add `~/.config/xdg-desktop-portal-wlr/config` with `[screencast]` / `chooser_type=simple` / `chooser_cmd=slurp -f %o -or` to select the output with slurp. Not set up here.

## Layout

    bin/        repo-management scripts (doctor.sh) — not symlinked
    generated/  matugen output sink — gitignored
    <app>/      per-app config, symlinked into ~/.config (see map above)
