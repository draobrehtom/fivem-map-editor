function StoreEntityHandlerId(entityId, entityEId)
    if type(entityId) ~= 'number' or type(entityEId) ~= 'string' then
        printlog('StoreEntityHandlerId', 'Action aborted. Invalid or missing argument(s).', entityId, entityEId)
        return
    end

    Editor.handlerId[entityId] = entityEId
end

function ClearEntityHandlerId(entityId)
    if not entityId or not Editor.handlerId[entityId] then return end

    Editor.handlerId[entityId] = nil
end

function AddChatMessage(messageText, messageType)
    if type(messageText) ~= 'string' then return end

    TriggerEvent('chat:addMessage', {
        args = {messageText},
        color = (messageType and MESSAGE_COLOR_FROM_TYPE[messageType]) and
            MESSAGE_COLOR_FROM_TYPE[messageType] or {255, 255, 255}
    })
end

function AddNotification(titleText, messageText)
    TriggerEvent('editor:addNotification',
                 {title = titleText, message = messageText})
end
