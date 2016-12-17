require "config"
-- inherits: 
-- enable_debug_window
-- seed_location_search_tries
-- max_modified_per_tick
-- tree_tile_properties
-- tree_tile_ore_modifiers

local locales = require ("./locales")["init_locales"] ()
assert (type(locales) == type({}), "failed to initiate locales")

local total_seeded, total_killed, total_decayed = 0, 0, 0
local total_alive, total_dead = 0, 0
--local locales

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

-- returns true if a is present in table (array) b
-- a == b[any]
-- @param a Element to check in values
-- @param b Table in form of array (indices 1..n with non-nil values)
-- @return true iff b[k] == a where k is some integer;
--         else false
local function eqany(a,b)
    for i = 1,#b do
        if a == b[i] then
            return true
        end
    end
    return false
end
assert (eqany (3, {2,3,4}), "3 present")
assert (not eqany (5, {2,3,4}), "5 absent")
assert (not eqany (4, {[1]=3, [3]=4}), "sparse, interrupted array")
assert (not eqany (2, {[1]=true, [2]=true, [3]=true}), "2 not in values")
assert (not eqany (2, {["a"]=2}), "associative table")

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

local function tile_has_ore (surface, position)
    return 0 < surface.count_entities_filtered{position=position, 
                                               type="resource"}
end

local function get_tile_properties (surface, tile)
    if not tile.valid then return nil end
    -- assert (tile.valid) -- find a gentler way?
    local props = tree_tile_properties[tile.name] or {}
    local ore_on_tile = tile_has_ore (surface, tile.position)
    for k,v in pairs (tree_tile_properties.default) do
        props[k] = props[k] or v
        if ore_on_tile then
            props[k] = props[k] * tree_tile_ore_modifiers[k]
        end
    end
    return props
end

local function get_tile_properties_position (surface, position)
    return get_tile_properties (surface, 
                                surface.get_tile (position.x, position.y))
end

local function populate_locales (surface)
    for chunk in surface.get_chunks () do
        if not locales:has (chunk) then
            locales:add_chunk (chunk)
        end
    end
end

-- ==================
-- === TREE STUFF ===
-- ==================

local function get_trees_in_chunk (surface, chunk)
    local area = {{chunk.x * chunksize, chunk.y * chunksize}, 
                  {(chunk.x + 1) * chunksize, (chunk.y + 1) * chunksize}}
    if 0 < surface.count_entities_filtered{area = area, type = "tree"} then
        return surface.find_entities_filtered{area = area, type = "tree"}
    else
        return {}
    end
end

local function try_decompose (decay_chance, tree, trees, i)
    if math.random () <= decay_chance then
        tree.destroy ()
        table.remove (trees, i)
        total_decayed = total_decayed + 1
    end
end

local function get_seeding_location (surface, tree)
    local x, y, dx, dy, p
    for _=1, seed_location_search_tries do
        dx, dy = marsaglia ()
        x, y = round (tree.position.x + dx), round (tree.position.y + dy)
        if x ~= tree.position.x and y ~= tree.position.y then
            p = surface.find_non_colliding_position (tree.name, {x,y}, 1, 1)
            if p then
                return p
            end
        end
    end
end

local function try_spawn (surface, tree)
    local p, t_props
    p = get_seeding_location (surface, tree)
    if p then
        t_props = get_tile_properties_position (surface, p)
        if t_props and math.random () <= t_props.spawn then
            return surface.create_entity{name=tree.name, 
                                         position=p, 
                                         force=tree.force}
        end
    end
end

local function try_seed (seed_chance, surface, tree)
    if math.random () <= seed_chance then
        if try_spawn (surface, tree) then
            total_seeded = total_seeded + 1
        end
    end
end

local function try_kill (death_chance, surface, tree, trees, i)
    if math.random () > death_chance then 
        return 
    end
    local position, force, carcass
    position = {x=tree.position.x, y=tree.position.y}
    force = tree.force
    tree.destroy ()
    table.remove (trees, i)
    --carcass = dead_tree_names[math.random (#dead_tree_names)]
    surface.create_entity{name=dead_tree_names[math.random (#dead_tree_names)],
                          position=position,
                          force=force}
    total_killed = total_killed + 1
end

local function update_chunk_trees (surface, chunk)
    local trees = get_trees_in_chunk (surface, chunk)
    for _=1, math.min (max_modified_per_tick, #trees) do
        local i = math.random (#trees)
        local tree = trees[i]
        local t_props = get_tile_properties_position (surface, tree.position)
        assert (t_props, "tree's position does not yield valid tile?")
        if eqany (tree.name, dead_tree_names) then
            try_decompose (t_props.decay, tree, trees, i)
        elseif i%2 == 1 then
            try_seed (t_props.mast, surface, tree)
        else
            try_kill (t_props.death, surface, tree, trees, i)
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
    ui.add{type="label",name="total"}
    ui.add{type="label",name="grown"}
    ui.add{type="label",name="killed"}
    ui.add{type="label",name="decayed"}
    
    ui.add{type="label",name="chunks"}
end
    
local function update_trees_gui (ui)
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
    local surface = game.surfaces[1]
    populate_locales (surface)
    update_chunk_trees (surface, locales:get_random_chunk ())
    
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
