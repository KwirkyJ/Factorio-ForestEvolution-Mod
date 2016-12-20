local utils = require "./utils"
local round, marsaglia, eqany = utils.round, utils.marsaglia, utils.eqany

-- === TEST ROUND ===
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

-- === TEST MARSAGLIA ===
local a, b = marsaglia ()
assert (type (a) == "number" and type (b) == "number", "returns random numbers")

-- === TEST EQANY ===
assert (eqany (3, {2,3,4}), "3 present")
assert (not eqany (5, {2,3,4}), "5 absent")
assert (not eqany (4, {[1]=3, [3]=4}), "sparse, interrupted array")
assert (not eqany (2, {[1]=true, [2]=true, [3]=true}), "2 not in values")
assert (not eqany (2, {["a"]=2}), "associative table")

print ("=== TESTS PASSED ===")

