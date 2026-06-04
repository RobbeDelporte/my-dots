local bind = require("keymap.bind")
local map_cr = bind.map_cr

local mappings = {
	plugins = {
		-- Plugin: MarkdownPreview
		["n|<F12>"] = map_cr("MarkdownPreviewToggle"):with_noremap():with_silent():with_desc("tool: Preview markdown"),
	},
}

bind.nvim_load_mapping(mappings.plugins)
