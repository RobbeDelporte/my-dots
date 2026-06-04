-- https://github.com/neovim/nvim-lspconfig/blob/master/lsp/basedpyright.lua
return {
	root_dir = function(bufnr, on_dir)
		local fname = vim.api.nvim_buf_get_name(bufnr)
		-- In a uv workspace the `[tool.pyright]` config (extraPaths, excludes,
		-- executionEnvironments) and the shared `.venv` live at the WORKSPACE
		-- root, marked by `uv.lock` -- not in the member subdirs, which carry
		-- their own `pyproject.toml`. Rooting at the nearest `pyproject.toml`
		-- would miss that config and break cross-package import resolution, so
		-- prefer `uv.lock`, then fall back to the usual project / VCS markers.
		local root = vim.fs.root(fname, { "uv.lock" })
			or vim.fs.root(fname, { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile" })
			or vim.fs.root(fname, { ".git" })
		on_dir(root or vim.fs.dirname(fname))
	end,
}
