-- User override for Catppuccin, read by modules.utils.load_plugin via
-- `require("user.configs.catppuccin")`.
--
-- We return a FUNCTION (not a table): load_plugin calls it with nvimdots' base
-- opts and uses the returned table directly as the catppuccin.setup() options
-- (see modules/utils/init.lua load_plugin, function branch). We MUST use the
-- function form, not a table: the base config sets `color_overrides = {}`, and
-- nvimdots' tbl_recursive_merge treats an empty table as a list
-- (vim.islist({}) == true) and merges it via list_extend, which drops our
-- string-keyed `mocha` override. The function form skips that merge — we receive
-- the full base opts (every integration + highlight_override preserved) and only
-- set color_overrides on it.
--
-- Palette source: matugen renders ~/my-dots/generated/nvim-colors.lua (raw
-- Material You roles) on every wallpaper/scheme change; we map those roles onto
-- Catppuccin's mocha slots. Accents Material You has no role for
-- (green/yellow/teal/peach/pink/sky/sapphire/rosewater/flamingo) are deliberately
-- left untouched, so they stay at their stock Catppuccin Mocha values — the same
-- curated-static outcome kitty.tmpl gets for green/yellow/cyan.
--
-- If the generated file is absent (fresh clone, before the first matugen run),
-- return the base opts unchanged → stock Catppuccin mocha.
local ok, roles = pcall(dofile, os.getenv("HOME") .. "/my-dots/generated/nvim-colors.lua")

return function(opts)
	if not ok or type(roles) ~= "table" then
		return opts
	end

	opts.color_overrides = {
		mocha = {
			-- Background elevation: darkest → main editor bg
			crust = roles.surface_container_lowest,
			mantle = roles.surface_container_low,
			base = roles.surface,
			-- UI element surfaces
			surface0 = roles.surface_container,
			surface1 = roles.surface_container_high,
			surface2 = roles.surface_container_highest,
			-- Borders / muted
			overlay0 = roles.outline_variant,
			overlay1 = roles.outline,
			overlay2 = roles.on_surface_variant,
			-- Foreground text ramp
			text = roles.on_surface,
			subtext1 = roles.on_surface_variant,
			subtext0 = roles.outline,
			-- Accents driven by matugen (others stay stock mocha)
			blue = roles.primary, -- same as kitty: blue = primary
			mauve = roles.tertiary, -- = kitty's magenta = tertiary
			red = roles.error,
			maroon = roles.error,
			lavender = roles.secondary,
		},
	}

	return opts
end
