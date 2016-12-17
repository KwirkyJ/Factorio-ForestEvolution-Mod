
-- number of ticks between update cycle
--tree_update_interval = 4

-- how much of the map area (chunks) to update per cycle
-- e.g., 0.01 on map with 864 chunks -> 9; 14 chunks -> 1
-- tree_update_fraction = 0.01 --TODO: use in control.lua

-- Show debug window
enable_debug_window = true

-- How many attempts to make at finding an unobstructed position
-- on which a seed might fall
seed_location_search_tries = 5

--
max_modified_per_tick = 256

-- probabilities of each occurrence on different tile types
-- "default" serves two roles:
-- 1 - used in event that a tile name is not matched
-- 2 - default values which tile[name][property] overrides
-- mast  -> probability of seeding
-- spawn -> probability of seed producing a tree
-- death -> probability of tree dying and producing a carcass (dead tree)
-- decay -> probability of carcass being removed
-- ? if death > mast*spawn then population will probably die off
-- ? if decay > death then number of dead trees will probably be low
tree_tile_properties = {
    ["default"] = {mast = 0.4, spawn = 0.8, death = 0.3, decay = 0.3},
    ["out-of-map"] = {spawn = 0},
    ["deepwater"] = {spawn = 0},
    ["deepwater-green"] = {spawn = 0},
    ["water"] = {spawn = 0},
    ["water-green"] = {spawn = 0},
    ["stone-path"] = {spawn = 0},
    ["concrete"] = {spawn = 0},
    ["hazard-concrete-left"] = {spawn = 0},
    ["hazard-concrete-right"] = {spawn = 0},
    ["sand"] = {mast = 0.25, spawn = 0.2, death = 0.15, decay = 0.15},
    ["sand-dark"] = {mast = 0.25, spawn = 0.4, death = 0.1, decay = 0.1},
    ["dirt"] = {spawn = 0.8, death = 0.3, decay = 0.3},
    ["dirt-dark"] = {spawn = 0.8, death = 0.3, decay = 0.3},
    ["grass"] = {spawn = 0.67, death = 0.22, decay = 0.5},
    ["grass-medium"] = {spawn = 0.67, death = 0.22, decay = 0.5},
    ["grass-dry"] = {spawn = 0.67, death = 0.22, decay = 0.5},
}


-- factor modifying tree behavior when tile has ore on it
tree_tile_ore_modifiers = {mast = 1, spawn = 0.3, death = 1, decay = 0.6}

