-- Python: point basedpyright at the project's uv environment.
--
-- Two defaults collide in a uv workspace. lspconfig roots basedpyright at the
-- nearest `pyproject.toml`, which for a workspace member is the package dir, and
-- basedpyright only auto-detects a `.venv` sitting in that root. Finding none it
-- falls back to `python` on $PATH, so every third-party import goes unresolved
-- and the workspace-root `[tool.pyright]` block is never read either.
--
-- So fix both ends: `uv.lock` anchors the root, and the interpreter is resolved
-- from there explicitly instead of being guessed a second time.

-- `uv.lock` first: it exists only at the workspace root, so it outranks a member
-- package's `pyproject.toml` however deep the open file sits. vim.fs.root tries
-- the markers in order, each against every ancestor, so order is priority.
local root_markers = {
  "uv.lock",
  "pyrightconfig.json",
  "pyproject.toml",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  "Pipfile",
  ".git",
}

--- Interpreter of the uv environment covering `root`, if there is one.
---@param root string?
---@return string?
local function venv_python(root)
  -- uv creates the environment as `.venv` at the workspace root unless told otherwise.
  local venv = vim.env.UV_PROJECT_ENVIRONMENT or ".venv"
  local dir = root
  while dir and dir ~= "" do
    local python = dir .. "/" .. venv .. "/bin/python"
    if vim.uv.fs_stat(python) then
      return python
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      return nil
    end
    dir = parent
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          root_markers = root_markers,
          before_init = function(_, config)
            local python = venv_python(config.root_dir)
            if python then
              config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
                python = { pythonPath = python },
              })
            end
          end,
        },
        -- Same root, so ruff reads the workspace's `[tool.ruff]` rather than a
        -- member package's.
        ruff = {
          root_markers = root_markers,
        },
      },
    },
  },
}
