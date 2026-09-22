# my-dots

Hyprland + wayle dotfiles. Symlinked into `~/.config` **manually** (no installer).

## Symlink map

| Source (in repo) | Link | Type | Why |
|---|---|---|---|
| `hypr/` | `~/.config/hypr` | whole-dir | only hand-authored files |
| `kitty/` | `~/.config/kitty` | whole-dir | only hand-authored files |
| `foot/` | `~/.config/foot` | whole-dir | only hand-authored files; nvim's terminal (see below) |
| `matugen/` | `~/.config/matugen` | whole-dir | colour templates, rendered by skwd (name is historical) |
| `nvim/` | `~/.config/nvim` | whole-dir | vendored config (~140 files) |
| `yazi/` | `~/.config/yazi` | whole-dir | `theme.toml` generated here (gitignored) |
| `rofi/` | `~/.config/rofi` | whole-dir | colors live in `generated/`, so dir stays clean |
| `wayle/` | `~/.config/wayle` | whole-dir | wayle atomically rewrites `runtime.toml`; generated files gitignored |
| `starship.toml` | `~/.config/starship.toml` | per-file | single file |
| `mimeapps.list` | `~/.config/mimeapps.list` | per-file | single file |
| `nvim.desktop` | `~/.local/share/applications/nvim.desktop` | per-file | shadows the distro entry so nvim opens in foot |
| `yazi.desktop` | `~/.local/share/applications/yazi.desktop` | per-file | shadows the distro entry so yazi opens in kitty |
| `gtk/settings.ini` | `~/.config/gtk-3.0/settings.ini` & `gtk-4.0/settings.ini` | per-file | dir shared with generated `gtk.css` + GTK `bookmarks`; GTK never rewrites `settings.ini` |
| `zsh/.zshrc` | `~/.zshrc` | per-file | home dotfile |
| `zsh/.zprofile` | `~/.zprofile` | per-file | home dotfile |

**Linking rule:**
- **Whole-dir symlink by default.**
- **Per-file symlink** only when the target `~/.config/<app>` dir is shared with app-generated/runtime files **and the app never rewrites the tracked file** (gtk's `settings.ini`).
- If the app *atomically rewrites* a file you want tracked (wayle's `runtime.toml` — write-temp + rename, which would replace a per-file symlink with a real file), use a **whole-dir symlink and gitignore the generated files** (the yazi/wayle pattern).

Run `bin/doctor.sh` (read-only) to verify every link is healthy. Adding a new tracked app or per-file link means updating the `links` array in that script.

## colour output flow

skwd renders the templates in `matugen/templates/` to **`generated/`** (gitignored) on every wallpaper change, then each integration's reload command refreshes the app. Consumers read from there:
- `generated/hypr-colors.lua` ← `hypr/palette.lua` overlays it onto `hypr/colors.lua`
- `generated/kitty.conf` ← `kitty/kitty.conf` includes it (SIGUSR1 reload)
- `generated/foot-colors.ini` ← `foot/foot.ini` pulls it in with `include` (no reload signal; next launch)
- `generated/hyprlock-colors.conf` ← `hypr/hyprlock.conf` sources it
- `generated/rofi-colors.rasi` ← `rofi/config.rasi` `@import`s it
- `yazi/theme.toml` (in the symlinked yazi dir, gitignored) and `~/.config/gtk-{3,4}.0/gtk.css` (real GTK dirs) stay in their app dirs by necessity.

## Terminals

Two, on purpose:

| | binding | role | padding |
|---|---|---|---|
| **kitty** | `SUPER + T` | general shell work | `window_padding_width 10` |
| **foot** | `SUPER + C` | nvim only (`foot nvim`) | `pad 0x0 center` |

Splitting them is what lets nvim run near-zero padding, an opaque background and
a block cursor while the shell terminal keeps its roomy, translucent, beam-cursor
look. Both are driven from `hypr/hyprland/variables.lua` (`terminal`, `editor`,
`editorTerminal`, `keys.terminal`, `keys.editor`) and both follow the palette, sharing
one role mapping across `kitty.tmpl` and `foot.tmpl`.

Launching nvim from anywhere else lands in foot too: `nvim.desktop` (repo root,
symlinked into `~/.local/share/applications`) shadows the distro's `Terminal=true`
entry, and `mimeapps.list` points the text/code MIME types at it.

foot notes, all verified against 1.28 and all different from the ghostty config
this replaced:

- **The colors section must be `[colors-dark]`.** A bare `[colors]` is rejected
  outright (`invalid section name`), taking the whole file's colors with it.
- **`include` has no optional form** (ghostty's `?` prefix). A missing
  `generated/foot-colors.ini` is a config *error* — but foot drops only that one
  directive, logs it, and keeps everything else, so `foot.ini`'s static fallback
  palette still applies on a fresh checkout. It does expand `~/`, so no absolute
  path is hardcoded any more.
- **No reload signal at all.** `SIGUSR1`/`SIGUSR2` switch between the
  already-loaded dark/light themes; neither re-reads `foot.ini`. Colors land on
  next launch, hence no reload command (kitty's `pkill -USR1` has no analogue).
- **Rebinding replaces a default combo list**, so the seven `[key-bindings]`
  lines are themselves the unbind of foot's bare `Control+equal/minus/0` and
  `Shift+Page_Up/Down` grabs — the keys nvim needs back. With Shift as a
  modifier, only the unshifted keysym matches (`Control+Shift+equal`, never
  `Control+Shift+plus`).
- `foot --check-config` validates the file, including keysym names. Use it.

## Hyprland config (Lua)

Hyprland deprecated hyprlang (`.conf`) in favour of Lua in 0.55, and the
announcement gives the old syntax "1–2 releases starting from 0.55" — 0.55 and
0.56 have both shipped, so `.conf` support is expected to disappear in 0.57.
The compositor config is therefore Lua:

```
hypr/hyprland.lua          entry point; require()s everything below, in order
hypr/colors.lua            tracked static colour fallback
hypr/palette.lua           fallback + generated override → resolved palette
hypr/hyprland/*.lua        variables, monitors, input, animations, rules, keybinds, special, execs
```

The parallel `.conf` tree that this replaced is gone (it was kept as a rollback
path until the Lua config had been daily-driven). `hyprlock.conf` stays
hyprlang — hyprlock is not the compositor and never took Lua. To check which config is live: `hyprctl dispatch` evaluates **Lua**, so
a legacy `hyprctl dispatch exec echo` fails with a Lua syntax error while
`hyprctl dispatch 'hl.dsp.exec_cmd("true")'` returns `ok`.

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
- **hypr\* tools still use hyprlang.** `hyprlock.conf` stays
  `.conf`; only the compositor moved.

`hypr/.luarc.json` points lua_ls at `/usr/share/hypr/stubs`, so editing these
files gives completion and typechecking for the whole `hl.*` API. To test config
changes without logging out, run a nested instance:
`Hyprland -c ~/.config/hypr/hyprland.lua`. Once a Lua config is live,
`hyprctl repl` opens a REPL against the running compositor.

## wayle

`~/.config/wayle` is a whole-dir symlink to `wayle/`. This setup is **GUI-driven**: you change settings in the wayle settings app, which writes **`runtime.toml`** — the **single tracked source of truth** (`my-dots/wayle/runtime.toml`). Because the whole dir is symlinked, those GUI writes land in the tracked file automatically, so your changes show up in `git status`.

wayle layers config as `defaults → config.toml → runtime.toml`; since everything lives in `runtime.toml`, **`config.toml` is intentionally empty and gitignored** (it's wayle's optional hand-edit layer, unused here). Everything else in the dir (`schema.json`, `config.toml.example`, `themes/`, `styles/`, `tombi.toml`) is wayle-generated and gitignored too — so `wayle/` tracks exactly one file. **`styling.theme-provider` must stay `"wayle"`** — the static provider. wayle no longer extracts colours: skwd-wall owns the wallpaper, so wayle has no image to read. The bar therefore uses the fixed ten-colour `styling.palette` in `runtime.toml`, set once by hand. To re-pin it to the current wallpaper, render the palette and set it in one call (see **wallpapers** below).

Note: wayle reformats `runtime.toml` (strips comments, reorders, expands floats) whenever the GUI writes it — expected. If the live bar ever ignores GUI edits right after a dotfiles change, run `wayle panel restart` (the daemon needs to re-attach to the dir).

**wayle no longer draws the wallpaper.** `wallpaper.engine-enabled = false`, which is wayle's documented mode for running an external wallpaper tool while keeping the bar. See **wallpapers**.

## wallpapers

[skwd-wall](https://github.com/liixini/skwd-wall) is the wallpaper engine: stills, video and Wallpaper Engine scenes, rendered through Vulkan. `skwd-walld.service` (systemd **user** unit) owns wallpaper state across reboots; `skwd-paper` draws it. `SUPER+SHIFT+W` opens the picker.

    yay -S skwd-wall-v2-bin skwd-lens-bin
    systemctl --user enable --now skwd-walld.service

`skwd-helm` is the CLI — `apply`, `current --json`, `retheme`, `random`, `history`, `watch`. Anything needing the current wallpaper path reads `skwd-helm current --json` and filters for `type == "static"`; hyprlock draws an image and cannot render a video or a scene, so while one of those is up it keeps the previous still.

**Theming.** skwd's built-in **Iris** engine derives the palette from a frame of
the wallpaper — so video and Wallpaper Engine scenes theme the desktop, which
matugen could not do from an `.mp4` path. matugen is no longer used at all.

Rendering runs through skwd's **Integrations** (Settings → Matugen → Integrations):
ten entries, each mapping one template in `matugen/templates/` to its output and
an optional reload command. They are stored in `skwd/config.json`. skwd's
renderer takes the same `{{colors.<role>.default.hex}}` / `.hex_stripped` tokens
matugen did, so the templates were carried over unchanged.

Two things worth knowing:

- **The engine setting is load-bearing and silent.** If `theme.engine` flips from
  `native` back to something else, integrations stop rendering and every app
  silently keeps the *last* wallpaper's colours. Check it with
  `jq -r .theme.engine ~/.config/skwd-wall-v2/config.json`, and the journal
  (`journalctl --user -u skwd-walld -g 'static templates'`) should log
  `rendered 10 integration file(s)` on every apply.
- **App themes stays Off** for kitty, rofi, yazi and foot. Those show *"Setup
  needs review"* in skwd's settings — that is skwd noticing the files already
  carry colours it did not write. It is a detection notice, not an error, and
  turning them on would make skwd write into `~/.config/<app>`, which are
  symlinks into this repo. `btop` is the one app left on managed theming, since
  nothing here templates it.

**The bar does not follow the wallpaper.** That is the one deliberate gap: wayle's palette is static (see **wayle**). To re-pin it to the current wallpaper:

    # read the current palette straight out of the rendered output
    grep -E '^(background|color4) ' ~/my-dots/generated/kitty.conf
    wayle config set styling.palette '{bg="#…",surface="#…",elevated="#…",fg="#…",fg-muted="#…",primary="#…",red="#…",yellow="#f9e2af",green="#a6e3a1",blue="#…"}'

Note `wayle config set` takes a **TOML inline table**; the JSON form is silently ignored, and its `Set … = …` echo prints the *pre-change* value — only a following `wayle config get` is evidence.

## Layout

    bin/        repo-management scripts (doctor.sh) — not symlinked
    generated/  colour output sink — gitignored
    <app>/      per-app config, symlinked into ~/.config (see map above)
