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

-- Metadata: "i" swaps the top-left overlay between the normal file summary and
-- every tag swayimg's libexiv2 parse produced (Exif + XMP + IPTC). The text
-- templates only resolve tags named one at a time ({meta.Exif.Image.Model}), so
-- the complete list has to be enumerated per image off get_image().meta. Values
-- come out raw (ResolutionUnit = 2, not "inch") and a long dump clips off-screen
-- with no way to scroll -- for those, run `exiv2 -pa <file>` in a terminal.
local SUMMARY = {
  "File:\t{name}",
  "Format:\t{format}",
  "File size:\t{sizehr}",
  "File time:\t{time}",
  "EXIF date:\t{meta.Exif.Photo.DateTimeOriginal}",
  "EXIF camera:\t{meta.Exif.Image.Model}",
}

local meta_mode = false

local function meta_scheme()
  local img = swayimg.viewer.get_image()
  local keys = {}
  for k in pairs(img and img.meta or {}) do keys[#keys + 1] = k end
  if #keys == 0 then return { "File:\t{name}", "Metadata:\tnone" } end
  table.sort(keys)
  local lines = {}
  for _, k in ipairs(keys) do
    -- Flatten tabs/newlines (a stray tab would re-split the key/value pair) and
    -- escape "{" -- the value is inlined into a template string, not substituted.
    local v = tostring(img.meta[k]):gsub("[\t\r\n]", " "):gsub("{", "{{")
    lines[#lines + 1] = k .. ":\t" .. v
  end
  return lines
end

local function apply_overlay()
  swayimg.text.size = meta_mode and 14 or 24
  swayimg.text.timeout = meta_mode and 3600 or 5
  swayimg.text.visible = true
  swayimg.viewer.set_text("topleft", meta_mode and meta_scheme() or SUMMARY)
end

swayimg.viewer.on_key("i", function()
  meta_mode = not meta_mode
  apply_overlay()
end)

-- Keep the dump in sync when navigating with it open.
swayimg.viewer.on_image_change(function()
  if meta_mode then apply_overlay() end
end)
