_G.CURRENT_RESOURCE_NAME = GetCurrentResourceName()
_G.COLLECTION_PLAYERS = 'players'
_G.COLLECTION_SESSIONS = 'sessions'
_G.COLLECTION_MAPS = 'maps'
_G.MONGO = exports.mongodb

local IS_CLIENT = type(PlayerPedId) == 'function'

function table.copy(tbl)
    if type(tbl) == 'table' then
        local copy = {}
        for k, v in pairs(tbl) do
            if type(v) == 'table' then
                copy[k] = table.copy(v)
            else
                copy[k] = v
            end
        end
        return copy
    end
    return nil
end

function protect(t)
    local fn = function(_, k)
        error("Key `" .. tostring(k) .. "` is not supported.")
    end
    return setmetatable(t, {__index = fn, __newindex = fn})
end

local PROMISE = protect({
    PENDING = 0,
    RESOLVING = 1,
    REJECTING = 2,
    RESOLVED = 3,
    REJECTED = 4
})
_G.PROMISE = table.copy(PROMISE)
protect(PROMISE)

local PROTECTED_ENTITY_KEYS = protect({
    ['id'] = true,
    ['objectHandler'] = true,
    ['modelHash'] = true,
    ['select'] = true,
    ['drag'] = true
})
_G.PROTECTED_ENTITY_KEYS = table.copy(PROTECTED_ENTITY_KEYS)
protect(PROTECTED_ENTITY_KEYS)

local KEYS_TO_NOT_EXPORT = protect({
    ['id'] = true,
    ['objectHandler'] = true,
    ['modelHash'] = true,
    ['rotationType'] = true,
    ['controllerId'] = true,
    ['select'] = true,
    ['drag'] = true
})
_G.KEYS_TO_NOT_EXPORT = table.copy(KEYS_TO_NOT_EXPORT)
protect(KEYS_TO_NOT_EXPORT)

MESSAGE_COLOR_FROM_TYPE = {
    ['error'] = {255, 0, 0},
    ['information'] = {0, 155, 255},
    ['success'] = {0, 255, 0},
    ['warning'] = {255, 255, 0}
}

local WEATHER_FROM_NUMBER = protect({
    [1] = 'BLIZZARD',
    [2] = 'CLEAR',
    [3] = 'CLEARING',
    [4] = 'CLOUDS',
    [5] = 'EXTRASUNNY',
    [6] = 'FOGGY',
    [7] = 'HALLOWEEN',
    [8] = 'NEUTRAL',
    [9] = 'OVERCAST',
    [10] = 'RAIN',
    [11] = 'SMOG',
    [12] = 'SNOW',
    [13] = 'SNOWLIGHT',
    [14] = 'THUNDER',
    [15] = 'XMAS'
})
_G.WEATHER_FROM_NUMBER = table.copy(WEATHER_FROM_NUMBER)
protect(WEATHER_FROM_NUMBER)

local function ArrayToString(array)
    if type(array) ~= 'table' then return nil end
    local str = '{'
    for key, value in next, array do
        if next(array, key) ~= nil then
            str = str .. tostring(key) .. ':' .. tostring(value) .. ', '
        else
            str = str .. tostring(key) .. ':' .. tostring(value)
        end
    end
    return str .. '}'
end

function printlog(...)
    local args = {...}
    local str = ''
    for k, arg in next, args do
        local arg = type(arg) == 'table' and ArrayToString(arg) or arg
        if next(args, k) ~= nil then
            str = str .. tostring(arg) .. ', '
        else
            str = str .. tostring(arg)
        end
    end
    return print((IS_CLIENT and '<client> ' or '') .. str)
end

function RGBToHex(r, g, b)
    local rgb = (r * 0x10000) + (g * 0x100) + b
    return string.format("%x", rgb)
end
