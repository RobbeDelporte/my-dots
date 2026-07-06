# ~/.zprofile — tracked in ~/my-dots/zsh/.zprofile (symlinked manually into ~; see README + bin/doctor.sh)
#
# No display manager: auto-start a Wayland session via UWSM on TTY1. `uwsm select`
# shows a menu of installed sessions (Hyprland); other TTYs fall through to a
# normal shell. (A graphical greeter may be added back later.)

# Default editor for git, CLI tools, etc. Set before the session exec below.
export EDITOR=nvim
export VISUAL=nvim

if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] && command -v uwsm >/dev/null 2>&1; then
    if uwsm check may-start && uwsm select; then
        exec systemd-cat -t uwsm uwsm start default
    fi
fi
