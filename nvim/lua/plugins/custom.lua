return {
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,

    config = function()
      local c = require("vscode.colors").get_colors()
      local t = require("util.vscode_ui")

      require("vscode").setup({
        italic_comments = true,
        underline_links = true,
        terminal_colors = true,
        group_overrides = {
          -- indent guides: a notch lighter than the editor background (#1f1f1f).
          -- VSCode's own guide colour is #404040, which reads heavier than this.
          SnacksIndent = { fg = "#2d2d2d" },
          -- Breadcrumb bar (dropbar renders into the winbar). The theme ships
          -- WinBar bold in the editor foreground; VSCode's breadcrumbs are quiet
          -- and unemphasised, sitting at the editor background.
          WinBar = { fg = t.breadcrumb_fg, bg = c.vscBack, bold = false },
          WinBarNC = { fg = t.breadcrumb_fg, bg = c.vscBack, bold = false },
          -- bufferline paints the active tab's LEADING CELL with this group, and
          -- the theme's own value (dark fill, no underline) leaves a gap at the
          -- left end of the accent line. It has to be fixed here rather than in
          -- bufferline's highlights table, which loses to the theme for the two
          -- BufferLine groups the theme defines itself.
          BufferLineIndicatorSelected = { fg = t.accent, bg = c.vscTabCurrent, underline = true, sp = t.accent },
        },
      })
      vim.cmd.colorscheme("vscode")
    end,
  },
  {
    "snacks.nvim",
    keys = {
      -- Sidebar: one slot, three tabs. H/L walk the strip from inside the pane.
      { "<leader>e", function() require("util.sidebar").show("explorer") end, desc = "Sidebar: Explorer" },
      { "<leader>gs", function() require("util.sidebar").show("changes") end, desc = "Sidebar: Git Changes" },
      { "<leader>gr", function() require("util.sidebar").show("pr") end, desc = "Sidebar: PR Diff" },
      { "<leader>E", function() require("util.sidebar").toggle() end, desc = "Sidebar: Toggle" },
      -- full-screen git status, displaced from <leader>gs by the Changes tab
      { "<leader>gc", function() Snacks.picker.git_status() end, desc = "Git Status (full screen)" },
    },
    opts = {
      indent = {
        animate = { enabled = false },
        indent = { char = "▏" },
        scope = { char = "▏" },
      },
      dashboard = {
        preset = {
          pick = function(cmd, opts)
            return LazyVim.pick(cmd, opts)()
          end,
          header = [[
 _______             ____   ____.__         
 \      \   ____  ___\   \ /   /|__| _____  
 /   |   \_/ __ \/  _ \   Y   / |  |/     \ 
/    |    \  ___(  <_> )     /  |  |  Y Y  \
\____|__  /\___  >____/ \___/   |__|__|_|  /
        \/     \/                        \/ 
        ]],

          -- stylua: ignore
          ---@type snacks.dashboard.Item[]
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        -- Restating snacks' defaults (header / keys / startup) because defining
        -- `sections` replaces the default list rather than extending it.
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          -- The title only renders when the section produced rows, so no saved
          -- sessions means no empty "Sessions" heading.
          {
            icon = " ",
            title = "Sessions",
            indent = 2,
            padding = 1,
            require("util.sessions").section({ limit = 5 }),
          },
          { section = "startup" },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "emmylua_ls" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = false,
        emmylua_ls = {
          settings = {
            emmylua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim" } },
              workspace = { library = { vim.env.VIMRUNTIME } },
            },
          },
        },
      },
    },
  },
}
