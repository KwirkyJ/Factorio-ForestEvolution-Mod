---Object-like structure for the storing and and random-access of
---"Chunk" positions.

local locales_has, locales_get_count
local locales_add_chunk, locales_get_random_chunk

---Create new locales "object" 
---@return Locales table-object-structure
local function init_locales ()
    return {_n = 0, 
            _flat = {},
            add_chunk = locales_add_chunk,
            get_random_chunk = locales_get_random_chunk,
            get_count = locales_get_count,
            has = locales_has,
           }
end

---Add a Chunk to the structure
---@param chunk Chunk ({x=0, y=32}, e.g.)
locales_add_chunk = function (self, chunk)
    local row = self[chunk.x]
    if row then
        row[chunk.y] = true
    else
        self[chunk.x] = {[chunk.y] = true}
    end
    table.insert (self._flat, {x = chunk.x, y = chunk.y})
    self._n = self._n + 1
end

---Get count of chunks in structure
---@return number (integer)
locales_get_count = function (self)
    return self._n
end

---Get a random Chunk in the structure
---@return nil iff structure is empty; 
---        else a Chunk
locales_get_random_chunk = function (self)
    if self._n > 0 then
        return self._flat[math.random (self._n)]
    end
end

---Check whether structure has (contains) a Chunk
---@param chunk Chunk {x=0, y=32}, e.g.
---@return nil iff not in structure;
---        else true
locales_has = function (self, c)
    if not self[c.x] then 
        return nil 
    else
        return self[c.x][c.y]
    end
end

return {init_locales = init_locales,
       }

