-- Tunables shared across the config. Replaces hyprlang's `$var` globals, which
-- were plain text substitution visible to every sourced file. Lua require()
-- scopes are isolated by design, so this is a module: consumers do
--     local v = require("hyprland/variables")
-- and read fields off the returned table.

local p = require("palette")

return {
    -- Palette re-export, so consumers that need raw colour roles don't have to
    -- require("palette") a second time.
    palette = p,

    -- ### Apps ###
    terminal = "kitty",
    browser  = "zen-browser",

    -- ### Touchpad ###
    touchpadDisableTyping = true,
    touchpadScrollFactor  = 3,
    workspaceSwipeFingers = 4,
    gestureFingers        = 3,
    gestureFingersMore    = 4,

    -- ### Blur ###
    blurEnabled      = true,
    blurSpecialWs    = true,
    blurPopups       = false,
    blurInputMethods = true,
    blurSize         = 8,
    blurPasses       = 2,
    blurXray         = false,

    -- ### Shadow ###
    shadowEnabled     = false,
    shadowRange       = 20,
    shadowRenderPower = 3,
    shadowColour      = "rgba(" .. p.surface .. "d4)",

    -- ### Gaps ###
    workspaceGaps       = 4,
    windowGapsIn        = 2,
    windowGapsOut       = 4,
    singleWindowGapsOut = 2,

    -- ### Window styling ###
    windowOpacity              = 1.0,
    windowRounding             = 6,
    windowBorderSize           = 1,
    activeWindowBorderColour   = "rgba(" .. p.primary .. "e6)",
    inactiveWindowBorderColour = "rgba(" .. p.onSurfaceVariant .. "11)",

    -- ### Misc ###
    volumeStep  = 10,
    cursorTheme = "sweet-cursors",
    cursorSize  = 24,

    -- ### Keybinds ###
    -- Two shapes here: bare modifier prefixes (concatenated with a key at the
    -- bind site, e.g. keys.goToWs .. " + 1") and complete bind strings.
    keys = {
        -- prefixes
        goToWs      = "SUPER",
        moveWinToWs = "SUPER + ALT",

        -- complete binds
        nextWs                   = "CTRL + SUPER + right",
        prevWs                   = "CTRL + SUPER + left",
        toggleSpecialWs          = "SUPER + S",
        windowGroupCycleNext     = "ALT + Tab",
        windowGroupCyclePrev     = "SHIFT + ALT + Tab",
        ungroup                  = "SUPER + U",
        toggleGroup              = "SUPER + Comma",
        moveWindow               = "SUPER + Z",
        resizeWindow             = "SUPER + X",
        pinWindow                = "SUPER + P",
        windowFullscreen         = "SUPER + F",
        windowBorderedFullscreen = "SUPER + ALT + F",
        toggleWindowFloating     = "SUPER + ALT + Space",
        closeWindow              = "SUPER + Q",
        terminal                 = "SUPER + T",
    },
}
