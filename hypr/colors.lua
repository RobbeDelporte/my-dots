-- Tracked static colour fallback. Used when matugen has never rendered (fresh
-- machine, first boot before a wallpaper is set). palette.lua overlays the
-- generated palette on top of this, key by key.
--
-- Bare hex, no leading `#` and no alpha — consumers append their own alpha
-- suffix inline, e.g. "rgba(" .. p.primary .. "e6)". Keep this key set in sync
-- with matugen/templates/hypr-colors.tmpl: identical keys on both sides means
-- the override is total and no stale fallback value can leak through.

return {
    -- Core surface / background
    background              = "131317",
    onBackground            = "e5e1e7",
    surface                 = "131317",
    surfaceDim              = "131317",
    surfaceBright           = "39393d",
    surfaceContainerLowest  = "0e0e12",
    surfaceContainerLow     = "1c1b1f",
    surfaceContainer        = "201f23",
    surfaceContainerHigh    = "2a292e",
    surfaceContainerHighest = "353438",
    onSurface               = "e5e1e7",
    surfaceVariant          = "47464f",
    onSurfaceVariant        = "c8c5d1",
    inverseSurface          = "e5e1e7",
    inverseOnSurface        = "313034",
    outline                 = "918f9a",
    outlineVariant          = "47464f",
    shadow                  = "000000",
    scrim                   = "000000",

    -- Primary
    surfaceTint             = "c2c1ff",
    primary                 = "c2c1ff",
    onPrimary               = "2a2a60",
    primaryContainer        = "7171ac",
    onPrimaryContainer      = "ffffff",
    inversePrimary          = "595992",
    primaryFixed            = "e2dfff",
    primaryFixedDim         = "c2c1ff",
    onPrimaryFixed          = "14134a",
    onPrimaryFixedVariant   = "414178",

    -- Secondary
    secondary               = "c6c4e0",
    onSecondary             = "2e2e44",
    secondaryContainer      = "45455c",
    onSecondaryContainer    = "b4b2ce",
    secondaryFixed          = "e2e0fd",
    secondaryFixedDim       = "c6c4e0",
    onSecondaryFixed        = "19192e",
    onSecondaryFixedVariant = "45455c",

    -- Tertiary
    tertiary                = "f5b2e0",
    onTertiary              = "4e1e44",
    tertiaryContainer       = "bb7da9",
    onTertiaryContainer     = "000000",
    tertiaryFixed           = "ffd7f0",
    tertiaryFixedDim        = "f5b2e0",
    onTertiaryFixed         = "35082e",
    onTertiaryFixedVariant  = "68355c",

    -- Error
    error                   = "ffb4ab",
    onError                 = "690005",
    errorContainer          = "93000a",
    onErrorContainer        = "ffdad6",
}
