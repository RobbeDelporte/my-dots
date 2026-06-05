-- swayimg viewer config (static; tracked in my-dots, symlinked to ~/.config/swayimg).
-- Behaviour + keybinds live here and are safe to hand-edit. Colours are matugen-
-- generated separately and pulled in via dofile (see below) so they re-theme with
-- the wallpaper without clobbering this file.

-- Current matugen palette. pcall so a missing render (fresh checkout) doesn't break
-- swayimg — it just falls back to built-in default colours.
pcall(dofile, os.getenv("HOME") .. "/my-dots/generated/swayimg-colors.lua")

-- Behaviour: opening a single file (e.g. xdg-open) also loads the rest of its
-- folder, so the gallery shows the whole directory instead of just one image.
swayimg.imagelist.enable_adjacent(true)

-- Annotate: send the current image to satty. POSIX-escape single quotes in the
-- path (' -> '\'') so odd filenames (spaces, apostrophes) don't break the shell.
-- --resize smart keeps satty within one monitor on multi-output captures.
local function shq(p) return "'" .. p:gsub("'", [['\'']]) .. "'" end
swayimg.viewer.on_key("e", function()
  os.execute("satty --resize smart --filename " .. shq(swayimg.viewer.get_image().path) .. " &")
end)
swayimg.gallery.on_key("e", function()
  os.execute("satty --resize smart --filename " .. shq(swayimg.gallery.get_image().path) .. " &")
end)

-- Gallery toggle: "g" switches viewer <-> gallery (swayimg's built-in key is Enter).
swayimg.viewer.on_key("g", function() swayimg.set_mode("gallery") end)
swayimg.gallery.on_key("g", function() swayimg.set_mode("viewer") end)

-- Navigate: Right/Left -> next/prev image. Overrides swayimg's built-in arrow
-- panning (pan stays on mouse drag + scroll); PgDn/PgUp also navigate by default.
swayimg.viewer.on_key("Right", function() swayimg.viewer.switch_image("next") end)
swayimg.viewer.on_key("Left", function() swayimg.viewer.switch_image("prev") end)
