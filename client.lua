-- zoo_indoorstorm -- the storm heard from indoors.
--
-- Inside a house or under a low roof, the storm sounds the way it would
-- through walls or a tent: thunder, rain and wind are turned down by two
-- audio scenes of our own (audio/zoo_storm_mix.dat40.rel). Nothing is seen
-- to change: the weather, the falling rain and the lightning stay as they
-- are, and only this player hears the difference.
--
-- The place is one of three:
--   outside  no roof, or a high roof with few walls around it (a bridge)
--   inside   a roof over the head and walls on most sides
--   shelter  a low roof right over the head, walls or not (a tent, a porch)
-- The game's own rooms decide nothing: some of them let the whole storm in.
--
-- Between storms the script only glances at the weather every few seconds.
-- A player running past a porch or a tent is not taking shelter: while
-- they move faster than a walk they are only ever let out, never taken in,
-- and outside nothing is looked at until they slow down.
--
-- How strongly each place turns the storm down, and whether /stormtest
-- exists, are set in config.lua. /stormtest brings a thunderstorm for this
-- player only, to try it out; used again, the weather is given back.

local IDLE_MS      = 3000    -- how often the weather is looked at between storms
local CHECK_MS     = 500     -- how often the place is checked during a storm
local MOVED        = 0.5     -- metres moved before the place is looked at again
local PASSING      = 2.5     -- metres a second; faster than this is passing by, not taking shelter
local ROOF_UP      = 25.0    -- how high a roof is looked for, metres
local WALL_REACH   = 8.0     -- how far a wall is looked for, metres
local WALL_RAYS    = 8       -- directions looked in around the player
local WALLS_NEEDED = 5       -- walls out of WALL_RAYS that make it a room
local SHELTER_ROOF = 4.0     -- a roof this close over the head is shelter, walls or not
local SAME_CHECKS  = 2       -- checks in a row that must agree before a change
local RAIN_NEEDED  = 0.05    -- rain at or above this level is a storm
local RAY_FLAGS    = 1 + 16  -- map and objects; never foliage, so a tree is no roof
local NEAR_REACH   = 15.0    -- how far around the player objects are listed, metres
local NEAR_EVERY   = 2000    -- how often that list is renewed, ms
local CANOPY_AREA  = 3.0     -- square metres seen from above that an object needs to be a roof
local CANOPY_GAP   = 0.2     -- how far above the head the top of a cloth roof must be, metres

-- weathers that are a storm even with little rain: thunder, or a loud wind
local STORMS = { 'THUNDER', 'THUNDERSTORM', 'HURRICANE', 'HAIL', 'SLEET',
                 'BLIZZARD', 'GROUNDBLIZZARD', 'WHITEOUT', 'SANDSTORM' }

-- the scene for each place, as named in the mix file
local SCENE = { inside = 'zoo_storm_inside_scene', shelter = 'zoo_storm_shelter_scene' }

local stormy = {}
for _, w in ipairs(STORMS) do stormy[GetHashKey(w)] = true end

local function storming()
    local rain = Citizen.InvokeNative(0x931B5F4CC130224B, Citizen.ResultAsFloat()) or 0.0  -- GET_RAIN_LEVEL
    if rain >= RAIN_NEEDED then return true end
    local prev = Citizen.InvokeNative(0x4BEB42AEBCA732E9, Citizen.ResultAsInteger())       -- _GET_PREV_WEATHER_TYPE_HASH_NAME
    local nxt = Citizen.InvokeNative(0x51021D36F62AAA83, Citizen.ResultAsInteger())        -- _GET_NEXT_WEATHER_TYPE_HASH_NAME
    return (stormy[prev] or stormy[nxt]) == true
end

-- the share of each scene applied, from config.lua: its patch reads the
-- 'apply' variable, so 1.0 is the whole mix and 0.0 none of it
local function share(pct)
    return math.max(0.0, math.min(100.0, tonumber(pct) or 100.0)) / 100.0
end
local STRENGTH = {
    [SCENE.inside]  = share(Config.Inside),
    [SCENE.shelter] = share(Config.Shelter),
}

-- one scene runs at a time; the scenes fade in and out on their own. A
-- scene set to 0 is never started.
local playing = nil
local function play(name)
    if name and STRENGTH[name] <= 0.0 then name = nil end
    if name == playing then return end
    if playing then Citizen.InvokeNative(0xDFE8422B3B94E688, playing) end  -- STOP_AUDIO_SCENE
    playing = name
    if name then
        Citizen.InvokeNative(0x013A80FC08F6E4F2, name)                          -- START_AUDIO_SCENE
        Citizen.InvokeNative(0xEF21A9EF089A2668, name, 'apply', STRENGTH[name])  -- SET_AUDIO_SCENE_VARIABLE
    end
end

local function probe(a, b, ped)
    return StartShapeTestLosProbe(a.x, a.y, a.z, b.x, b.y, b.z, RAY_FLAGS, ped, 7)
end

local function outcome(h)
    for _ = 1, 10 do
        local state, hit, at = GetShapeTestResult(h)
        if state ~= 1 then return (hit == true or hit == 1), at end
        Wait(0)
    end
    return false, nil
end

-- A cloth roof (an awning, a tent's canvas, anything that moves in the
-- wind) has nothing a ray can hit. So an object counts as a low roof when
-- the player stands within its outline seen from above, its top is over
-- the head by CANOPY_GAP to SHELTER_ROOF, and it is wide enough to be a
-- roof at all (a lamp or a sign is not).
local near, nearAt = {}, -NEAR_EVERY
local dims = {}   -- model -> its box and the area it covers
local function canopyOver(head)
    local now = GetGameTimer()
    if now - nearAt >= NEAR_EVERY then
        nearAt, near = now, {}
        for _, obj in ipairs(GetGamePool('CObject')) do
            if #(GetEntityCoords(obj) - head) <= NEAR_REACH then near[#near + 1] = obj end
        end
    end
    for _, obj in ipairs(near) do
        if DoesEntityExist(obj) then
            local model = GetEntityModel(obj)
            local d = dims[model]
            if not d then
                local mn, mx = GetModelDimensions(model)
                d = { mn = mn, mx = mx, area = (mx.x - mn.x) * (mx.y - mn.y) }
                dims[model] = d
            end
            if d.area >= CANOPY_AREA then
                local p = GetOffsetFromEntityGivenWorldCoords(obj, head.x, head.y, head.z)
                local over = d.mx.z - p.z
                if p.x >= d.mn.x and p.x <= d.mx.x and p.y >= d.mn.y and p.y <= d.mx.y
                   and over >= CANOPY_GAP and over <= SHELTER_ROOF then
                    return true
                end
            end
        end
    end
    return false
end

-- one look around: a roof over the head and the walls around the player
local function look(ped, c)
    local head = vector3(c.x, c.y, c.z + 0.7)
    local chest = vector3(c.x, c.y, c.z + 0.3)
    local roofRay = probe(head, vector3(head.x, head.y, head.z + ROOF_UP), ped)
    local wallRays = {}
    for i = 1, WALL_RAYS do
        local a = (i - 1) * (2.0 * math.pi / WALL_RAYS)
        wallRays[i] = probe(chest, vector3(chest.x + math.cos(a) * WALL_REACH,
                                           chest.y + math.sin(a) * WALL_REACH, chest.z), ped)
    end
    Wait(0)
    local hit, at = outcome(roofRay)
    local roofAt = hit and at and (at.z - head.z) or nil
    local walls = 0
    for i = 1, WALL_RAYS do
        if outcome(wallRays[i]) then walls = walls + 1 end
    end
    if roofAt and walls >= WALLS_NEEDED then return 'inside' end
    if roofAt and roofAt <= SHELTER_ROOF then return 'shelter' end
    if canopyOver(head) then return 'shelter' end
    return 'outside'
end

CreateThread(function()
    local place, pending, agree, lastAt = 'outside', nil, 0, nil
    while true do
        if not storming() then
            play(nil)
            place, pending, agree, lastAt = 'outside', nil, 0, nil
            Wait(IDLE_MS)
        else
            local ped = PlayerPedId()
            local at = GetEntityCoords(ped)
            local passing = GetEntitySpeed(ped) > PASSING
            if passing and place == 'outside' then
                pending, agree = nil, 0
            -- a player standing still keeps their place, unless a change
            -- is still waiting to be confirmed
            elseif pending or not lastAt or #(at - lastAt) >= MOVED then
                lastAt = at
                local now = look(ped, at)
                if now == place then
                    pending, agree = nil, 0
                elseif now == pending then
                    agree = agree + 1
                else
                    pending, agree = now, 1
                end
                if pending and agree >= SAME_CHECKS then
                    place, pending, agree = pending, nil, 0
                end
            end
            play(SCENE[place])
            Wait(CHECK_MS)
        end
    end
end)

-- the test storm: through weathersync when it runs (it would put the
-- server's weather straight back otherwise), else set on the game directly
local testStorm = nil   -- the weather to go back to, or false with weathersync; nil when off
local function weathersync()
    return GetResourceState('weathersync') == 'started'
end
local function setWeather(hash, seconds)
    Citizen.InvokeNative(0x59174F1AFE095B5A, hash, true, false, true, seconds + 0.0, false)  -- SET_WEATHER_TYPE
end
local function giveWeatherBack()
    if testStorm == false then
        pcall(function() exports['weathersync']:setSyncEnabled(true) end)
    elseif testStorm then
        setWeather(testStorm, 5.0)
    end
    testStorm = nil
end

if Config.TestCommand then
    RegisterCommand('stormtest', function()
        if testStorm ~= nil then
            giveWeatherBack()
        elseif weathersync() then
            testStorm = false
            pcall(function() exports['weathersync']:setMyWeather('THUNDERSTORM', 5.0, false) end)
        else
            testStorm = Citizen.InvokeNative(0x51021D36F62AAA83, Citizen.ResultAsInteger())  -- _GET_NEXT_WEATHER_TYPE_HASH_NAME
            setWeather(GetHashKey('THUNDERSTORM'), 5.0)
        end
    end, false)
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    play(nil)
    giveWeatherBack()
end)
