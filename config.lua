return {
    -- Number of ticks between updating trees
    -- 1 = every tick; 60 = once every sixty ticks
    tree_update_interval = 1,
   
    -- TODO: deprecate max_modified in favor of fractional count
    -- Maximim number of trees touched in a chunk
    -- 0.25 = touch up to 1/4 of a chunk's trees
    tree_chunk_population_fraction = 0.25,
    
    -- How much area around the player to update
    -- Creates a record of chunks to update
    tree_chunk_radius = 6,

    -- Show debug window
    enable_debug_window = true,

    -- How many attempts to make at finding an unobstructed position
    -- on which a seed might fall
    seed_location_search_tries = 6,

    -- probabilities of each occurrence on different tile types
    -- "default" serves two roles:
    -- * used in event that a tile name is not matched
    -- * supplies values which tile[name][property] overrides
    -- mast  -> probability of seeding
    -- spawn -> probability of seed producing a tree
    -- death -> probability of tree dying and producing a carcass (dead tree)
    -- decay -> probability of carcass being removed
    -- ? if death > mast*spawn then population will probably die off
    -- ? if decay > death then number of dead trees will probably be low
    tree_tile_properties = {
        ["default"] = {mast = 0.05, spawn = 0.35, death = 0.02, decay = 0.05},
        ["out-of-map"] = {spawn = 0},
        ["deepwater"] = {spawn = 0},
        ["deepwater-green"] = {spawn = 0},
        ["water"] = {spawn = 0},
        ["water-green"] = {spawn = 0},
        ["stone-path"] = {spawn = 0},
        ["concrete"] = {spawn = 0},
        ["hazard-concrete-left"] = {spawn = 0},
        ["hazard-concrete-right"] = {spawn = 0},
        ["sand"]      = {mast = 0.02, spawn = 0.2, death = 0.005, decay = 0.01},
        ["sand-dark"] = {mast = 0.02, spawn = 0.4, death = 0.01},
        ["dirt"]      = {spawn = 0.8, death = 0.016, decay = 0.1},
        ["dirt-dark"] = {spawn = 0.8, death = 0.016, decay = 0.16},
        ["grass"]        = {spawn=0.64, decay=0.25},
        ["grass-medium"] = {spawn=0.64, decay=0.22},
        ["grass-dry"]    = {spawn=0.52, decay=0.12},
    },

    -- factor modifying tree behavior when tile has ore on it
    tree_tile_ore_modifiers = {mast = 1, spawn = 0.3, death = 1, decay = 0.7},
}

