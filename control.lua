local config = require "./config"
local utils  = require "./utils"

local locales = require ("./locales")["init_locales"] ()
assert (locales.add_chunk, "failed to initiate locales")

local total_seeded, total_killed, total_decayed = 0, 0, 0
local total_alive, total_dead = 0, 0

local chunksize = 32

local cycle_search, cycle_seed, cycle_grown, cycle_kill, cycle_decay, cycle_trees

local tree_names      = config.tree_names_live
local dead_tree_names = config.tree_names_dead

-- =================
-- === UTILITIES ===
-- =================

local eqany     = utils.eqany
local marsaglia = utils.marsaglia
local round     = utils.round

-- wrapper to handle debug logging
local function log_act (a)
    if not config.enable_debug_window then 
        return 
    end
    if a == "kill" then
        total_killed = total_killed + 1
        cycle_kill   = cycle_kill + 1
    elseif a == "mast" then
        cycle_seed = cycle_seed + 1
    elseif a == "grow" then
        total_seeded = total_seeded + 1
        cycle_grown = cycle_grown + 1
    elseif a == "decay" then
        total_decayed = total_decayed + 1
        cycle_decay = cycle_decay + 1
    elseif a == "seedsearch" then
        cycle_search = cycle_search + 1
    end
end

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

local function ore_at_position (surface, position)
    return 0 < surface.count_entities_filtered{position=position, 
                                               type="resource"}
end

local function get_tile_properties (surface, tile) 
    if not tile.valid then 
        return nil 
    end
    local props = {}
    local tileref = config.tree_tile_properties[tile.name]
    if tileref then
        for k,v in pairs (tileref) do
            props[k] = v
        end
    end
    local ore_on_tile = ore_at_position (surface, tile.position)
    for k,v in pairs (config.tree_tile_properties.default) do
        props[k] = props[k] or v
        if ore_on_tile then
            props[k] = props[k] * config.tree_tile_ore_modifiers[k]
        end
    end
    return props
end

local function get_tile_properties_position (surface, position)
    return get_tile_properties (surface, 
                                surface.get_tile (position.x, position.y))
end

local function populate_locales ()
    local x, y, chunk
    for _,player in pairs (game.players) do
        x, y = round (player.position.x / chunksize), 
               round (player.position.y / chunksize)
        for u = x-config.tree_chunk_radius, x+config.tree_chunk_radius do
            for v = y-config.tree_chunk_radius, y+config.tree_chunk_radius do
                chunk = {x=u, y=v}
                if not locales:has (chunk) then
                    locales:add_chunk (chunk)
                end
            end
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
        log_act ("decay")
    end
end

local function get_seeding_location (surface, tree)
    local dx, dy, p
    for _=1, config.seed_location_search_tries do
        log_act ("seedsearch")
        dx, dy = marsaglia ()
        p = {x = tree.position.x + dx, 
             y = tree.position.y + dy}
        if surface.can_place_entity{name=tree.name, 
                                    position=p, 
                                    force=tree.force}
        then
            return p
        end
    end
end

local function try_spawn (surface, tree)
    local p, t_props
    log_act ("mast")
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

local function seed_tree (surface, tree)
    if try_spawn (surface, tree) then
        log_act ("grow")
    end
end

local function kill_tree (surface, tree, trees, i)
    local position, force = {x=tree.position.x, y=tree.position.y}, tree.force
    tree.destroy ()
    table.remove (trees, i)
    surface.create_entity{name=dead_tree_names[math.random (#dead_tree_names)],
                          position=position,
                          force=force}
    log_act ("kill")
end

local function update_chunk_trees (surface, chunk)
    local trees = get_trees_in_chunk (surface, chunk)
    if #trees == 0 then 
        return 
    end
    local maxtrees = #trees*config.tree_chunk_population_fraction
    maxtrees = math.random (math.min (#trees, math.ceil (maxtrees)))
    if config.enable_debug_window then
        cycle_trees = maxtrees
    end
    for _=1, maxtrees do
        local i = math.random (#trees)
        local tree = trees[i]
        local t_props = get_tile_properties_position (surface, tree.position)
        if eqany (tree.name, dead_tree_names) then
            try_decompose (t_props.decay, tree, trees, i)
        elseif math.random () < t_props.mast then
            seed_tree (surface, tree)
        elseif math.random () < t_props.death then
            kill_tree (surface, tree, trees, i)
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
    ui.add{type="label",name="total_live"}
    ui.add{type="label",name="total_dead"}
    ui.add{type="label",name="grown"}
    ui.add{type="label",name="killed"}
    ui.add{type="label",name="decayed"}
    ui.add{type="label",name="chunks"}
    ui.add{type="label",name="treecount"}
    ui.add{type="label",name="cycleseed"}
    ui.add{type="label",name="cyclesearch"}
    ui.add{type="label",name="cyclegrown"}
    ui.add{type="label",name="cyclekill"}
    ui.add{type="label",name="cycledecay"}
end

local function update_trees_gui (ui)
    ui.total.caption = "Trees Total: "..total_alive+total_dead
    ui.total_live.caption = "Alive: "..total_alive
    ui.total_dead.caption = "Dead: "..total_dead
    ui.grown.caption = "Grown: " .. total_seeded
    ui.killed.caption = "Died: " .. total_killed
    ui.decayed.caption = "Decayed: " .. total_decayed
    ui.chunks.caption = "chunks: " .. locales:get_count ()
    ui.treecount.caption = "touched: " .. cycle_trees
    ui.cycleseed.caption = "masted: " .. cycle_seed
    ui.cyclesearch.caption = "searched: " .. cycle_search
    ui.cyclegrown.caption = "grown: " .. cycle_grown
    ui.cyclekill.caption = "killed: " .. cycle_kill
    ui.cycledecay.caption = "decayed: " .. cycle_decay
end

-- =================
-- === LOOP/HOOK ===
-- =================

local function on_tick(event)
    if game.tick % config.tree_update_interval == 0 then
        local surface = game.surfaces[1]
        populate_locales ()
        if config.enable_debug_window then
            cycle_search, cycle_trees, cycle_seed, cycle_grown, cycle_kill, cycle_decay = 0,0,0,0,0,0
        end
        update_chunk_trees (surface, locales:get_random_chunk ())
    
        if config.enable_debug_window then
            total_alive = count_trees (tree_names) 
            total_dead = count_trees (dead_tree_names)
            if not game.players[1].gui.left.trees then
                init_trees_gui ()
            end
            update_trees_gui (game.players[1].gui.left.trees)
        end
    end
end

-- Register event handlers
script.on_event(defines.events.on_tick, function(event) on_tick(event) end)

