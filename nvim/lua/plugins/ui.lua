-- Editor chrome: the tab strip and the breadcrumb bar, both shaped to read like
-- VSCode. Kept out of custom.lua because that file is about behaviour (pickers,
-- LSP, sidebar) while this one is purely how the frame looks.
return {
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      local c = require("vscode.colors").get_colors()
      -- Tokens the theme palette lacks; shared with the group_overrides in
      -- custom.lua. Everything else comes from the theme, so the strip tracks it.
      local t = require("util.vscode_ui")
      local inactive_fg, accent, active_fg = t.inactive_fg, t.accent, t.active_fg

      local o = opts.options
      -- VSCode keeps the strip up from the first open file; LazyVim hides it
      -- until there are two buffers, which makes it jump into existence.
      o.always_show_bufferline = true
      -- Flat rectangles butted together — no slants, slopes or rounding.
      o.separator_style = "thin"
      -- VSCode puts the accent on TOP of the active tab. A tabline is one row
      -- and Neovim has no overline attribute, so the line goes under the label:
      -- same signal, mirrored. The background match below is the other half.
      o.indicator = { style = "underline" }
      o.show_buffer_close_icons = true
      o.show_close_icon = false -- VSCode has no global close on the strip
      o.buffer_close_icon = "✕"
      o.modified_icon = "●"
      -- Reveal the ✕ under the pointer, like VSCode's hover affordance.
      o.hover = { enabled = true, delay = 120, reveal = { "close" } }
      -- VSCode recolours the tab LABEL on a diagnostic and never shows a count
      -- badge; the highlight groups still fire, only the badge text is dropped.
      o.diagnostics_indicator = function()
        return ""
      end

      opts.highlights = {
        -- Active tab sits at the editor background, exactly as in VSCode, so the
        -- tab reads as continuous with the pane below it.
        buffer_selected = { fg = active_fg, bg = c.vscTabCurrent, bold = false, italic = false },
        background = { fg = inactive_fg, bg = c.vscTabOther },
        buffer_visible = { fg = inactive_fg, bg = c.vscTabOther },
        indicator_selected = { fg = accent, bg = c.vscTabCurrent },
        indicator_visible = { fg = c.vscTabOther, bg = c.vscTabOther },
        -- Separators in the bar colour, which reads as the 1px gap VSCode draws.
        separator = { fg = c.vscTabOutside, bg = c.vscTabOther },
        separator_visible = { fg = c.vscTabOutside, bg = c.vscTabOther },
        separator_selected = { fg = c.vscTabOutside, bg = c.vscTabCurrent },
        modified = { fg = inactive_fg, bg = c.vscTabOther },
        modified_visible = { fg = inactive_fg, bg = c.vscTabOther },
        modified_selected = { fg = active_fg, bg = c.vscTabCurrent },
        close_button = { fg = inactive_fg, bg = c.vscTabOther },
        close_button_visible = { fg = inactive_fg, bg = c.vscTabOther },
        close_button_selected = { fg = active_fg, bg = c.vscTabCurrent },
        duplicate = { fg = inactive_fg, bg = c.vscTabOther, italic = false },
        duplicate_visible = { fg = inactive_fg, bg = c.vscTabOther, italic = false },
        duplicate_selected = { fg = active_fg, bg = c.vscTabCurrent, italic = false },
      }

      -- The accent line is drawn as an underline, so its colour is each group's
      -- `sp` — and bufferline defaults that to the selected tab's own background,
      -- which renders it invisible. Every group that can appear on the active tab
      -- needs the accent stamped on it, otherwise the line breaks wherever one of
      -- them is used (a modified dot, a diagnostic label, the close button).
      for _, group in ipairs({
        "tab_selected",
        "close_button_selected",
        "buffer_selected",
        "numbers_selected",
        "diagnostic_selected",
        "hint_selected",
        "hint_diagnostic_selected",
        "info_selected",
        "info_diagnostic_selected",
        "warning_selected",
        "warning_diagnostic_selected",
        "error_selected",
        "error_diagnostic_selected",
        "modified_selected",
        "duplicate_selected",
        "separator_selected",
        "tab_separator_selected",
        "indicator_selected",
        "pick_selected",
      }) do
        local hl = opts.highlights[group] or {}
        hl.underline = true
        hl.sp = accent
        opts.highlights[group] = hl
      end

      return opts
    end,
  },

  -- Breadcrumbs. dropbar over the alternatives because its segments are
  -- clickable and open a dropdown of siblings/symbols — VSCode's breadcrumbs
  -- are an interaction, not just a label.
  {
    "Bekaboo/dropbar.nvim",
    event = "LazyFile",
    keys = {
      { "<leader>cb", function() require("dropbar.api").pick() end, desc = "Breadcrumbs: Pick" },
    },
    opts = {
      icons = {
        ui = {
          bar = { separator = " › " }, -- VSCode's separator, not a nerd-font chevron
        },
      },
    },
  },
}
