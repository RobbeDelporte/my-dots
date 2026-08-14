-- Resolves the live colour palette: tracked static fallback (colors.lua)
-- overlaid with matugen's render, if one exists.
--
-- ~/.config/hypr is a whole-dir symlink to the repo, so matugen must NOT write
-- inside it (it would clobber the tracked colors.lua). The generated palette
-- lands in the gitignored ~/my-dots/generated/ sink instead, and is pulled in
-- here by absolute path.
--
-- Under hyprlang a missing `source =` was a harmless warning. Under Lua a bare
-- require() of a nonexistent module raises a real error that aborts the whole
-- calling file — which would take the entire config down on a machine that has
-- never run matugen. Hence the explicit existence check plus pcall: absent or
-- malformed generated palette degrades to the static fallback, nothing else.

local palette = require("colors")

local HOME = os.getenv("HOME") or ""
local GENERATED = HOME .. "/my-dots/generated/hypr-colors.lua"

local function load_generated(path)
    local probe = io.open(path, "r")
    if not probe then
        return nil
    end
    probe:close()

    local ok, result = pcall(dofile, path)
    if ok and type(result) == "table" then
        return result
    end
    return nil
end

local generated = load_generated(GENERATED)
if generated then
    for role, hex in pairs(generated) do
        palette[role] = hex
    end
end

return palette
