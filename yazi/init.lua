-- yazi init script. Runs once at startup. Plugins live at
-- ~/.config/yazi/plugins/<name>.yazi/; package.toml controls which are
-- installed via `ya pkg install`.

-- Bordered panes (rounded corners).
require("full-border"):setup({
    type = ui.Border.ROUNDED,
})

-- Show git status indicators in the file listing.
-- Toggle the linemode with `m` then pick `git` or `git-files`.
require("git"):setup()
