-- Client request: update/edit session
RegisterNetEvent('session:requestUpdate')
AddEventHandler('session:requestUpdate', function(post)
    local session = GetSessionFromId(tonumber(post.id))
    if not session then return end

    local details = SafeSessionConfig(post.details)
    printlog('session:requestUpdate', post.id, details)
    for key in pairs(details) do session:Set(key, post.details[key]) end

    session:Save()
    session:Fetch()
    SendSessionsToPlayer(-1)
end)
