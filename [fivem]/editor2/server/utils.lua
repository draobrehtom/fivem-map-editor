function ResetPlayerRoutingBucket(playerId)
    return SetPlayerRoutingBucket(playerId, 0)
end

function AddChatMessage(messageText, playerId, messageType)
    if type(messageText) ~= 'string' then return end

    local playerId = tonumber(playerId) or -1
    if playerId == -1 then messageText = '* ' .. messageText end

    TriggerClientEvent('chat:addMessage', playerId, {
        args = {messageText},
        color = (messageType and MESSAGE_COLOR_FROM_TYPE[messageType]) and
            MESSAGE_COLOR_FROM_TYPE[messageType] or {255, 255, 255}
    })
end
