_G.CURRENT_RESOURCE_NAME = GetCurrentResourceName()

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
    return print((IS_CLIENT and '[CLIENT] ' or '[SERVER] ') .. str)
end
