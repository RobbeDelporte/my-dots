# my-dots: prune + restructure for coherence

**Date:** 2026-06-04
**Status:** design (awaiting review)

## Problem

The dotfiles were assembled piecemeal (caelestia → wayle, fuzzel → rofi, adi1090x
pack dumped in wholesale). The desktop *works*, but the repo no longer reads as a
coherent description of how the setup functions:

- **Tracked state ≠ on-disk state.** rofi was flattened on disk (`config.rasi`,
  `launcher.rasi`, `colors.rasi`, `powermenu.{rasi,sh}`) and the adi1090x
  `type-N/style-N` pack moved out to `~/my-dots/rofi-gallery/`, but the git index
  still has ~209 of the old sprawl files staged. `git status` describes a tree
  that isn't on disk.
- **Live breakage.** `Ctrl+Alt+Del` runs `~/.config/rofi/powermenu/type-5/powermenu.sh`,
  a path that no longer exists (now `~/.config/rofi/powermenu.sh`).
- **Host-specific file is committed.** `.gitignore` ignores `hypr/monitors.conf`,
  but the file lives at `hypr/hyprland/monitors.conf` and is tracked.
- **Stale ghosts.** `.zprofile` and `.gitignore` reference the removed
  `scripts/install.sh`; `matugen/templates/wlogout.tmpl` is orphaned (not wired
  into `config.toml`); `fuzzel.tmpl` is mid-deletion.
- **No map.** The architecture (symlink model + wallpaper→theme pipeline + wayle
  config layering) is explained only in scattered inline comments — nothing in the
  repo tells the whole story.

## Goals

1. The repo's tracked tree matches on-disk reality.
2. The repo holds **tracked source only** — generated and host-specific files are
   never committed.
3. **One tool per job** — one launcher, one power menu, no orphan duplicates.
4. Every path, comment, and gitignore entry matches reality (no stale references).
5. A reader can open the repo and understand how the setup works without
   reverse-engineering it (top-level `README.md` + `docs/theming.md`).

## Non-goals

- No tool swaps. Keep Hyprland, wayle, matugen, rofi, kitty, yazi, nvim, zsh.
- No change to the working wallpaper→theme pipeline mechanism (wayle runs matugen,
  captures its `--json`; per-app templates render colors). We document and tidy it,
  we don't redesign it.
- No nvim refactor (vendored upstream; out of scope).

## Decisions (confirmed with user)

| Decision | Choice |
|---|---|
| Power menu | Keep rofi powermenu; **fully remove wlogout** (orphan template + flag binary for uninstall) |
| `rofi-gallery/` | **Delete it** (adi1090x pack is re-downloadable) |
| State dir | **Rename matugen outputs** to `~/.local/state/theme/`; wayle keeps `~/.local/state/wayle/` for its own runtime files |

## Change set

### 1. Reconcile git index ↔ disk (core fix)
- Bring the tracked tree in line with the flattened on-disk rofi: track
  `rofi/config.rasi`, `rofi/launcher.rasi`, `rofi/powermenu.rasi`,
  `rofi/powermenu.sh`; drop the phantom-staged `type-N/style-N`, `applets/`,
  `colors/`, `launchers/` paths from the index.
- `rofi/colors.rasi` and `rofi/images/` remain gitignored (already are).
- **Execution note:** user commits in parallel — re-check `git status` live and
  stage explicit paths at execution time; do not assume the snapshot in this spec.

### 2. Fix breakage
- `hypr/hyprland/keybinds.conf`: repoint `Ctrl+Alt+Del` from
  `~/.config/rofi/powermenu/type-5/powermenu.sh` → `~/.config/rofi/powermenu.sh`.
  Fix the stale trailing comment (`type-2/style-9` / `type-5` mismatch).
- `.gitignore`: change `hypr/monitors.conf` → `hypr/hyprland/monitors.conf`.
- Untrack the host-specific file: `git rm --cached hypr/hyprland/monitors.conf`
  (leave the working file in place).

### 3. Remove stale ghosts
- `zsh/.zprofile`: drop the "symlinked by scripts/install.sh" comment; keep the
  UWSM TTY1 autostart logic and the `EDITOR`/`VISUAL` exports.
- `.gitignore`: drop the "managed by install.sh" wording on the monitors line.
- Delete `matugen/templates/wlogout.tmpl` (orphan) and `matugen/templates/fuzzel.tmpl`
  (mid-deletion).
- Add a one-line note in `README.md` that `wlogout` is no longer used and can be
  uninstalled (`pacman -Rns wlogout` or equivalent) — leaving removal as a manual
  step, not run automatically.

### 4. Rename state dir for matugen outputs → `~/.local/state/theme/`
Move **only matugen-generated files**; wayle's own runtime files stay in
`~/.local/state/wayle/`.

Files to update (exact list):
- `matugen/config.toml`: three `output_path`s
  (`colors.conf`, `kitty.conf`, `hyprlock-colors.conf`) → `~/.local/state/theme/…`;
  update the explanatory comments that name the wayle dir.
- `hypr/hyprland.conf:4`: `source = ~/.local/state/theme/colors.conf`.
- `hypr/hyprlock.conf:18`: `source = ~/.local/state/theme/hyprlock-colors.conf`.
  **Leave line 19** (`hyprlock-wallpaper.conf`) pointing at `~/.local/state/wayle/`
  — that file is written by wayle, not matugen.
- `kitty/kitty.conf:47`: `include ${HOME}/.local/state/theme/kitty.conf`; update
  the comment on line 2.

Migration: after repointing, trigger a re-theme (`wayle wallpaper set …` or a
matugen render) so `~/.local/state/theme/` is populated, then delete the three now
orphaned matugen files from `~/.local/state/wayle/` (`colors.conf`, `kitty.conf`,
`hyprlock-colors.conf`). The static fallbacks (`hypr/colors.conf`, kitty defaults)
keep everything valid in the gap before the first render.

### 5. Restructure for data-flow clarity + the map
- Delete `~/my-dots/rofi-gallery/`.
- Add `docs/theming.md`: the wallpaper→theme pipeline (trigger → wayle → matugen →
  templates → outputs → reload hooks), the wayle `config.toml` vs `runtime.toml`
  layering, and **the one generated-file convention** (below).
- Add top-level `README.md`: symlink model, pipeline diagram, tool inventory
  (what each tool is used for), pointer to `docs/theming.md`.

**The generated-file convention (documented and enforced):**
> The repo holds tracked source only. Generated theme files are gitignored and live
> where each app requires them: in the shared state dir `~/.local/state/theme/`
> when the config dir already has a tracked fallback of that name (hypr); in-place
> and gitignored otherwise (rofi `colors.rasi`, yazi `theme.toml`, gtk `gtk.css`).
> Host-specific files (`hypr/hyprland/monitors.conf`) are gitignored too.

## Risks & verification

- **State-dir rename leaves a gap before first render.** Mitigated by the static
  fallbacks; verify hyprland/kitty/hyprlock still load with no override present,
  then verify colors reappear after a `wayle wallpaper set`.
- **Git reconciliation could touch the user's in-flight work.** Mitigated by
  re-checking `git status` live and staging explicit paths only.
- **hyprlock split (colors in `theme/`, wallpaper in `wayle/`)** — verify hyprlock
  still themes correctly and shows the blurred wallpaper after the change.
- Verification checklist at execution: `Super+Space` (drun), `Ctrl+Alt+Del`
  (powermenu), wallpaper picker re-themes bar + terminal + lock screen, `git status`
  reflects disk, no dangling symlinks.

## Out of scope
- Renaming wayle's own state dir (wayle controls it).
- Any change to nvim, the wayle bar layout, or the matugen template token set.
