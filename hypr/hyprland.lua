-- Self-contained Hyprland config. Order matters: variables (which pull in the
-- resolved colour palette) load before anything that reads them, and rules load
-- in file order because the last matching rule wins.
--
-- require() paths are relative to THIS file, i.e. ~/.config/hypr/. Each require
-- is its own Lua scope — a runtime error in one file aborts that file only.

local v = require("hyprland/variables")
local p = v.palette

require("hyprland/monitors")

-- General / decoration / layout — uses the gaps/blur/rounding values above.
hl.config({
    general = {
        layout = "dwindle",

        allow_tearing = false, -- Allows `immediate` window rule to work

        gaps_workspaces = v.workspaceGaps,
        gaps_in         = v.windowGapsIn,
        gaps_out        = v.windowGapsOut,
        border_size     = v.windowBorderSize,

        col = {
            active_border   = v.activeWindowBorderColour,
            inactive_border = v.inactiveWindowBorderColour,
        },
    },

    dwindle = {
        preserve_split = true,
        smart_split    = false,
        smart_resizing = true,
    },

    decoration = {
        rounding         = v.windowRounding,
        active_opacity   = v.windowOpacity,
        inactive_opacity = v.windowOpacity,

        blur = {
            enabled          = v.blurEnabled,
            xray             = v.blurXray,
            special          = v.blurSpecialWs,
            ignore_opacity   = true, -- Allows opacity blurring
            new_optimizations = true,
            popups           = v.blurPopups,
            input_methods    = v.blurInputMethods,
            size             = v.blurSize,
            passes           = v.blurPasses,
        },

        shadow = {
            enabled      = v.shadowEnabled,
            range        = v.shadowRange,
            render_power = v.shadowRenderPower,
            color        = v.shadowColour,
        },
    },

    misc = {
        vrr = 1,

        animate_manual_resizes        = false,
        animate_mouse_windowdragging  = false,

        disable_hyprland_logo   = true,
        force_default_wallpaper = 0,

        on_focus_under_fullscreen  = 2,
        allow_session_lock_restore = true,
        middle_click_paste         = false,
        focus_on_activate          = true,
        session_lock_xray          = true,

        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,

        background_color = "rgb(" .. p.surfaceContainer .. ")",
    },

    group = {
        col = {
            border_active          = v.activeWindowBorderColour,
            border_inactive        = v.inactiveWindowBorderColour,
            border_locked_active   = v.activeWindowBorderColour,
            border_locked_inactive = v.inactiveWindowBorderColour,
        },

        groupbar = {
            font_family               = "JetBrains Mono NF",
            font_size                 = 15,
            gradients                 = true,
            gradient_round_only_edges = false,
            gradient_rounding         = 5,
            height                    = 25,
            indicator_height          = 0,
            gaps_in                   = 3,
            gaps_out                  = 3,

            text_color = "rgb(" .. p.onPrimary .. ")",
            col = {
                active          = "rgba(" .. p.primary .. "d4)",
                inactive        = "rgba(" .. p.outlineVariant .. "d4)",
                locked_active   = "rgba(" .. p.primary .. "d4)",
                locked_inactive = "rgba(" .. p.secondary .. "d4)",
            },
        },
    },

    debug = {
        error_position = 1,
    },
})

hl.workspace_rule({ workspace = "special:special", gaps_out = v.workspaceGaps })

-- Environment variables
hl.env("QT_QPA_PLATFORMTHEME", "qtengine")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("XCURSOR_THEME", v.cursorTheme)
hl.env("XCURSOR_SIZE", tostring(v.cursorSize))
hl.env("HYPRCURSOR_THEME", v.cursorTheme)
hl.env("HYPRCURSOR_SIZE", tostring(v.cursorSize))
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland,x11,windows")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

require("hyprland/input")
require("hyprland/animations")
require("hyprland/rules")
require("hyprland/keybinds")
require("hyprland/special")
require("hyprland/execs")
