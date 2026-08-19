-- Special workspaces (scratchpads): reveal the workspace, spawning its app into
-- it on first use.
--
-- This used to shell out to wstoggle.sh, which asked the compositor the same
-- questions over hyprctl + jq. The Lua config can query it directly, so the
-- subprocess — and the shell→Lua quoting it needed once `hyprctl dispatch`
-- started evaluating Lua — is gone.

local v = require("hyprland/variables")

-- Settle time between spawning a window and revealing its workspace, so the
-- window is assigned before the slide-in animation starts.
local SPAWN_SETTLE_MS = 300

-- hl.get_windows({ class = … }) matches exactly and case-sensitively. wstoggle.sh
-- used jq's `test($c; "i")`, so keep that: case-insensitive substring, compared
-- literally rather than as a Lua pattern (the "-" in "spotify-qt" is a pattern
-- quantifier, so a bare :match() would not mean what it looks like).
local function is_running(class)
    local needle = class:lower()
    for _, w in ipairs(hl.get_windows()) do
        if w.class and w.class:lower():find(needle, 1, true) then
            return true
        end
    end
    return false
end

local function scratchpad(name, class, cmd)
    return function()
        local reveal = hl.dsp.workspace.toggle_special(name)
        if is_running(class) then
            hl.dispatch(reveal)
        else
            hl.dispatch(hl.dsp.exec_cmd("[workspace special:" .. name .. " silent] " .. cmd))
            hl.timer(function() hl.dispatch(reveal) end, { timeout = SPAWN_SETTLE_MS, type = "oneshot" })
        end
    end
end

-- files (user override): yazi in kitty, Super+E
hl.bind("SUPER + E", scratchpad("files", "yazi", "kitty --class yazi --title yazi yazi"))
-- communication: slack, Super+D
hl.bind("SUPER + D", scratchpad("communication", "slack", "slack"))
-- music: spotify-qt, Super+M
hl.bind("SUPER + M", scratchpad("music", "spotify-qt", "spotify-qt"))
-- sysmon: btop in kitty, Ctrl+Shift+Escape
hl.bind("CTRL + SHIFT + Escape", scratchpad("sysmon", "btop", "kitty --class btop --title btop btop"))
-- generic scratch toggle, Super+S
hl.bind(v.keys.toggleSpecialWs, hl.dsp.workspace.toggle_special("special"))
