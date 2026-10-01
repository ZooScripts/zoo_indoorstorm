Config = {}

-- How strongly the storm (thunder, rain and wind) is turned down, from 0 to
-- 100. 100 is the whole mix: the storm is still heard, much quieter and
-- muffled. 0 leaves the storm as loud as outside.
Config.Inside  = 100   -- inside a house: a roof overhead and walls around
Config.Shelter = 100   -- under a low roof: a tent, a porch, an awning

-- /stormtest gives the player who types it a thunderstorm of their own, to
-- try the script out; typed again, their weather comes back.
-- false removes the command.
Config.TestCommand = true
