function AddChatMessage(messageText, playerId)
    if type(messageText) ~= 'string' then return end

    local playerId = tonumber(playerId) or -1
    TriggerClientEvent('chat:addMessage', playerId,
                       {args = {messageText}, color = {255, 255, 255}})
end
