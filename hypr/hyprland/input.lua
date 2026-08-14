-- Input, cursor, per-device tuning and trackpad gestures.

local v = require("hyprland/variables")

hl.config({
    input = {
        kb_layout          = "us",
        numlock_by_default = false,
        repeat_delay       = 250,
        repeat_rate        = 35,

        focus_on_close = 1,

        sensitivity    = -0.35,
        accel_profile  = "flat",
        force_no_accel = false,
        follow_mouse   = 2,

        touchpad = {
            natural_scroll       = true,
            disable_while_typing = v.touchpadDisableTyping,
            scroll_factor        = v.touchpadScrollFactor,
        },
    },

    binds = {
        scroll_event_delay = 0,
    },

    cursor = {
        hotspot_padding = 1,
    },

    gestures = {
        -- NB: Hyprland 0.55 dropped `workspace_swipe`/`workspace_swipe_fingers`
        -- from this block — the swipe is bound via hl.gesture() below. Only the
        -- swipe TUNING options remain valid here.
        workspace_swipe_distance                 = 700,
        workspace_swipe_cancel_ratio             = 0.15,
        workspace_swipe_min_speed_to_force       = 5,
        workspace_swipe_direction_lock           = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new               = true,
    },
})

-- Per-device touchpad accel — NB: sensitivity/accel_profile are NOT valid inside
-- input.touchpad{} (Hyprland has no such config keys); they only work at input{}
-- top level (would override the mouse) or in a per-device block like this one.
hl.device({
    name          = "uniw0001:00-093a:0255-touchpad",
    sensitivity   = -0.1,
    accel_profile = "adaptive",
})

hl.gesture({ fingers = v.workspaceSwipeFingers, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = v.gestureFingers, direction = "up", action = "special", workspace_name = "special" })

-- Was `dispatcher, exec, hyprctl dispatch togglespecialworkspace special` under
-- hyprlang — a shell + IPC round-trip just to reach a dispatcher. Lua calls it
-- directly.
hl.gesture({
    fingers   = v.gestureFingers,
    direction = "down",
    action    = function()
        hl.dispatch(hl.dsp.workspace.toggle_special("special"))
    end,
})

hl.gesture({
    fingers   = v.gestureFingersMore,
    direction = "down",
    action    = function()
        hl.dispatch(hl.dsp.exec_cmd("systemctl suspend-then-hibernate"))
    end,
})
