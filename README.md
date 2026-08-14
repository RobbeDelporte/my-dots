# my-dots

Hyprland + wayle dotfiles. Symlinked into `~/.config` **manually** (no installer).

## Symlink map

| Source (in repo) | Link | Type | Why |
|---|---|---|---|
| `hypr/` | `~/.config/hypr` | whole-dir | only hand-authored files |
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
- `generated/hypr-colors.lua` ← `hypr/palette.lua` overlays it onto `hypr/colors.lua`
- `generated/hypr-colors.conf` ← `hypr/hyprland.conf` sources it (legacy, see below)
- `generated/kitty.conf` ← `kitty/kitty.conf` includes it (SIGUSR1 reload)
- `generated/hyprlock-colors.conf` ← `hypr/hyprlock.conf` sources it
- `generated/rofi-colors.rasi` ← `rofi/config.rasi` `@import`s it
- `yazi/theme.toml` (in the symlinked yazi dir, gitignored) and `~/.config/gtk-{3,4}.0/gtk.css` (real GTK dirs) stay in their app dirs by necessity.

## Hyprland config (Lua)

Hyprland deprecated hyprlang (`.conf`) in favour of Lua in 0.55, and the
announcement gives the old syntax "1–2 releases starting from 0.55" — 0.55 and
0.56 have both shipped, so `.conf` support is expected to disappear in 0.57.
The compositor config is therefore Lua:

```
hypr/hyprland.lua          entry point; require()s everything below, in order
hypr/colors.lua            tracked static colour fallback
hypr/palette.lua           fallback + matugen override → resolved palette
hypr/hyprland/*.lua        variables, monitors, input, animations, rules, keybinds, special, execs
```

Hyprland picks `hyprland.lua` over `hyprland.conf` **once, at startup** — there
is no live switching. The old `.conf` tree is still tracked as a rollback path:
rename `hypr/hyprland.lua` out of the way and the next login falls back to
hyprlang. Delete both the `.conf` files and matugen's `[templates.hypr-colors]`
block once the Lua config has been daily-driven.

Notes that bit during the migration and are easy to re-break:

- **`require()` is not `source =`.** Each require is its own Lua scope, so
  hyprlang's global `$vars` became modules that `return` a table. A require of a
  *nonexistent* module raises a real error that kills the calling file — which is
  why `palette.lua` probes for the generated palette with `io.open` + `pcall`
  instead of requiring it. Under hyprlang a missing `source` was just a warning.
- **Window-rule order.** Hyprland evaluates all *named* rules before all
  anonymous ones. `hyprland/rules.lua` is deliberately 100% anonymous so plain
  top-to-bottom order is preserved; adding a `name` to one rule silently
  promotes it above every unnamed rule below it.
- **Regexes need `[[long strings]]`.** `"\."` is not a valid Lua escape and is a
  syntax error, which stops the whole file from loading.
- **`resize` takes pixels, not percentages.** hyprlang's `resizeactive -10% 0`
  has no direct equivalent; `keybinds.lua` resolves the fraction against the
  focused monitor (`hl.get_active_monitor()`, physical size ÷ scale).
- **hypr\* tools still use hyprlang.** `hypridle.conf` and `hyprlock.conf` stay
  `.conf`; only the compositor moved.

`hypr/.luarc.json` points lua_ls at `/usr/share/hypr/stubs`, so editing these
files gives completion and typechecking for the whole `hl.*` API. To test config
changes without logging out, run a nested instance:
`Hyprland -c ~/.config/hypr/hyprland.lua`. Once a Lua config is live,
`hyprctl repl` opens a REPL against the running compositor.

## wayle

`~/.config/wayle` is a whole-dir symlink to `wayle/`. This setup is **GUI-driven**: you change settings in the wayle settings app, which writes **`runtime.toml`** — the **single tracked source of truth** (`my-dots/wayle/runtime.toml`). Because the whole dir is symlinked, those GUI writes land in the tracked file automatically, so your changes show up in `git status`.

wayle layers config as `defaults → config.toml → runtime.toml`; since everything lives in `runtime.toml`, **`config.toml` is intentionally empty and gitignored** (it's wayle's optional hand-edit layer, unused here). Everything else in the dir (`schema.json`, `config.toml.example`, `themes/`, `styles/`, `tombi.toml`) is wayle-generated and gitignored too — so `wayle/` tracks exactly one file. **`styling.theme-provider` must stay `"matugen"`** (self-theme from the wallpaper).

Note: wayle reformats `runtime.toml` (strips comments, reorders, expands floats) whenever the GUI writes it — expected. If the live bar ever ignores GUI edits right after a dotfiles change, run `wayle panel restart` (the daemon needs to re-attach to the dir).

**Do not remove the `awww` package** — it is wayle's wallpaper backend daemon (`wayle wallpaper set` drives `awww-daemon`). Removing it breaks wallpapers and the matugen self-theming chain.

## Layout

    bin/        repo-management scripts (doctor.sh) — not symlinked
    generated/  matugen output sink — gitignored
    <app>/      per-app config, symlinked into ~/.config (see map above)
