Forest Evolution -- A Mod for Factorio
========================================

This is a mod for a game called Factorio, compatible with version 0.14.
This mod will make trees reproduce, die, and decompose as the game progresses.
Evolution is tile-dependent; while work went into tuning the properties as
provided, they are accessible in config.lua for adjustment.

* The algorithm keeps a cache of the player's movements; to prevent 
modification of the entire map, only regions near the player's activities 
(configurable in config.lua) are selected for updating trees (if any) within 
their area.

* The provided configuration prevents trees from spawning on concrete and 
stone paths--pave your base to prevent them from encroaching.

* Debug mode shows information relevant to the mod's operations, but some may 
find it cluttered.

* _**Multiplayer is untested.**_

Now get your flamethrower ready!
