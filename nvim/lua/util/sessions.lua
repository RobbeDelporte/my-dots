-- Recent persistence.nvim sessions, as a snacks dashboard section.
--
-- persistence already sorts its list by mtime, so "most recent" comes for free;
-- the work here is decoding a session filename back into something readable and
-- turning it into dashboard items.
local M = {}

--- Decode a session file path into the project it belongs to.
---
--- persistence encodes the directory with `/` replaced by `%`, optionally
--- followed by `%%<branch>` (branch slashes are escaped the same way):
---   /home/u/proj on `feat/x`  ->  %home%u%proj%%feat%x.vim
---@param file string absolute path to a session file
---@return { file: string, dir: string, branch: string? }
local function decode(file)
  local dir = require("persistence.config").options.dir
  local name = file:sub(#dir + 1, -5) -- strip the directory prefix and `.vim`
  local encoded_dir, encoded_branch = unpack(vim.split(name, "%%", { plain = true }))
  return {
    file = file,
    dir = (encoded_dir:gsub("%%", "/")),
    branch = encoded_branch and (encoded_branch:gsub("%%", "/")) or nil,
  }
end

--- Dashboard section listing the most recently used sessions.
---
--- Deliberately NOT deduplicated by directory the way `persistence.select()` is:
--- one repo checked out on two branches is two sessions, and which branch you
--- were on is the half worth seeing.
---@param opts? { limit?: number }
---@return snacks.dashboard.Gen
function M.section(opts)
  opts = opts or {}
  local limit = opts.limit or 5

  return function()
    local ok, persistence = pcall(require, "persistence")
    if not ok then
      return {}
    end

    local found = {} ---@type { dir: string, branch: string? }[]
    for _, file in ipairs(persistence.list()) do
      local session = decode(file)
      -- Projects that have since been deleted or moved would otherwise sit in
      -- the list as rows that chdir into nothing.
      if vim.uv.fs_stat(session.dir) then
        found[#found + 1] = session
        if #found >= limit then
          break
        end
      end
    end

    -- snacks renders `desc` before `file` and that order isn't configurable, so
    -- the branch lands left of the path. Pad it to a common width and the two
    -- read as columns instead of colliding; with no branches anywhere the width
    -- is 0 and the section degrades to a plain list of paths.
    local branch_width = 0
    for _, session in ipairs(found) do
      branch_width = math.max(branch_width, vim.fn.strdisplaywidth(session.branch or ""))
    end

    local items = {} ---@type snacks.dashboard.Item[]
    for _, session in ipairs(found) do
      local branch = session.branch or ""
      items[#items + 1] = {
        icon = "directory",
        file = session.dir,
        desc = branch_width > 0 and (branch .. string.rep(" ", branch_width - vim.fn.strdisplaywidth(branch)) .. "  ")
          or nil,
        autokey = true,
        action = function()
          vim.fn.chdir(session.dir)
          -- Source THIS row's session file rather than calling persistence.load(),
          -- which re-derives the path from cwd + current branch. A row for a
          -- branch you have since switched away from would otherwise silently
          -- load nothing (or a different session) while claiming to open this one.
          persistence.fire("LoadPre")
          vim.cmd("silent! source " .. vim.fn.fnameescape(session.file))
          persistence.fire("LoadPost")
        end,
      }
    end
    return items
  end
end

return M
