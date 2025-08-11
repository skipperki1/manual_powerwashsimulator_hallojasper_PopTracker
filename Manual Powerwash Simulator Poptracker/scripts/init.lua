-- entry point for all lua code of the pack
-- more info on the lua API: https://github.com/black-sliver/PopTracker/blob/master/doc/PACKS.md#lua-interface
ENABLE_DEBUG_LOG = true
-- get current variant
local variant = Tracker.ActiveVariantUID
-- check variant info
IS_ITEMS_ONLY = variant:find("itemsonly")
HORIZONTAL = variant:find("standard")
VERTICAL = variant:find("vertical")

print("-- Example Tracker --")
print("Loaded variant: ", variant)
print("IS_ITEMS_ONLY: ", IS_ITEMS_ONLY)
print("HORIZONTAL: ", HORIZONTAL)
print("VERTICAL: ", VERTICAL)
if ENABLE_DEBUG_LOG then
    print("Debug logging is enabled!")
end

-- Utility Script for helper functions etc.
ScriptHost:LoadScript("scripts/utils.lua")

-- Logic
ScriptHost:LoadScript("scripts/logic/logic.lua")
ScriptHost:LoadScript("scripts/autotracking/settings.lua")

-- Custom Items
ScriptHost:LoadScript("scripts/custom_items/class.lua")
ScriptHost:LoadScript("scripts/custom_items/progressiveTogglePlus.lua")
ScriptHost:LoadScript("scripts/custom_items/progressiveTogglePlusWrapper.lua")

-- Items
Tracker:AddItems("items/items.jsonc")
Tracker:AddItems("items/settings.jsonc")


if not IS_ITEMS_ONLY then -- <--- use variant info to optimize loading
    -- Maps
    Tracker:AddMaps("maps/maps.jsonc")
    -- Locations
    Tracker:AddLocations("locations/locations.jsonc")
end

-- Layout
Tracker:AddLayouts("layouts/items.jsonc")
Tracker:AddLayouts("layouts/settings.jsonc")
if HORIZONTAL then
    Tracker:AddLayouts("layouts/tracker.jsonc")
    Tracker:AddLayouts("layouts/broadcast.jsonc")
    print("Horizontal Layouts loaded!")
elseif IS_ITEMS_ONLY then
    Tracker:AddLayouts("layouts/tracker.jsonc")
    Tracker:AddLayouts("layouts/broadcast.jsonc")
    print("Itemsonly Layout loaded!")
elseif VERTICAL then
    Tracker:AddLayouts("layouts/tracker.jsonc")
    Tracker:AddLayouts("layouts/broadcast.jsonc")
    print("Vertical Layouts loaded!")
end

-- AutoTracking for Poptracker
if PopVersion and PopVersion >= "0.18.0" then
    ScriptHost:LoadScript("scripts/autotracking.lua")
end
