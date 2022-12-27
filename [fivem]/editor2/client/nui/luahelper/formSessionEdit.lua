RegisterNUICallback('formSessionEdit.remove', function(post)
    local session = GetSessionFromId(post.id)
    if not session then return end

    TriggerServerEvent('session:requestRemove', post)
end)

RegisterNUICallback('formSessionEdit.save', function(post)
    TriggerServerEvent('session:requestUpdate', post)
end)
