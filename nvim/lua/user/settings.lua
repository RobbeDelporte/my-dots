-- Please check `lua/core/settings.lua` to view the full list of configurable settings
local settings = {}

-- Examples
settings["use_ssh"] = true

settings["colorscheme"] = "catppuccin"

-- Transparent background: let nvim show the (opaque, Material-themed) terminal
-- surface through. Catppuccin's highlight_overrides already route floats/Pmenu/
-- Trouble to `cp.none` when this is on, so it composes with the matugen palette.
settings["transparent_background"] = true

return settings
