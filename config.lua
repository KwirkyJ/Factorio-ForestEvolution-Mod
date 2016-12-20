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
        ["grass"] = {spawn = 0.67, death = 0.22, decay = 0.85},
        ["grass-medium"] = {spawn = 0.67, death = 0.22, decay = 0.85},
        ["grass-dry"] = {spawn = 0.67, death = 0.22, decay = 0.85},
    },

    -- factor modifying tree behavior when tile has ore on it
    tree_tile_ore_modifiers = {mast = 1, spawn = 0.3, death = 1, decay = 0.6},
    
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

