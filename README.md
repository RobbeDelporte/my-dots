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
- `generated/hypr-colors.conf` ← `hypr/hyprland.conf` sources it
- `generated/kitty.conf` ← `kitty/kitty.conf` includes it (SIGUSR1 reload)
- `generated/hyprlock-colors.conf` ← `hypr/hyprlock.conf` sources it
- `generated/rofi-colors.rasi` ← `rofi/config.rasi` `@import`s it
- `yazi/theme.toml` (in the symlinked yazi dir, gitignored) and `~/.config/gtk-{3,4}.0/gtk.css` (real GTK dirs) stay in their app dirs by necessity.

## wayle

`~/.config/wayle` is a whole-dir symlink to `wayle/`. wayle layers config as:

    defaults  ->  config.toml  ->  runtime.toml (GUI scratch)

Both `config.toml` and `runtime.toml` are tracked. The wayle-settings GUI / `wayle config set` write `runtime.toml` (via atomic rename) — because the whole dir is symlinked, those writes land in the tracked `wayle/runtime.toml` automatically, so GUI edits show up in `git status`. Everything else in the dir (`schema.json`, `config.toml.example`, `themes/`, `styles/`, `tombi.toml`) is wayle-generated and gitignored. **`styling.theme-provider` must stay `"matugen"`** (self-theme from the wallpaper).

**Do not remove the `awww` package** — it is wayle's wallpaper backend daemon (`wayle wallpaper set` drives `awww-daemon`). Removing it breaks wallpapers and the matugen self-theming chain.

## Layout

    bin/        repo-management scripts (doctor.sh) — not symlinked
    generated/  matugen output sink — gitignored
    <app>/      per-app config, symlinked into ~/.config (see map above)
