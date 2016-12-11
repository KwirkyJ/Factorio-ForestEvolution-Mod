require "config"
-- inherits: 
-- tree_update_interval
-- tree_update_fraction
-- enable_debug_window
-- max_grown_per_tick
-- tree_tile_densities
-- tree_density_default
-- tree_ore_density_modifier
-- tree_tile_decay
-- tree_decay_default
-- tree_dieoff_chance

local total_seeded, total_killed, total_decayed = 0, 0, 0
local total_alive, total_dead = 0, 0
local locales

local chunksize = 32

local tree_names = {
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
}

local dead_tree_names = {
    "dead-tree",
    "dry-tree",
    "green-coral",
    "dead-grey-trunk",
    "dry-hairy-tree",
    "dead-dry-hairy-tree",
}

-- =================
-- === UTILITIES ===
-- =================

--local fmod = math.fmod

-- round to nearest zero
-- !note! round(-0.5) -> -1
local function round (n)
    if n >= 0 then 
        return math.floor (n+0.5)
    else
        return math.ceil (n-0.5)
    end
end
assert (round ( 1.5) == 2)
assert (round ( 1.2) == 1)
assert (round ( 0.8) == 1)
assert (round ( 0.5) == 1)
assert (round ( 0.3) == 0)
assert (round ( 0.0) == 0)
assert (round (-0.3) == 0)
assert (round (-0.5) ==-1)
assert (round (-0.8) ==-1)
assert (round (-2.2) ==-2)

-- random-number generator with normal distribution centered about 0
-- values in excess of +/- 3 are uncommon
local function marsaglia ()
    local u,v,S
    repeat
        u, v = math.random (), math.random ()
        if math.random () < 0.5 then u = -u end
        if math.random () < 0.5 then v = -v end
        S = u^2 + v^2
    until S < 1
    local K = ((-2 * math.log (S)) / S) ^ 0.5
    return u*K, v*K
end

-- returns true if a is present in table b
-- a == b[any]
local function eqany(a,b)
    for i = 1,#b do
        if a == b[i] then
            return true
        end
    end
    return false
end
assert (eqany (3, {2,3,4}))
assert (not eqany (1, {2,3,4}))

-- LuaSurface.count_entities_filtered() is slow.
-- LuaForce.get_entity_count() is much faster, but it needs 
-- entity name argument, not type so we must repeat it for all types of trees.
local function count_trees (names)
    local sum = 0
    for i=1, #names do
        sum = sum + game.forces.neutral.get_entity_count (names[i])
    end
    return sum
end

-- find number of trees in a given area (position +/- radius)
local function get_tree_count (surface, position, radius)
    local x, y = position.x, position.y
    return surface.count_entities_filtered{area={{x-radius, y-radius},
                                                 {x+radius, y+radius}},
                                                 type="tree"}
end

-- find the maximum and current density at this position (+/- radius)
-- radius is 'square area' at present
local function get_tree_density (surface, position, radius)
    local capacity, area, tile = 0, 0, {}
    for x = position.x-radius, position.x+radius do
        for y = position.y-radius, position.y+radius do
            tile = surface.get_tile (x, y)
            if tile.valid then 
                area = area + 1
                local cap = tree_tile_densities[tile.name] or 
                            tree_density_default
                local ore_count = surface.count_entities_filtered{position=position, type="resource"}
                if ore_count > 0 then
                    cap = cap * tree_ore_density_modifier
                end
                capacity = capacity + cap
            end
        end
    end
    return capacity/area, get_tree_count (surface, position, radius)/area
end

-- ===============
-- === LOCALES ===
-- ===============

local locales_has, locales_get_count
local locales_add_chunk, locales_get_random_chunk

-- Create a pristine Locales "object" for storage, quick lookup, 
-- and random access of Chunks 
-- @return Locales table-object-structure
local function init_locales ()
    return {n=0, 
            flat={},
            add_chunk = locales_add_chunk,
            get_random_chunk = locales_get_random_chunk,
            get_count = locales_get_count,
            has = locales_has,
           }
end

-- Add a Chunk to the structure
-- @param chunk Chunk {x=0, y=32}, e.g.
locales_add_chunk = function (self, chunk)
    local n, row = self.n, self[chunk.x]
    if row then
        row[chunk.y] = true
    else
        self[chunk.x] = {[chunk.y] = true}
    end
    table.insert (self.flat, {x = chunk.x, y = chunk.y})
    self.n = n + 1
end

-- Get count of chunks in structure
-- @return number (integer)
locales_get_count = function (self)
    return self.n
end

-- Get a random Chunk in the structure
-- @return nil iff structure is empty; 
--         else a Chunk
locales_get_random_chunk = function (self)
    if self.n > 0 then
        return self.flat[math.random (#self.flat)]
    end
end

-- Check whether structure has (contains) a Chunk
-- @param chunk Chunk {x=0, y=32}, e.g.
-- @return nil iff not in structure;
--         else true
locales_has = function (self, c)
    if not self[c.x] then 
        return nil 
    else
        return self[c.x][c.y]
    end
end

-- === TEST LOCALES ===
locales = init_locales ()
assert (locales:get_count () == 0)
assert (not locales:has ({x=0, y=0}))

-- add chunks
locales:add_chunk ({x=  0, y=64})
locales:add_chunk ({x= 96, y=0})
locales:add_chunk ({x=-32, y=0})
locales:add_chunk ({x=  0, y=0})

-- verify state and behaviors
assert (locales:get_count () == 4)
assert (locales:has ({x=0, y=0}))
assert (locales:has ({x=96, y=0}))
assert (locales:has ({x=0, y=64}))
assert (not locales:has ({x=32, y=32}))
for _=1, 5 do
    assert (locales:has (locales:get_random_chunk ()))
end

-- test duplicate addition
assert (locales:get_count () == 4)
assert (locales:has ({x=96, y=0}))
locales:add_chunk ({x=96, y=0})
assert (locales:get_count () == 5)
assert (locales:has ({x=96, y=0}))

-- reset and verify
locales = init_locales ()
assert (locales:get_count () == 0)
assert (not locales:has ({x=0, y=0}))
-- === END LOCALES TESTS ===

-- ==================
-- === TREE STUFF ===
-- ==================

local function can_grow_on_tile (surface, tile)
    local d_target, d_ideal, d_actual --densities 
    if not tile.valid then
        return false
    end
    d_target = tree_tile_densities[tile.name] or tree_density_default
    if d_target == 0 then
        return false
    end
    d_ideal, d_actual = get_tree_density (surface, tile.position, 3)
    if d_ideal < d_actual then
        return false
    end
        return true
end

local function try_add_tree (surface, tree)
    if eqany (tree.name, dead_tree_names) then
        return false
    end
    local dx, dy = marsaglia () -- normal random distribution
    local x, y = round (tree.position.x + dx), round (tree.position.y + dy)
    if x == tree.position.x and y == tree.position.y then
        return false
    end
    local newpos = surface.find_non_colliding_position (tree.name, {x,y}, 1, 1)
    if newpos and
       can_grow_on_tile (surface, surface.get_tile (newpos.x, newpos.y))
    then
       return surface.create_entity{name=tree.name, 
                                    position=newpos, 
                                    force=tree.force}
    else
        return false
    end
end

local function get_trees_in_chunk (surface, chunk)
    local area = {{chunk.x * chunksize, chunk.y * chunksize}, 
                  {(chunk.x + 1) * chunksize, (chunk.y + 1) * chunksize}}
    if 0 < surface.count_entities_filtered{area = area, type = "tree"} then
        return surface.find_entities_filtered{area = area, type = "tree"}
    else
        return {}
    end
end

local function try_decompose (surface, trees, tree, i)
    local tile = surface.get_tile (tree.position.x, tree.position.y)
    if math.random () < (tree_tile_decay[tile.name] or 
                         tree_decay_default) 
    then
        tree.destroy ()
        table.remove (trees, i)
        total_decayed = total_decayed + 1
    end
end

local function try_seed (surface, tree)
    if try_add_tree (surface, tree) then
        total_seeded = total_seeded + 1
    end
end

local function try_kill (surface, trees, tree, i)
    local position = {x=tree.position.x, y=tree.position.y}
    local force = tree.force
    if math.random () < tree_dieoff_chance then
        tree.destroy ()
        table.remove (trees, i)
        local carcass = dead_tree_names[math.random (#dead_tree_names)]
        surface.create_entity{name=carcass, position=position, force=force}
        total_killed = total_killed + 1
    end
end

local function update_chunk_trees (surface, chunk)
    local trees = get_trees_in_chunk (surface, chunk)
    for _=1, math.min (max_grown_per_tick, #trees) do
        local i = math.random (#trees)
        local tree = trees[i]
        if eqany (tree.name, dead_tree_names) then
            try_decompose (surface, trees, tree, i)
        elseif i%2 == 1 then
            try_seed (surface, tree)
        else
            try_kill (surface, trees, tree, i)
        end
    end
end

local function populate_locales (surface)
    for chunk in surface.get_chunks () do
        if not locales:has (chunk) then
            locales:add_chunk (chunk)
        end
    end
end

-- ===========
-- === GUI ===
-- ===========

local function init_trees_gui ()
    local ui =  game.players[1].gui.left
    ui.add{type="frame", name="trees", caption="Trees", direction="vertical"}
    ui = ui.trees 
    ui.add{type="label",name="progress"}
    ui.add{type="label",name="total"}
    ui.add{type="label",name="grown"}
    ui.add{type="label",name="killed"}
    ui.add{type="label",name="decayed"}
    
    ui.add{type="label",name="chunks"}
end
    
local function update_trees_gui (ui)
    ui.progress.caption = "State: ".. tree_update_interval - (game.tick % tree_update_interval)
    ui.total.caption = "Total trees: "..total_alive+total_dead.." ("..total_alive..","..total_dead..")"
    ui.grown.caption = "Trees grown: " .. total_seeded
    ui.killed.caption = "Trees died: " .. total_killed
    ui.decayed.caption = "Trees decayed: " .. total_decayed
    
    ui.chunks.caption = "Chunks: " .. locales:get_count ()
end

-- =================
-- === LOOP/HOOK ===
-- =================

function on_tick(event)
    if game.tick % tree_update_interval == 0 then
        local surface = game.surfaces[1]
        populate_locales (surface)
        
        --for _=1, math.ceil (locales:get_count () * tree_update_fraction) do
        --    update_chunk_trees (surface, locales:get_random_chunk ())
        --end
        update_chunk_trees (surface, locales:get_random_chunk ())
    end
    
    if enable_debug_window then
        total_alive = count_trees (tree_names) 
        total_dead = count_trees (dead_tree_names)
        if not game.players[1].gui.left.trees then
            init_trees_gui ()
        end
        update_trees_gui (game.players[1].gui.left.trees)
    end
end

-- Register event handlers
script.on_event(defines.events.on_tick, function(event) on_tick(event) end)
