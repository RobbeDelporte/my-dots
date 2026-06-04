# yazi cheatsheet

> Press `~` inside yazi for the *full* keymap reference at any time.
> This file covers the binds you'll actually use day-to-day.

## Navigation

- `h` `j` `k` `l` — left / down / up / right
- `<Enter>` / `l` — **smart-enter**: cd into a dir OR open a file
- `gg` / `G` — jump to top / bottom
- `H` `L` — back / forward in history
- `cd` then type a path — change directory directly

## Selection

- `<Space>` — toggle select on file
- `v` — visual select mode
- `<Esc>` — clear selection / close popup

## Operations

- `y` — yank (copy)
- `x` — cut
- `p` — paste (force overwrite: `P`)
- `d` — move to trash (force delete: `D`)
- `a` — create file (end with `/` to create a dir)
- `r` — rename
- `;` — run a shell command (use `:` for blocking commands)

## Search / Find

- `/` — find forward
- `?` — find backward
- `n` / `N` — next / previous match
- `s` — search with `fd` (filter results inline)

## Tabs

- `t` — new tab
- `1`–`9` — jump to tab N
- `[` / `]` — prev / next tab
- `<Tab>` — switch to other side
- `T` — close current tab

## Tasks / Misc

- `~` — open help (full keymap reference)
- `w` — show tasks panel
- `m` — change linemode (size / mtime / `git` / `git-files` / permissions)
- `<Esc>` — close any popup

## Installed plugins

- **smart-enter** — `<Enter>` / `l` enters dirs *and* opens files with one key.
- **git** — shows git status indicators in the file listing. Try `m` → `git`.
- **full-border** — rounded borders on every pane.
- **glow** — `<Enter>` on a `*.md` file (like this one) renders inline.
