function CreateSession(post, callback)
    if type(post) ~= 'table' or type(post.name) ~= 'string' then
        printlog('CreateSession',
                 'Action aborted. Invalid or missing argument(s).', post)
        return nil
    end

    local session = Session:New(post)
    if not session then return nil end

    local owner = GetPlayerInstanceFromIdentifier(post.ownerId)
    if owner then
        session:Set('ownerName', owner:Get('playerName') or 'Unknown')
    end
    
    session:Save(callback)
    -- backup maps
    MONGO:update({
        collection = COLLECTION_MAPS,
        query = {ownerId = post.ownerId},
        update = {["$set"] = {session = session.id}}
    })
    return session
end

-- Client request: create session
RegisterNetEvent('session:requestCreate')
AddEventHandler('session:requestCreate', function(post)
    local playerId = tonumber(source)
    local playerInstance = GetPlayerInstanceFromPlayerId(playerId)
    local playerUId = playerInstance and playerInstance.uId or nil
    if not playerUId then
        TriggerClientEvent('session:createCallback', playerId, 1)
        TriggerClientEvent('editor:addNotification', playerId, {
            title = 'Session Create',
            message = 'We could not process your request, because you have no FiveM identifier set.',
            icon = 'circle'
        })
        printlog('session:requestCreate',
                 'Action aborted. Failed to get source player identifier.')
        return
    end

    printlog('session:requestCreate', playerUId, post)
    MONGO:find({
        collection = COLLECTION_SESSIONS,
        query = {ownerId = playerUId},
        options = {projection = {_id = 0}}
    }, function(success, result)
        if not success then return end

        if #result > 0 then
            TriggerClientEvent('session:createCallback', playerId, 1, session)
            TriggerClientEvent('editor:addNotification', playerId, {
                title = 'Session Create',
                message = 'You already own a session.',
                icon = 'circle'
            })
            printlog('session:requestCreate', 'Action aborted. Player ' ..
                         playerUId .. ' owns a session already.')
            return
        end

        -- Attempt to create session
        local session = CreateSession({
            name = post.name,
            maximumSlots = post.maximumSlots,
            password = post.password,
            ownerId = playerUId
        }, function(session)
            if not session then
                TriggerClientEvent('session:createCallback', playerId, 1)
                TriggerClientEvent('editor:addNotification', playerId, {
                    title = 'Session Create',
                    message = 'Could not create session. Make sure you are logged into FiveM.',
                    icon = 'circle'
                })
                return
            end

            TriggerClientEvent('session:createCallback', playerId, 0, session)
        end)
    end)
end)
