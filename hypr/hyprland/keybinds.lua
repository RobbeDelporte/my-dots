-- Keybinds.
--
-- hyprlang bind-flag suffixes map onto the opts table:
--   bind → {}            bindr  → { release = true }
--   binde → { repeating = true }
--   bindl → { locked = true }    bindle → { locked = true, repeating = true }
--   bindm → { mouse = true }

local v = require("hyprland/variables")

local SCRIPTS = "~/.config/hypr/scripts"

-- Go to workspace via ws.sh: collapses any open special workspace first.
local function ws(arg)
    return hl.dsp.exec_cmd(SCRIPTS .. "/ws.sh " .. arg)
end

-- hyprlang's `resizeactive -10% 0` took a percentage of the monitor. The Lua
-- resize dispatcher accepts PIXELS ONLY — a "10%" string is rejected outright
-- ("Expected positions (x & y)") — so the percentage is resolved against the
-- focused monitor at press time instead. m.width/m.height are the physical
-- mode, hence the divide by scale to get logical pixels.
local function monitor_logical_size()
    local m = hl.get_active_monitor()
    if not m then
        return nil
    end
    local scale = m.scale
    if not scale or scale == 0 then
        scale = 1
    end
    return m.width / scale, m.height / scale
end

-- fx/fy are fractions of the monitor, e.g. resize_by(-0.1, 0) == `-10% 0`
local function resize_by(fx, fy)
    return function()
        local w, h = monitor_logical_size()
        if not w then
            return
        end
        hl.dispatch(hl.dsp.window.resize({
            x = math.floor(w * fx),
            y = math.floor(h * fy),
            relative = true,
        }))
    end
end

-- absolute counterpart of the above (hyprlang's `resizeactive exact 55% 70%`).
-- Acts immediately rather than returning a closure — its one caller already sits
-- inside a bind function.
local function resize_exact(fx, fy)
    local w, h = monitor_logical_size()
    if not w then
        return
    end
    hl.dispatch(hl.dsp.window.resize({ x = math.floor(w * fx), y = math.floor(h * fy) }))
end

-- ── Launcher ──
hl.bind("SUPER + Space", hl.dsp.exec_cmd("pkill -x rofi || rofi -show drun"))
hl.bind("SUPER + Tab", hl.dsp.exec_cmd(SCRIPTS .. "/window-switcher.sh"))       -- window switcher (hyprctl + rofi)
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd(SCRIPTS .. "/wallpicker.sh"))      -- wallpaper picker (rofi + thumbnails)
-- hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd("~/.config/eww/place.sh"))       -- drag-to-place the wallpaper clock (DISABLED with the clock)

-- ── Session / shell control ──
hl.bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd("wayle panel restart"), { release = true })

-- ── Brightness ──
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- ── Media ──
hl.bind("CTRL + SUPER + Space", hl.dsp.exec_cmd("playerctl --player=spotifyd play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl --player=spotifyd play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl --player=spotifyd play-pause"), { locked = true })
hl.bind("CTRL + SUPER + Equal", hl.dsp.exec_cmd("playerctl --player=spotifyd next"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl --player=spotifyd next"), { locked = true })
hl.bind("CTRL + SUPER + Minus", hl.dsp.exec_cmd("playerctl --player=spotifyd previous"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl --player=spotifyd previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl --player=spotifyd stop"), { locked = true })

-- ── Workspaces ──
-- Ten near-identical bind pairs under hyprlang; one loop here. Key 0 → ws 10.
for i = 1, 10 do
    local key = i % 10
    hl.bind(v.keys.goToWs .. " + " .. key, ws(i))
    hl.bind(v.keys.moveWinToWs .. " + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + mouse_down", ws("e-1"))
hl.bind("SUPER + mouse_up", ws("e+1"))
hl.bind(v.keys.prevWs, ws("e-1"), { repeating = true })
hl.bind(v.keys.nextWs, ws("e+1"), { repeating = true })
hl.bind("SUPER + Page_Up", ws("e-1"), { repeating = true })
hl.bind("SUPER + Page_Down", ws("e+1"), { repeating = true })

-- ── Move window to workspace ──
hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + ALT + mouse_up", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("CTRL + SUPER + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }), { repeating = true })
hl.bind("CTRL + SUPER + SHIFT + left", hl.dsp.window.move({ workspace = "-1" }), { repeating = true })
hl.bind("CTRL + SUPER + SHIFT + up", hl.dsp.window.move({ workspace = "special:special" }))
hl.bind("CTRL + SUPER + SHIFT + down", hl.dsp.window.move({ workspace = "e+0" }))
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special:special" }))

-- ── Window groups ──
hl.bind(v.keys.windowGroupCycleNext, hl.dsp.window.cycle_next(), { repeating = true })
hl.bind(v.keys.windowGroupCyclePrev, hl.dsp.window.cycle_next({ next = false }), { repeating = true })
hl.bind("CTRL + ALT + Tab", hl.dsp.group.next(), { repeating = true })
hl.bind("CTRL + SHIFT + ALT + Tab", hl.dsp.group.prev(), { repeating = true })
hl.bind(v.keys.toggleGroup, hl.dsp.group.toggle())
hl.bind(v.keys.ungroup, hl.dsp.window.move({ out_of_group = true }))
hl.bind("SUPER + SHIFT + Comma", hl.dsp.group.lock_active({ action = "toggle" }))

-- ── Window actions ──
hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

hl.bind("SUPER + Minus", resize_by(-0.1, 0), { repeating = true })
hl.bind("SUPER + Equal", resize_by(0.1, 0), { repeating = true })
hl.bind("SUPER + SHIFT + Minus", resize_by(0, -0.1), { repeating = true })
hl.bind("SUPER + SHIFT + Equal", resize_by(0, 0.1), { repeating = true })
hl.bind("SUPER + ALT + left", resize_by(-0.1, 0), { repeating = true })
hl.bind("SUPER + ALT + right", resize_by(0.1, 0), { repeating = true })
hl.bind("SUPER + ALT + up", resize_by(0, -0.1), { repeating = true })
hl.bind("SUPER + ALT + down", resize_by(0, 0.1), { repeating = true })

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(v.keys.moveWindow, hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(v.keys.resizeWindow, hl.dsp.window.resize(), { mouse = true })

hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.center())
-- Two dispatchers on one key: resize to a fixed fraction, then recentre.
hl.bind("CTRL + SUPER + ALT + Backslash", function()
    resize_exact(0.55, 0.7)
    hl.dispatch(hl.dsp.window.center())
end)

hl.bind(v.keys.pinWindow, hl.dsp.window.pin())
hl.bind(v.keys.windowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(v.keys.windowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(v.keys.toggleWindowFloating, hl.dsp.window.float({ action = "toggle" }))
hl.bind(v.keys.closeWindow, hl.dsp.window.close())

-- ── Lock (hyprlock; hypridle removed → exec the launcher directly) ──
hl.bind("SUPER + Escape", hl.dsp.exec_cmd(SCRIPTS .. "/lock.sh"))
hl.bind("SUPER + L", hl.dsp.exec_cmd(SCRIPTS .. "/lock.sh"))

-- ── Apps ──
hl.bind(v.keys.terminal, hl.dsp.exec_cmd("app2unit -- " .. v.terminal))

-- ── Utilities ──
hl.bind("Print", hl.dsp.exec_cmd(SCRIPTS .. "/screenshot.sh screen"), { locked = true })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(SCRIPTS .. "/screenshot.sh region"))
hl.bind("SUPER + SHIFT + ALT + S", hl.dsp.exec_cmd(SCRIPTS .. "/screenshot.sh window"))
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd(SCRIPTS .. "/record.sh -s"))
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd(SCRIPTS .. "/record.sh"))
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd(SCRIPTS .. "/record.sh -r"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))

-- ── Volume / mic ──
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ " .. v.volumeStep .. "%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. v.volumeStep .. "%-"),
    { locked = true, repeating = true })

-- ── Sleep ──
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend-then-hibernate"), { locked = true })

-- ── Clipboard & emoji ──
hl.bind("SUPER + V", hl.dsp.exec_cmd("pkill -x rofi || cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
hl.bind("SUPER + Period", hl.dsp.exec_cmd("pkill -x rofi || BEMOJI_PICKER_CMD='rofi -dmenu' bemoji"))
hl.bind("CTRL + SHIFT + ALT + V",
    hl.dsp.exec_cmd([[sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"]]),
    { locked = true })
