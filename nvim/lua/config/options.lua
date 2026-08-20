-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = false -- absolute line numbers

-- Root detection. LazyVim defaults to { "lsp", { ".git", "lua" }, "cwd" }, which
-- resolves per BUFFER and only falls back to the working directory — so opening
-- one file from another project silently re-roots pickers and the sidebar there.
-- Pinning it to cwd gives the VSCode model instead: the root is the folder you
-- opened, and `:cd` is the only thing that changes it.
vim.g.root_spec = { "cwd" }

vim.g.cursorline = false
vim.g.cursorcolumn = false
vim.g.spell = false
vim.g.ttyfast = true
