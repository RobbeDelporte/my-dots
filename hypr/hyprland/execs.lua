-- Autostart. hyprlang's `exec-once =` becomes a hyprland.start event handler:
-- the callback fires once when the compositor comes up, and hl.exec_cmd() runs
-- each command through sh, same as before.

local v = require("hyprland/variables")

hl.on("hyprland.start", function()
    -- Shell
    hl.exec_cmd("uwsm app -- wayle shell")

    -- Desktop wallpaper clock (eww) — DISABLED. launch.sh waits for awww, opens
    -- one window per output, and places them per eww/positions.conf. Re-enable by
    -- uncommenting this AND matugen's [templates.eww] post_hook (which reopens the
    -- clock on every theme render) and the Super+Ctrl+W place bind in keybinds.lua.
    -- hl.exec_cmd("uwsm app -- ~/.config/eww/launch.sh")

    -- Idle / lock: hypridle removed (manual-lock-only).

    -- Clipboard history watchers
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- ydotool daemon (alternate-paste bind)
    hl.exec_cmd("uwsm app -- ydotoold")

    -- Keyring and auth
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Auto delete trash 30 days old
    hl.exec_cmd("trash-empty 30")

    -- Cursors
    hl.exec_cmd("hyprctl setcursor " .. v.cursorTheme .. " " .. v.cursorSize)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme '" .. v.cursorTheme .. "'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size " .. v.cursorSize)

    -- Location provider and night light
    hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")
    hl.exec_cmd("sleep 1 && gammastep")

    -- Forward bluetooth media commands to MPRIS
    hl.exec_cmd("mpris-proxy")
end)
