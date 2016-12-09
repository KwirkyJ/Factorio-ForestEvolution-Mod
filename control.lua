require "config"
-- inherits: 
-- tree_update_interval
-- tree_update_locales
-- enable_debug_window
-- tree_tile_densities
-- tree_density_default
-- tree_ore_density_modifier
-- max_grown_per_tick

local total_seeded, total_killed, total_decayed = 0, 0, 0
local total_alive, total_dead = 0, 0

local chunksize = 32
local max_tick_chunk = 2

local current_cycle = 0

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

-- ===================
-- === TREE GROWTH ===
-- ===================

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

local function spawn_trees_in_chunk (surface, trees, max)
    max = max or max_tick_chunk
    for _=1, math.min (max, #trees) do
        local tree = trees[math.random(#trees)]
        if try_add_tree (surface, tree) then
            total_seeded = total_seeded + 1
        end
    end
end

local function cull_dead_trees (surface, trees, tries)
    for _=1, math.min (tries, #trees) do
        local i = math.random (#trees)
        local tree = trees[i]
        if eqany (tree.name, dead_tree_names) then
            -- TODO: adjust removal chance to function of density and 'biome'
            if math.random () < 0.2 then -- 20% chance to decay?
                local success = tree.destroy () --TODO: destroy() vs die(); nuke everything to demonstrate clearly
                if success then 
                    table.remove (trees, i) 
                    total_decayed = total_decayed + 1
                end
            end
        end
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

--[[
local function update_trees_in_locale (L)
    local chunk = L[math.random (#L)]
    local surface = game.surfaces[1]
    local trees = get_trees_in_chunk (surface, chunk)
    cull_dead_trees (surface, trees, 10) -- trees table possibly modified here
    -- kill some trees
    spawn_trees_in_chunk (surface, trees, max_grown_per_tick)
end
--]]

-- ===============
-- === LOCALES ===
-- ===============

-- "Object" for storage and quick lookup of Chunks in the game Surface
local locales = {n=0, flat={}}
-- locale[x][y]=i, ["n"] = count of chunks in structure
-- e.g., {x=0,y=0}, {x=32,y=0}, {x=0,y=32}
-- locales{n=3,
--         [0] = {0=3, 32=1}, 
--         [32] = {0=1},
--         flat = {[1] = {x= 0,y=0},
--                 [2] = {x=32,y=0},
--                 [3] = {x= 0,y=32},
--                }
--        }

-- Get a random Chunk in the structure
-- @param locale_index 
-- @return nil iff structure is empty 
--             or no Chunk matches locale_index (if provided); 
--         else a Chunk
locales.get_random_chunk = function (self, locale_index)
    if self.n < 1 then 
        return nil 
    elseif not locale_index then
        return self.flat[math.random (#self.flat)]
    else
        local n, seen, chunk, i = self.n, {}
        assert (n == #self.flat)
        while #seen < n do
            i = math.random (n)
            chunk, seen[i] = self.flat[i], true
            if get_chunk_locale (chunk) == locale_index then
                return chunk
            end
        end
        return nil
    end
end

-- Get which locale this chunk is in
-- @param chunk Chunk {x=0, y=32}, e.g.
-- @return nil iff not in structure;
--         else number (integer)
locales.get_chunk_locale = function (self, c)
    if not self[c.x] then 
        return nil 
    else
        return self[c.x][c.y]
    end
end

-- Add a Chunk to the structure
-- @param chunk Chunk {x=0, y=32}, e.g.
locales._add_chunk = function (self, chunk)
    local i, n, row = math.random (tree_update_locales),
                      self.n, 
                      self[chunk.x]
    if row then
        row[chunk.y] = i
    else
        self[chunk.x] = {[chunk.y] = i}
    end
    table.insert (self.flat, {x = chunk.x, y = chunk.y})
    self.n = n + 1
end

-- Iterate over Chunks in game surface and make sure all are in the structure
-- @param surface LuaSurface; defaults to game.surfaces[1]
locales.add_missing_chunks = function (self, surface)
    surface = surface or game.surfaces[1]
    for chunk in surface.get_chunks () do
        if not self:get_chunk_locale (chunk) then
            self:_add_chunk (chunk)
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
    
    ui.add{type="label",name="locales_n"}
end
    
local function update_trees_gui (ui)
    ui.progress.caption = "State: ".. tree_update_interval - (game.tick % tree_update_interval)
    ui.total.caption = "Total trees: "..total_alive+total_dead.." ("..total_alive..","..total_dead..")"
    ui.grown.caption = "Trees grown: " .. total_seeded
    ui.killed.caption = "Trees died: " .. total_killed
    ui.decayed.caption = "Trees decayed: " .. total_decayed
    
    ui.locales_n.caption = "locales.n: " .. locales.n
end

-- =================
-- === LOOP/HOOK ===
-- =================

function on_tick(event)
    --[[
    if game.tick % tree_update_interval > 0 then 
        return 
    end
    current_cycle = (current_cycle + 1) % tree_update_locales
    if current_cycle == 0 then
        current_cycle = #locales
    end
    add_missing_chunks_to_locales ()
    update_trees_in_locale (locales[current_cycle]) 
    --]]
    ---[[
    if game.tick % tree_update_interval == 0 then
        local surface = game.surfaces[1]
        locales:add_missing_chunks (surface)
        
        local trees = get_trees_in_chunk (surface, locales:get_random_chunk ())
        --[=[ handy nested comments
        if #trees > 0 then
            for _=1, #trees do
                local tree = table.remove (trees, 1)
                tree.destroy ()
                total_killed = total_killed + 1
            end
        end
        --]=]
        
        for _=1, math.min (max_grown_per_tick, #trees) do
            local i = math.random (#trees)
            local tree = trees[i]
            if eqany (tree.name, dead_tree_names) then -- cull
                local tile = surface.get_tile (tree.position.x, tree.position.y)
                if math.random () < (tree_tile_decay[tile.name] or 
                                     tree_decay_default) 
                then
                    tree.destroy ()
                    table.remove (trees, i)
                    total_decayed = total_decayed + 1
                end
            elseif i%2 == 1 then -- seed
                    if try_add_tree (surface, tree) then
                        total_seeded = total_seeded + 1
                    end
            else -- kill
                local position = {x=tree.position.x, y=tree.position.y}
                local force = tree.force
                --local d_ideal, d_actual = get_tree_density (surface, 
                --                                            position, 
                --                                            3)
                --if math.random () < (d_actual / d_ideal)^4 then
                if math.random () < tree_dieoff_chance then
                    tree.destroy ()
                    table.remove (trees, i)
                    local carcass = dead_tree_names[math.random (#dead_tree_names)]
                    surface.create_entity{name=carcass, 
                                          position=position, 
                                          force=force}
                    total_killed = total_killed + 1
                end
            end
        end
    end
    
    --]]
    total_alive = count_trees (tree_names) 
    total_dead = count_trees (dead_tree_names)
    if enable_debug_window then
        if not game.players[1].gui.left.trees then
            init_trees_gui ()
        end
        update_trees_gui (game.players[1].gui.left.trees)
    end
end

-- Register event handlers
script.on_event(defines.events.on_tick, function(event) on_tick(event) end)
