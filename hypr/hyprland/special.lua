-- Special workspaces (scratchpads). wstoggle.sh spawns the app on first use and
-- toggles the workspace after that.

local v = require("hyprland/variables")

local WSTOGGLE = "~/.config/hypr/scripts/wstoggle.sh"

-- files (user override): yazi in kitty, Super+E
hl.bind("SUPER + E", hl.dsp.exec_cmd(WSTOGGLE .. " files yazi kitty --class yazi --title yazi yazi"))
-- communication: slack, Super+D
hl.bind("SUPER + D", hl.dsp.exec_cmd(WSTOGGLE .. " communication slack slack"))
-- music: spotify-qt, Super+M
hl.bind("SUPER + M", hl.dsp.exec_cmd(WSTOGGLE .. " music spotify-qt spotify-qt"))
-- sysmon: btop in kitty, Ctrl+Shift+Escape
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd(WSTOGGLE .. " sysmon btop kitty --class btop --title btop btop"))
-- generic scratch toggle, Super+S
hl.bind(v.keys.toggleSpecialWs, hl.dsp.workspace.toggle_special("special"))
