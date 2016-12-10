
-- number of ticks between update cycle
tree_update_interval = 4

-- how much of the map area (chunks) to update per cycle
-- e.g., 0.01 on map with 864 chunks -> 9; 14 chunks -> 1
tree_update_fraction = 0.01 --TODO: use in control.lua

-- Show debug window
enable_debug_window = true

--
max_grown_per_tick = 256

-- how tightly packed can trees get on different types of terrain
-- 0 -> will not grow at all
-- 1 -> probably cannot walk between
tree_tile_densities = {
    ["out-of-map"] = 0,
    ["deepwater"] = 0,
    ["deepwater-green"] = 0,
    ["water"] = 0,
    ["water-green"] = 0,
    ["stone-path"] = 0,
    ["concrete"] = 0,
    ["hazard-concrete-left"] = 0,
    ["hazard-concrete-right"] = 0,
    ["sand"] = 0.01,
    ["sand-dark"] = 0.05,
    ["dirt"] = 0,
    ["dirt-dark"] = 1,
    ["grass"] = 0.01,
    ["grass-medium"] = 0.2,
    ["grass-dry"] = 0.05,
}

-- density when none of the above match (for any unforeseen reason)
tree_density_default = 0.7

-- factor modifying tree density when tile has ore on it
tree_ore_density_modifier = 0.3

-- probability of a tree decaying in a certain type of terrain ("biome")
-- can optimize by omitting tree-inhospitable tiles
-- 0 -> will be around forever
-- 1 -> will be removed at next encounter with algorithm
tree_tile_decay = {
    ["sand"] = 0.01,
    ["sand-dark"] = 0.05,
    ["dirt"] = 0,
    ["dirt-dark"] = 1,
    ["grass"] = 0.01,
    ["grass-medium"] = 0.2,
    ["grass-dry"] = 0.05,
}

--default value when tile name does not match any tree_tile_decay keys
tree_decay_default = 0.1

-- likelihood of a tree dying
tree_dieoff_chance = 0.002

