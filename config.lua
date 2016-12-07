
-- The interval between tree grow cycle in ticks. Lower value grows faster.
tree_expansion_frequency = 16

-- Show debug window for added tree counts and total counts
enable_debug_window = true

-- Hard limit on number of trees. If the number of trees is too large, it takes
-- time to save and load, and any other aspect of the game gets slower.
-- I feel comfortable with this number, but your opinion may differ.
-- If you kill enough trees, they will start growing again.
max_trees = 800000

max_grown_per_tick = 10

-- Threshold rate at grow speed starts dropping
tree_decrease_start = 0.8
