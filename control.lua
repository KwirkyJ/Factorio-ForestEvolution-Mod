require "config"
-- inherits: 
-- tree_expansion_frequency
-- enable_debug_window
-- max_trees
-- tree_decrease_start"

local freq = 16
local freq2 = freq ^ 2
local totalgen = 0
local chunksize = 32
--local original_tree_count = 0

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
    "tree-09-red"
}

local tree_unfriendly_tile_names = {
    ["out-of-map"] = true,
    ["deepwater"] = true,
    ["deepwater-green"] = true,
    ["water"] = true,
    ["water-green"] = true,
    ["grass"] = true,
    ["sand"] = true,
    ["sand-dark"] = true,
    ["stone-path"] = true,
    ["concrete"] = true,
    ["hazard-concrete-left"] = true,
    ["hazard-concrete-right"] = true,
    ["dirt"] = true,
    ["dirt-dark"] = true,
}

local function fmod(a,m)
    return a - math.floor(a / m) * m
end

local function can_grow_on_tile (tile)
    if not tile.valid then
        return false
    end
    --for i=1, #tree_unfriendly_tile_names do
    --    if tile.name == tree_unfriendly_tile_names[i] then
    for unfriendly in pairs (tree_unfriendly_tile_names) do
        if tile.name == unfriendly then
            return false
        end
    end
    return true
end

local function eqany(a,b)
    for i = 1,#b do
        if a == b[i] then
            return true
        end
    end
    return false
end


local shuffle, shsrc = {}, {}
--[[
for i = 1,freq do
    for j = 1,freq do
        shuffle_src[i * freq + j] = i * freq + j
    end
end
--]]
-- formerly raster-scan above; nested loops are unnecessary
for i=1, freq2 do shsrc[i] = true end

for i in pairs(shsrc) do 
    -- pairs() return order stochastic/undefined; thus suitably random
    table.insert(shuffle, i)
end

shsrc = nil


-- Playermap is a 2-D map that indicates approximate location of player owned
-- entities. It is used for optimizing the algorithm to quickly determine 
-- proximity of the player's properties which would be of player's interest.
-- Because LuaSurface.count_entities_filtered() is slow for large area, 
-- we want to call it as few times as possible.
-- This is similar in function as chunks, but playermap element is greater than
-- chunks, because it's not good idea to make scripting languages like Lua
-- calculating large set of data. Also we only need very rough estimation, so
-- chunk granularity is too fine for us.
local playermap = {}
--local playermap_freq = 4

local function update_player_map(m, surface)
    local mm = m % #shuffle + 1
    local mx = shuffle[mm] % freq
    local my = math.floor(shuffle[mm] / freq)
    for chunk in surface.get_chunks() do
        if fmod(chunk.x + mx, freq) == 0 and fmod(chunk.y + my, freq) == 0 and
            0 < surface.count_entities_filtered{area = {{chunk.x * chunksize, chunk.y * chunksize}, {(chunk.x + 1) * chunksize, (chunk.y + 1) * chunksize}}, force = "player"} then
            local px = math.floor(chunk.x / 4)
            local py = math.floor(chunk.y / 4)
            if playermap[py] == nil then
                playermap[py] = {}
            end
            playermap[py][px] = m
        end
    end
end

-- Return {rows, active, visited} playermap chunks
local function countPlayerMap(m)
    local ret = {0,0,0}
    for i,v in pairs(playermap) do
        ret[1] = ret[1] + 1
        for j,w in pairs(v) do
            if m < w + freq2 then
                ret[2] = ret[2] + 1
            end
            ret[3] = ret[3] + 1
        end
    end
    return ret
end

-- LuaSurface.count_entities_filtered() is slow.
-- LuaForce.get_entity_count() is much faster, but it needs 
-- entity name argument, not type so we must repeat it for all types of trees.
local function count_trees()
    local c=0
    for i=1,#tree_names do
        c = c + game.forces.neutral.get_entity_count(tree_names[i])
    end
    return c
end

--TODO: can probably be futher optimized? nest fors and ifs is messy anyway
local function is_near_playermap (chunk, m)
    local px = math.floor(chunk.x / 4)
    local py = math.floor(chunk.y / 4)
    for y=-1,1 do
        if playermap[py + y] then
            for x=-1,1 do
                if playermap[py + y][px + x] and 
                   m < playermap[py + y][px + x] + freq2 
                then
                    return true
                end
            end
        end
    end
    return false
end

local function grow_trees(m)
        local num = 0
        local allnum = 0
        local str = ""
        local mm = m % #shuffle + 1
        local mx = shuffle[mm] % freq
        local my = math.floor(shuffle[mm] / freq)
        local surface = game.surfaces[1]
        local totalc = 0
        for chunk in surface.get_chunks() do
            allnum = allnum + 1

            -- Grow trees on only the player's proximity since the player is not
            -- interested nor has means to observe deep in the unknown region.
            if fmod(chunk.x + mx, freq) == 0 and 
               fmod(chunk.y + my, freq) == 0 and
               is_near_playermap (chunk, m) 
            then
                local area = {{chunk.x * chunksize, chunk.y * chunksize}, {(chunk.x + 1) * chunksize, (chunk.y + 1) * chunksize}}
                local c = surface.count_entities_filtered{area = area, type = "tree"}
                totalc = totalc + c
                if 0 < c then
                    local trees = surface.find_entities_filtered{area = area, type = "tree"}
                    if 0 < #trees then
                        local nondeadtree = false
                        local tree = trees[math.random(#trees)]
                        -- Draw trees until we get a non-dead tree.
                        for try = 1,10 do
                            if not eqany(tree.name, {"dead-tree", "dry-tree", "dead-grey-trunk", "dry-hairy-tree", "dead-dry-hairy-tree"}) then
                                nondeadtree = true
                                break
                            end
                        end
                        if nondeadtree then
                            local newpos
                            local success = false
                            -- Try until randomly generated position does not block something.
                            for try = 1,10 do
                                newpos = {tree.position.x + (math.random(-5,5)), tree.position.y + (math.random(-5,5))}
                                local newarea = {{newpos[1] - 1, newpos[2] - 1}, {newpos[1] + 1, newpos[2] + 1}}
                                local newarea2 = {{newpos[1] - 2, newpos[2] - 2}, {newpos[1] + 2, newpos[2] + 2}}
                                if 0 == surface.count_entities_filtered{area = newarea, type = "tree"} and
                                can_grow_on_tile (surface.get_tile (newpos[1], newpos[2])) and
                                0 == surface.count_entities_filtered{area = newarea2, force = "player"} and
                                surface.can_place_entity{name = tree.name, position = newpos, force = tree.force} then
                                    success = true
                                    break
                                end
                            end
                            if success then
                                num = num + 1
                                surface.create_entity{name = tree.name, position = newpos, force = tree.force}
                            end
                        end
                    end
                end
            end
        end
        totalgen = totalgen + num
    end

local function init_trees_gui ()
    game.players[1].gui.left.add{type="frame", name="trees", caption="Trees", direction="vertical"}
    -- original_tree_count = game.surfaces[1].count_entities_filtered{area={{-10000,-10000},{10000,10000}},type="tree"}
    game.players[1].gui.left.trees.add{type="label",name="m"}
    game.players[1].gui.left.trees.add{type="label",name="total"}
    game.players[1].gui.left.trees.add{type="label",name="count"}
    game.players[1].gui.left.trees.add{type="label",name="playermap"}
end

local function update_trees_gui (trees_gui, cycle_state, tree_count, generated, playermap_count)
    trees_gui.m.caption = cycle_state
    trees_gui.total.caption = "Total trees: " .. tree_count
    trees_gui.count.caption = "Added trees: " .. generated
    trees_gui.playermap.caption = "Playermap: " .. playermap_count[1] .. "/" .. playermap_count[2] .. "/" .. playermap_count[3]
end

function on_tick(event)
    -- First, cache player map data by searching player owned entities.
    if game.tick % tree_expansion_frequency == 0 then
        local m = math.floor(game.tick / tree_expansion_frequency)
        update_player_map(m, game.surfaces[1])
    end

    -- Delay the loop as half a phase of update_player_map to reduce
    -- 'petit-freeze' duration as possible.
    if math.floor(game.tick + tree_expansion_frequency / 2) % tree_expansion_frequency == 0 then
        local m = math.floor(game.tick / tree_expansion_frequency)

        -- As number of trees grows, the growth rate decreases, maxes at max_trees.
        local numTrees = count_trees()
        if numTrees < max_trees * tree_decrease_start or
           numTrees < max_trees * (tree_decrease_start + math.random() * (1 - tree_decrease_start)) 
        then
            grow_trees(m)
        end

        if enable_debug_window then
            if not game.players[1].gui.left.trees then
                init_trees_gui ()
            end
            update_trees_gui (game.players[1].gui.left.trees,
                              m % #shuffle .. '/' .. #shuffle,
                              count_trees (),
                              totalgen,
                              countPlayerMap (m))
        end
    end
end

-- Register event handlers
script.on_event(defines.events.on_tick, function(event) on_tick(event) end)
