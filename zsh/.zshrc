# XDG base dirs (mostly set by systemd user manager; belt-and-braces for
# plain ttys where the user runs zsh without logging in via UWSM).
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# PATH — ensure ~/.local/bin wins over /usr/bin (user-local binaries/scripts).
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# History — keep it unless it actively annoys.
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=10000
SAVEHIST=10000
mkdir -p "${HISTFILE:h}"
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# Key bindings — pin the emacs keymap explicitly. Otherwise zsh picks the
# default keymap from $EDITOR/$VISUAL: since those are now "nvim" (contains
# "vi"), zle would default to vi-insert mode, where Ctrl+R is `redisplay`
# instead of reverse history search. `bindkey -e` keeps emacs line editing.
bindkey -e

# Completion.
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Starship prompt — config tracked in my-dots (~/.config/starship.toml → ~/my-dots/starship.toml).
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# OSC 133 prompt markers — lets the terminal jump between prompts (kitty also
# provides this via its native shell integration; harmless to set explicitly).
autoload -Uz add-zsh-hook
_osc133_prompt_mark() { print -Pn '\e]133;A\e\\' }
add-zsh-hook precmd _osc133_prompt_mark

# Better ls — icons + dirs first.
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --group-directories-first -1'
fi

# Interactive greeting.
if [[ -o interactive ]]; then
    printf '\e[38;5;16m'
    printf '\e[0m'
    command -v fastfetch >/dev/null 2>&1 && fastfetch --key-padding-left 5
fi
