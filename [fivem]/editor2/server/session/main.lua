_G.PlayerSessionId = {}
local AwaitingDatabaseConnection = true

local function InitSessions()
    MONGO:find({
        collection = COLLECTION_SESSIONS,
        query = {},
        options = {projection = {_id = 0}}
    }, function(success, result)
        if not success then return end
        for _, document in pairs(result) do CreateSession(document) end
        AwaitingDatabaseConnection = nil
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == CURRENT_RESOURCE_NAME then
        if not MONGO:isConnected() then
            return printlog(
                       'Server is not connected to the database, awaiting connection to load sessions.')
        end
        InitSessions()
    end
end)

AddEventHandler('onDatabaseConnect', function(dbName)
    if AwaitingDatabaseConnection and dbName == 'editor2' then
        printlog('Server is now connected to the database, loading sessions.')
        InitSessions()
    end
end)

-- update owned sessions of player once they are 'logged in'
AddEventHandler('player:setup', function(uId, data)
    MONGO:find({
        collection = COLLECTION_SESSIONS,
        query = {ownerId = uId},
        options = {projection = {_id = 0}}
    }, function(success, result)
        if not success then return end

        for _, document in pairs(result) do
            local session = GetSessionFromId(document.id)
            if session then
                session:Set('ownerName',
                            GetPlayerName(GetPlayerIdFromIdentifier(uId)))
            end
        end
    end)
end)

AddEventHandler('editor:playerDropped', function(playerId, playerName)
    local playerSession = GetPlayerSession(playerId)
    if not playerSession then return end

    playerSession:RemovePlayer(playerId, playerName)
end)

local function HandlePlayerSessionJoin(playerId, sessionId, enteredPassword)
    playerId = tonumber(playerId)
    if not playerId then return end

    -- check if player is already in another session
    local playerSession = GetPlayerSession(playerId)
    if playerSession then
        TriggerClientEvent('editor:addNotification', playerId, {
            title = 'Session',
            message = 'You must leave your current session before joining another.',
            icon = 'circle'
        })
        return
    end

    sessionId = tonumber(sessionId)
    if not sessionId then
        TriggerClientEvent('editor:addNotification', playerId, {
            title = 'Session',
            message = 'You must specify a session id. /join <session id>',
            icon = 'circle'
        })
        return
    end

    local session = GetSessionFromId(sessionId)
    if not session then
        TriggerClientEvent('editor:addNotification', playerId, {
            title = 'Session',
            message = 'Session was not found.',
            icon = 'circle'
        })
        return
    end

    local playerCanJoin = false
    local playerInstance = GetPlayerInstanceFromPlayerId(playerId)
    local playerUId = playerInstance and playerInstance.uId or nil
    if session.password and string.len(session.password) > 0 then
        if playerUId and session.ownerId and session.ownerId == playerUId then
            playerCanJoin = true

        else
            enteredPassword = type(enteredPassword) == 'string' and
                                  enteredPassword or -1
            if enteredPassword == -1 or enteredPassword ~= session.password then
                TriggerClientEvent('editor:addNotification', playerId, {
                    title = 'Session',
                    message = 'You have entered an invalid password.',
                    icon = 'circle'
                })
                return
            end
        end
    end

    if session.maximumSlots > 0 then
        if not canJoin and session:GetCurrentPlayerCount() >=
            session.maximumSlots then
            TriggerClientEvent('editor:addNotification', playerId, {
                title = 'Session',
                message = 'This session is full.',
                icon = 'circle'
            })
            return
        end
    end

    session:AddPlayer(playerId)
end

local function HandlePlayerSessionLeave(playerId)
    playerId = tonumber(playerId)
    if not playerId then return end

    local session = GetPlayerSession(playerId)
    if not session then
        TriggerClientEvent('editor:addNotification', playerId, {
            title = 'Session',
            message = 'You have not joined a session.',
            icon = 'circle'
        })
        return
    end

    session:RemovePlayer(playerId)
end

AddEventHandler('session:playerJoined', function(session, playerId)
    printlog('session:playerJoined', 'Player ' .. GetPlayerName(playerId) ..
                 ' joined session ' .. session.id)
    SetPlayerSession(playerId, session.id)
    AddChatMessage('You joined session ' .. session.name, playerId, 'success')

    local session = GetSessionFromId(session.id)
    if not session then return end

    session:AddChatMessage('Player ' .. tostring(session.players[playerId]) ..
                               ' joined this session.', 'information')
end)

AddEventHandler('session:playerLeft', function(session, playerId)
    printlog('session:playerLeft',
             'Player ' .. tostring(session.players[playerId]) ..
                 ' left session ' .. session.id)
    SetPlayerSession(playerId, -1)
    AddChatMessage('You left session ' .. session.name, playerId, 'error')

    local session = GetSessionFromId(session.id)
    if not session then return end

    session:AddChatMessage('Player ' .. tostring(session.players[playerId]) ..
                               ' left this session.')
end)

-- Client request: join
RegisterNetEvent('session:requestJoin')
AddEventHandler('session:requestJoin', function(sessionId, enteredPassword)
    HandlePlayerSessionJoin(source, sessionId, enteredPassword)
end)

-- Client request: leave
RegisterNetEvent('session:requestLeave')
AddEventHandler('session:requestLeave',
                function() HandlePlayerSessionLeave(source) end)

-- Command purpose: To join a session
-- If the source is > 0, then that means it must be a player.
RegisterCommand('join', function(source, args)
    local playerId = tonumber(source)
    if playerId > 0 then HandlePlayerSessionJoin(playerId, args[1], args[2]) end
end, true)

-- Command purpose: To leave current session
-- If the source is > 0, then that means it must be a player.
RegisterCommand('leave', function(source)
    local playerId = tonumber(source)
    if playerId > 0 then HandlePlayerSessionLeave(playerId) end
end, false)

RegisterNetEvent('editor:requestSessions')
AddEventHandler('editor:requestSessions',
                function() SendSessionsToPlayer(source) end)

-- map requests (save, load, unload)
-- save
RegisterNetEvent('session:requestSaveMap')
AddEventHandler('session:requestSaveMap', function(post)
    local playerId = tonumber(source)
    if type(post) ~= 'table' then return end

    local session = GetPlayerSession(playerId)
    if not session then return end

    printlog('session:requestSaveMap',
             'Player ' .. GetPlayerName(playerId) ..
                 ' requested to save map in session ' .. session.id .. ' as ' ..
                 tostring(post.name))
    session:SaveCurrentMap(post.name, post.meta)
end)

RegisterCommand('save', function(source, args)
    local playerId = tonumber(source)
    if playerId < 0 then return end

    local session = GetPlayerSession(playerId)
    if not session then return end

    session:SaveCurrentMap(nil, nil)
end, false)

-- load
RegisterNetEvent('session:requestLoadMap')
AddEventHandler('session:requestLoadMap', function(post)
    local playerId = tonumber(source)
    if type(post) ~= 'table' or type(post.name) ~= 'string' then return end

    local session = GetPlayerSession(playerId)
    if not session then return end

    printlog('session:requestLoadMap',
             'Player ' .. GetPlayerName(playerId) .. ' requested to load map ' ..
                 tostring(post.name) .. ' in session ' .. session.id)
    session:LoadMap(post.name or nil)
end)

RegisterCommand('load', function(source, args)
    local playerId = tonumber(source)
    if playerId < 0 then return end

    local session = GetPlayerSession(playerId)
    if not session then return end

    if type(args[1]) ~= 'string' then return end

    session:LoadMap(args[1])
end, false)

-- unload
RegisterNetEvent('session:requestUnloadMap')
AddEventHandler('session:requestUnloadMap', function()
    local playerId = tonumber(source)
    local session = GetPlayerSession(playerId)
    if not session then return end

    printlog('session:requestUnloadMap',
             'Player ' .. GetPlayerName(playerId) ..
                 ' requested to unload map in session ' .. session.id)
    session:UnloadCurrentMap()
end)

RegisterCommand('unload', function(source)
    local playerId = tonumber(source)
    if playerId < 0 then return end

    local session = GetPlayerSession(playerId)
    if not session then return end

    session:UnloadCurrentMap()
end, false)

-- whitelist
RegisterNetEvent('session:requestWhitelist')
AddEventHandler('session:requestWhitelist', function()
    local playerId = tonumber(source)
    local session = GetPlayerSession(playerId)
    if not session then return end

    session:SendWhitelistToPlayer(playerId)
end)

RegisterNetEvent('session:toggleWhitelist')
AddEventHandler('session:toggleWhitelist', function(state)
    local playerId = tonumber(source)
    local session = GetPlayerSession(playerId)
    if not session then return end

    local playerInstance = GetPlayerInstanceFromPlayerId(playerId)
    local playerUId = playerInstance and playerInstance.uId or nil
    if not playerUId or session.ownerId ~= playerUId then
        return TriggerClientEvent('editor:addNotification', playerId, {
            title = 'Session',
            message = 'Access denied.',
            icon = 'circle'
        })
    end

    session:ToggleWhitelist(state)
    session:Save(function()
        SendSessionsToPlayer(-1)
        TriggerClientEvent('editor:addNotification', playerId, {
            title = 'Session',
            message = 'You have ' .. (state and 'disabled' or 'enabled') ..
                ' whitelist for this session.',
            icon = 'circle'
        })
    end)
    session:SendWhitelistToPlayer(playerId)
end)

RegisterNetEvent('session:saveWhitelist')
AddEventHandler('session:saveWhitelist', function(whitelist)
    local playerId = tonumber(source)
    local session = GetPlayerSession(playerId)
    if not session then return end

    local playerInstance = GetPlayerInstanceFromPlayerId(playerId)
    local playerUId = playerInstance and playerInstance.uId or nil
    if not playerUId or session.ownerId ~= playerUId then
        return TriggerClientEvent('editor:addNotification', playerId, {
            title = 'Session',
            message = 'Access denied.',
            icon = 'circle'
        })
    end

    session:SaveWhitelist(whitelist, function()
        SendSessionsToPlayer(-1)
        TriggerClientEvent('editor:addNotification', playerId, {
            title = 'Session',
            message = 'You have successfully saved your whitelist configuration.',
            icon = 'circle'
        })
    end)
end)

-- map list
RegisterNetEvent('session:requestMapNames')
AddEventHandler('session:requestMapNames', function()
    local playerId = tonumber(source)
    local session = GetPlayerSession(playerId)
    if not session then return end

    printlog('session:requestMapNames')
    session:SendMapNamesToPlayer(playerId)
end)

-- environment
RegisterNetEvent('session:changeEnvironment')
AddEventHandler('session:changeEnvironment', function(post)
    local playerId = tonumber(source)
    if type(post) ~= 'table' then return end

    local session = GetPlayerSession(playerId)
    if not session then return end

    printlog('session:changeEnvironment', post)
    session:SetEnvironmentVariable('weather', post.weather)
    session:SetEnvironmentVariable('time', post.time)
    session:Save(function()
        TriggerClientEvent('editor:addNotification', playerId, {
            title = 'Session',
            message = 'You have successfully changed session environment.',
            icon = 'circle'
        })
    end)
end)

-- export
RegisterNetEvent('session:requestExportMap')
AddEventHandler('session:requestExportMap', function(mapName)
    local playerId = tonumber(source)
    if type(mapName) ~= 'string' then return end

    local session = GetPlayerSession(playerId)
    if not session then return end

    printlog('session:requestExportMap', mapName)
    session:ExportMapForPlayer(playerId, mapName)
end)

RegisterNetEvent('session:requestExportAsYmap')
AddEventHandler('session:requestExportAsYmap', function(post)
    local playerId = tonumber(source)
    if type(post) ~= 'table' then return end

    local session = GetPlayerSession(playerId)
    if not session then return end

    printlog('session:requestExportAsYmap',
             'Player ' .. GetPlayerName(playerId) ..
                 ' requested to save map in session ' .. session.id .. ' as ' ..
                 tostring(post.name))

    session:ExportCurrentMapAsYmap(post.name, post.meta)
end)