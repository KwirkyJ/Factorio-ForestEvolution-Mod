return {
    -- Number of ticks between updating trees
    -- 1 = every tick; 60 = once every sixty ticks
    tree_update_interval = 1,

    -- TODO: deprecate max_modified in favor of fractional count
    -- Maximim number of trees touched in a chunk
    -- 0.25 = touch up to 1/4 of a chunk's trees
    tree_population_update_fraction = 0.25,

    -- Size, in tiles per side, of update regions
    locale_size = 32,

    -- Regions around the player to add to locale cache
    locale_cache_radius = 6,
    
    -- Soft limit on the number of trees a locale may contain
    tree_max_locale_population = 1200,

    -- Show debug window
    enable_debug_window = false,

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

    tree_names_live = {
        "tree-01",
        "tree-02",
        "tree-02-red",
        "tree-03",
        "tree-04",
        "tree-05",
        "tree-06",
        "tree-06-brown",
        "tree-07",
        "tree-08",
        "tree-08-brown",
        "tree-08-red",
        "tree-09",
        "tree-09-brown",
        "tree-09-red",
    },

    tree_names_dead = {
        "dead-tree",
        "dry-tree",
        "green-coral",
        "dead-grey-trunk",
        "dry-hairy-tree",
        "dead-dry-hairy-tree",
    },
}

