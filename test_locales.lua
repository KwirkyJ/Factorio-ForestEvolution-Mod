local lcl = require './locales'

locales = lcl.init_locales ()
assert (locales:get_count () == 0)
assert (not locales:has ({x=0, y=0}))

-- add chunks
locales:add_chunk ({x=  0, y= 0})
locales:add_chunk ({x=  0, y=64})
locales:add_chunk ({x= 96, y= 0})
locales:add_chunk ({x=-32, y= 0})

-- verify state and behaviors
assert (locales:get_count () == 4)
assert (locales:has ({x=0, y=0}))
assert (locales:has ({x=96, y=0}))
assert (locales:has ({x=0, y=64}))
assert (not locales:has ({x=32, y=32}))
for _=1, 10 do
    assert (locales:has (locales:get_random_chunk ()))
end

-- test duplicate addition
assert (locales:get_count () == 4)
assert (locales:has ({x=96, y=0}))
locales:add_chunk ({x=96, y=0})
assert (locales:get_count () == 5)
assert (locales:has ({x=96, y=0}))

print ("=== TESTS SUCCESSFUL ===")

