-- Window / workspace / layer rules.
--
-- ORDER IS LOAD-BEARING: rules are evaluated top to bottom and the last match
-- wins. Deliberately every rule here is ANONYMOUS (no `name` field) — Hyprland
-- evaluates *all named rules first*, then all anonymous ones, so naming only
-- some of these would silently reorder them against the rest. Add a name only
-- if you also want the handle for :set_enabled(), and only once you've checked
-- it doesn't need to lose to a rule below it.
--
-- Regexes are written as [[long strings]] so backslashes stay literal: "\." is
-- not a valid Lua escape sequence and would be a syntax error.

local v = require("hyprland/variables")

-- float + fixed size + centered, the shape half the rules below want
local function floating_centered(match, size)
    hl.window_rule({ match = match, float = true, size = size, center = true })
end

-- ── User window rules ──
floating_centered({ class = [[xdg-desktop-portal-(gtk|gnome|kde|hyprland)]] }, { 1000, 700 })

-- GNOME Files (Nautilus) — floating, like Thunar was
hl.window_rule({ match = { class = [[org\.gnome\.Nautilus]] }, float = true, size = { 1200, 800 } })

hl.window_rule({ match = { class = "anki-popup" }, float = true, size = { 620, 540 }, center = true, pin = true })

-- ######## Window rules (ported from fork) ########
hl.window_rule({ match = { fullscreen = false }, opacity = v.windowOpacity .. " override" })

-- native transparency or we want them opaque
hl.window_rule({ match = { class = [[kitty|swayimg|com\.gabm\.satty]] }, opaque = true })
-- Center all floating windows (not xwayland cause popups)
hl.window_rule({ match = { float = true, xwayland = false }, center = true })

-- Float
hl.window_rule({ match = { class = "guifetch" }, float = true }) -- FlafyDev/guifetch
hl.window_rule({ match = { class = "yad" }, float = true })
hl.window_rule({ match = { class = "zenity" }, float = true })
hl.window_rule({ match = { class = "wev" }, float = true })
hl.window_rule({ match = { class = [[org\.gnome\.FileRoller]] }, float = true })
hl.window_rule({ match = { class = "file-roller" }, float = true })
hl.window_rule({ match = { class = "blueman-manager" }, float = true })
hl.window_rule({ match = { class = [[com\.github\.GradienceTeam\.Gradience]] }, float = true })
hl.window_rule({ match = { class = "feh" }, float = true })
hl.window_rule({ match = { class = "swayimg" }, float = true })
hl.window_rule({ match = { class = [[com\.gabm\.satty]] }, float = true, center = true })
hl.window_rule({ match = { class = "system-config-printer" }, float = true })

-- Float, resize and center
floating_centered({ class = "kitty", title = "nmtui" }, { "monitor_w*0.6", "monitor_h*0.7" })
floating_centered({ class = [[org\.gnome\.Settings]] }, { "monitor_w*0.7", "monitor_h*0.8" })
floating_centered({ class = [[org\.pulseaudio\.pavucontrol|yad-icon-browser]] }, { "monitor_w*0.6", "monitor_h*0.7" })
floating_centered({ class = "nwg-look" }, { "monitor_w*0.5", "monitor_h*0.6" })

-- Special workspaces
hl.window_rule({ match = { class = "btop" }, workspace = "special:sysmon" })
hl.window_rule({ match = { class = "slack" }, workspace = "special:communication" })
hl.window_rule({ match = { class = "spotify-qt" }, workspace = "special:music" })

-- Dialogs
hl.window_rule({ match = { title = [[(Select|Open)( a)? (File|Folder)(s)?]] }, float = true })
hl.window_rule({ match = { title = [[File (Operation|Upload)( Progress)?]] }, float = true })
hl.window_rule({ match = { title = [[.* Properties]] }, float = true })
hl.window_rule({ match = { title = "Export Image as PNG" }, float = true })
hl.window_rule({ match = { title = "GIMP Crash Debug" }, float = true })
hl.window_rule({ match = { title = "Save As" }, float = true })
hl.window_rule({ match = { title = "Library" }, float = true })

-- Picture in picture (resize and move done via script)
-- NB: the y expression uses window_w, not window_h — a faithful port of the old
-- `move 100%-w-2% 100%-w-3%`, where the second `w` was almost certainly meant to
-- be `h`. Left as-is so this migration changes no behaviour; fix separately.
hl.window_rule({
    match = { title = [[Picture(-| )in(-| )[Pp]icture]] },
    -- Initial move so window doesn't shoot across the screen from the center
    move  = { "monitor_w-window_w-(monitor_w*0.02)", "monitor_h-window_w-(monitor_h*0.03)" },
    keep_aspect_ratio = true,
    float = true,
    pin   = true,
})

-- Creative software
hl.window_rule({ match = { class = [[krita|gimp|inkscape|darktable|resolve|kdenlive|shotcut|blender|godot]] }, opaque = true })

-- Ueberzugpp
hl.window_rule({ match = { class = [[^(ueberzugpp_.*)$]] }, float = true, no_initial_focus = true })

-- Steam
hl.window_rule({ match = { class = "steam" }, rounding = 10 })
hl.window_rule({ match = { class = "steam", title = "Friends List" }, float = true })

-- Games (Steam, Lutris/Wine, Gamescope)
hl.window_rule({
    match = { class = [[(steam_app_(default|[0-9]+))|gamescope]] },
    opaque       = true,
    immediate    = true,   -- Allow tearing for games
    idle_inhibit = "always", -- Always idle inhibit when playing a game
})

-- Minecraft launcher consoles
hl.window_rule({ match = { class = "com-atlauncher-App", title = "ATLauncher Console" }, float = true })
hl.window_rule({ match = { class = "PandoraLauncher", title = "Minecraft Game Output" }, float = true })

-- Autodesk Fusion 360
hl.window_rule({ match = { class = [[fusion360\.exe]], title = [[Fusion360|(Marking Menu)]] }, no_blur = true })

-- Ugh xwayland popups
hl.window_rule({
    match = { xwayland = true, title = [[win[0-9]+]] },
    no_dim    = true,
    no_shadow = true,
    rounding  = 10,
})

-- ######## Workspace rules ########
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = v.singleWindowGapsOut })
hl.workspace_rule({ workspace = "f[1]s[false]",   gaps_out = v.singleWindowGapsOut })

-- ######## Layer rules ########
hl.layer_rule({ match = { namespace = "hyprpicker" }, animation = "fade" }) -- Colour picker out animation
hl.layer_rule({ match = { namespace = "selection" },  animation = "fade" }) -- slurp
hl.layer_rule({ match = { namespace = "wayfreeze" },  animation = "fade" })

-- Rofi
hl.layer_rule({ match = { namespace = "rofi" }, animation = "popin 80%", blur = true })

-- Desktop wallpaper clock (eww). eww 0.5.0 has no per-window namespace, so it
-- uses the default "gtk-layer-shell" -- currently the only surface with it.
-- Pop in instead of the default layer slide/fade when it (re)opens.
hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, animation = "popin 80%" })
