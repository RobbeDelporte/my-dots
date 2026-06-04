# ~/.zprofile — tracked in ~/my-dots/zsh/.zprofile (symlinked manually into ~; see README + bin/doctor.sh)
#
# Auto-start a Hyprland session via UWSM on TTY1 (matches caelestia's upstream
# recommendation). Other TTYs fall through to a normal shell.

# Default editor for git, CLI tools, etc. Set before the session exec below so
# the whole Hyprland session (and every terminal it spawns) inherits it.
export EDITOR=nvim
export VISUAL=nvim

if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] && command -v uwsm >/dev/null 2>&1; then
    if uwsm check may-start && uwsm select; then
        exec systemd-cat -t uwsm uwsm start default
    fi
fi
