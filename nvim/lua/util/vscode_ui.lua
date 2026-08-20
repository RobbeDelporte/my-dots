-- VSCode UI tokens that vscode.nvim's palette has no counterpart for.
--
-- One place because two different layers need the same values: theme-owned
-- highlight groups are overridden in the colorscheme spec (plugins/custom.lua,
-- via group_overrides) while plugin-owned ones are set on the plugin
-- (plugins/ui.lua, via bufferline's highlights table). Same colours, two
-- mechanisms — so the colours live here rather than in either of them.
--
-- Values are the literal VSCode theme tokens they are named after.
return {
  accent = "#0078D4", -- tab.activeBorderTop
  inactive_fg = "#8C8C8C", -- tab.inactiveForeground (50% white over #2D2D2D)
  breadcrumb_fg = "#A9A9A9", -- breadcrumb.foreground
  active_fg = "#FFFFFF", -- tab.activeForeground
}
