local lcl = require './locales'

local locales = lcl.init_locales ()
assert (locales:get_count () == 0)
assert (not locales:has ({x=0, y=0}))

-- add chunks
locales:add ({x=  0, y= 0})
locales:add ({x=  0, y=64})
locales:add ({x= 96, y= 0})
locales:add ({x=-32, y= 0})

-- verify state and behaviors
assert (locales:get_count () == 4)
assert (locales:has ({x=0, y=0}))
assert (locales:has ({x=96, y=0}))
assert (locales:has ({x=0, y=64}))
assert (not locales:has ({x=32, y=32}))
for _=1, 20 do
    assert (locales:has (locales:get_random ()))
end

-- test tostring: in order of addition
assert (tostring (locales) == "(0, 0), (0, 64), (96, 0), (-32, 0)", 
        tostring (locales))

-- test duplicate addition
assert (locales:get_count () == 4)
assert (locales:has ({x=96, y=0}))
locales:add ({x=96, y=0})
assert (locales:get_count () == 5)
assert (locales:has ({x=96, y=0}))

assert (tostring (locales) == "(0, 0), (0, 64), (96, 0), (-32, 0), (96, 0)",
        tostring (locales))

print ("=== TESTS SUCCESSFUL ===")

