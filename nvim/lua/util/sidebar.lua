-- One sidebar slot, three switchable tabs, VSCode-style.
--
-- Each tab is a snacks picker pinned to the `sidebar` layout. Only one is ever
-- live, so "switching tabs" is closing one picker and opening the next in the
-- same slot. Which tab is live is *derived* from the live pickers rather than
-- stored, so closing the pane with `q` can't leave this module out of sync.
local M = {}

---@class Sidebar.Tab
---@field name string
---@field source string picker source, used to recognise a live tab
---@field open fun(opts?: table)
---@field resolve? fun(cb: fun(opts?: table)) async; calls back with nil to veto the swap

-- Verified: these four are what make a picker behave like the explorer, i.e.
-- a persistent split that survives jumping to a file.
local base = {
  layout = { preset = "sidebar", preview = false },
  auto_close = false,
  jump = { close = false },
  focus = "list",
}

--- Pin a picker to the sidebar slot and give it the tab-strip keys.
---@param extra? table
local function pin(extra)
  return vim.tbl_deep_extend("force", {}, base, {
    actions = {
      sidebar_next = { desc = "Next sidebar tab", action = function() M.cycle(1) end },
      sidebar_prev = { desc = "Prev sidebar tab", action = function() M.cycle(-1) end },
    },
    -- Explicit descs so the pane's own `?` help reads as prose, not action names.
    win = {
      list = {
        keys = {
          L = { "sidebar_next", desc = "Next sidebar tab", mode = "n" },
          H = { "sidebar_prev", desc = "Prev sidebar tab", mode = "n" },
        },
      },
    },
  }, extra or {})
end

---@type Sidebar.Tab[]
M.tabs = {
  {
    name = "explorer",
    source = "explorer",
    open = function()
      Snacks.explorer(pin({ cwd = LazyVim.root() }))
    end,
  },
  {
    name = "changes",
    source = "git_status",
    open = function()
      Snacks.picker.git_status(pin())
    end,
  },
  {
    name = "pr",
    source = "gh_diff",
    -- Resolved before any pane is closed, so a branch with no PR leaves the
    -- sidebar exactly as it was.
    resolve = function(cb)
      local root = LazyVim.root.git()
      local branch = vim.fn.systemlist({ "git", "-C", root, "branch", "--show-current" })[1] or "?"
      local cmd = { "gh", "pr", "view", "--json", "number", "--jq", ".number" }
      vim.system(cmd, { cwd = root, text = true }, function(out)
        vim.schedule(function()
          local pr = tonumber(vim.trim(out.stdout or ""))
          if out.code ~= 0 or not pr then
            Snacks.notify.warn(("No pull request for branch `%s`"):format(branch))
            return cb(nil)
          end
          cb({ pr = pr })
        end)
      end)
    end,
    open = function(opts)
      Snacks.picker.gh_diff(pin(opts))
    end,
  },
}

-- Tab to reopen when toggling the sidebar back on. A preference, not a fact:
-- if it goes stale the worst case is reopening the wrong tab.
M.last = "explorer"

---@param name string
---@return Sidebar.Tab?, number?
local function by_name(name)
  for i, tab in ipairs(M.tabs) do
    if tab.name == name then
      return tab, i
    end
  end
end

--- The live sidebar tab, if the sidebar is open.
---@return Sidebar.Tab?, snacks.Picker?, number?
function M.active()
  for i, tab in ipairs(M.tabs) do
    local picker = Snacks.picker.get({ source = tab.source })[1]
    if picker then
      return tab, picker, i
    end
  end
end

function M.close()
  local _, picker = M.active()
  if picker then
    picker:close()
  end
end

--- Swap the sidebar over to `tab`, closing whatever tab held the slot.
---@param tab Sidebar.Tab
---@param opts? table
local function swap_to(tab, opts)
  local active, picker = M.active()
  if active == tab then
    return picker:focus()
  end
  if picker then
    picker:close()
  end
  M.last = tab.name
  tab.open(opts)
end

--- Show `name`. If it is already the live tab, hop between it and the editor.
---@param name string
function M.show(name)
  local tab = by_name(name)
  if not tab then
    return Snacks.notify.error("Unknown sidebar tab: " .. name)
  end
  local active, picker = M.active()
  if active == tab then
    if picker:is_focused() and vim.api.nvim_win_is_valid(picker.main) then
      vim.api.nvim_set_current_win(picker.main)
    else
      picker:focus()
    end
    return
  end
  if tab.resolve then
    -- Nothing is closed until the resolver succeeds; active state is re-read
    -- inside swap_to because the resolver is async.
    return tab.resolve(function(opts)
      if opts then
        swap_to(tab, opts)
      end
    end)
  end
  swap_to(tab)
end

--- Walk the tab strip, keeping the pane where it is.
---@param delta number
function M.cycle(delta)
  local _, _, i = M.active()
  local tab = M.tabs[((i or 1) + delta - 1) % #M.tabs + 1]
  -- Deferred: this runs from a picker action that is about to close its own picker.
  vim.schedule(function()
    M.show(tab.name)
  end)
end

--- Close the sidebar, or reopen the tab last shown.
function M.toggle()
  if M.active() then
    M.close()
  else
    M.show(M.last)
  end
end

return M
