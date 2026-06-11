local bind = require("keymap.bind")
local map_callback = bind.map_callback

return {
	-- Plugin: diffview.nvim — "PR view": tree of every file this branch changed
	-- vs the remote default branch, each opening its diff in the buffer.
	["n|<leader>gm"] = map_callback(function()
			local function git(cmd)
				local out = vim.fn.systemlist(cmd)
				if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
					return nil
				end
				return out[1]
			end
			-- Prefer origin's recorded default branch; fall back to common names.
			local base = git({ "git", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" })
			if not base then
				for _, ref in ipairs({ "origin/main", "origin/master", "main", "master" }) do
					if git({ "git", "rev-parse", "--verify", "--quiet", ref }) then
						base = ref
						break
					end
				end
			end
			if not base then
				vim.notify("diffview: could not resolve a base branch", vim.log.levels.WARN)
				return
			end
			vim.cmd("DiffviewOpen " .. base .. "...HEAD")
		end)
		:with_noremap()
		:with_silent()
		:with_desc("git: Diff branch vs main (PR view)"),
}
