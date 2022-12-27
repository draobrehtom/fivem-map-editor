RegisterNetEvent('session:requestRemove')
AddEventHandler('session:requestRemove', function(post)
    local session = GetSessionFromId(tonumber(post.id))
    if not session then return end

    session:Delete()
    SendSessionsToPlayer(-1)
end)
