local _TriggerEvent = TriggerEvent

function TriggerEvent(eventName, ...)
    local args = {...}
    
    local valid = true
    for k, v in pairs(args) do
        if type(v) == 'function' then valid = false break end
    end
    if valid then NUI.CallEvent(eventName, args) end

    return _TriggerEvent(eventName, ...)
end
