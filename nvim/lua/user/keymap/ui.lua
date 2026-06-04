local bind = require("keymap.bind")
local map_callback = bind.map_callback

-- Proportional mouse-wheel scrolling for high-resolution wheels.
--
-- A hi-res wheel (e.g. Logitech MX Master) floods nvim with ~100 scroll events
-- per notch, and nvim scrolls at least one whole line per event -- so the view
-- overshoots and lags behind you. Smooth-scroll plugins (neoscroll, etc.) make
-- this WORSE: the flood makes them accumulate a huge animation target, which is
-- why they feel slow and keep scrolling after you stop.
--
-- This maps total wheel rotation to lines via a fractional accumulator instead:
--   * no animation  -> stops the instant you stop (no trailing)
--   * proportional   -> more rotation = more lines, like a normal mouse
--   * no eaten nudges -> the first event of each gesture always moves a line
-- It is nvim-only; your terminal and browser scrolling are untouched.
--
-- SENSITIVITY is the ONLY knob you ever need to touch: lines per wheel event.
-- Edit the number below, then restart nvim (no commands to paste).
--   too slow?  raise it  (try 3, then 5)
--   too fast?  lower it  (try 1, then 0.5)
local SENSITIVITY = 1.5
local NEW_GESTURE_MS = 150

local acc, last_t, last_dir = 0, 0, nil

local function wheel(ctrl)
	return function()
		local now = vim.loop.now()
		if ctrl ~= last_dir or now - last_t > NEW_GESTURE_MS then
			-- new gesture (or direction change): guarantee one immediate step
			acc = 1
			last_dir = ctrl
		end
		last_t = now
		acc = acc + SENSITIVITY
		local lines = math.floor(acc)
		if lines >= 1 then
			acc = acc - lines
			vim.api.nvim_feedkeys(
				vim.api.nvim_replace_termcodes(lines .. ctrl, true, false, true),
				"nx",
				false
			)
		end
	end
end

return {
	["nv|<ScrollWheelUp>"] = map_callback(wheel("<C-y>"))
		:with_silent()
		:with_noremap()
		:with_desc("scroll: Wheel up"),
	["nv|<ScrollWheelDown>"] = map_callback(wheel("<C-e>"))
		:with_silent()
		:with_noremap()
		:with_desc("scroll: Wheel down"),
}
