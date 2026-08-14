-- Monitor layout. One hl.monitor() per rule; output = "" is the catch-all that
-- matches any output not named by a more specific rule.

-- Laptop panel
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.2 })

-- Catch-all for unknown externals
hl.monitor({ output = "", mode = "2560x1440@74.78Hz", position = "auto-right", scale = 1, vrr = 0 })

hl.monitor({ output = "DP-1", mode = "3440x1440@59.97Hz", position = "auto-right", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1, vrr = 0 })
