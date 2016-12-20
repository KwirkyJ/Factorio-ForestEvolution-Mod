

-- round to nearest zero
-- !note! round(-0.5) -> -1
local function round (n)
    if n >= 0 then 
        return math.floor (n+0.5)
    else
        return math.ceil (n-0.5)
    end
end

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

return {round = round,
        marsaglia = marsaglia,
        eqany = eqany,
       }

