function SafeSessionConfig(config)
    if type(config) ~= 'table' then return config end

    config.name =
        type(config.name) == 'string' and string.len(config.name) > 2 and
            config.name or 'Default editor session @ store.foxx.gg'
    config.maximumSlots = type(config.maximumSlots) == 'number' and
                              config.maximumSlots >= 0 and config.maximumSlots or
                              4
    config.password = type(config.password) == 'string' and config.password or
                          ''
    return config
end

function GetSessionFromId(sessionId)
    return sessionId and Session.instances[sessionId] or nil
end

function GetPlayerSessionId(playerId)
    return playerId and PlayerSessionId[playerId] or nil
end

function GetPlayerSession(playerId)
    return playerId and PlayerSessionId[playerId] and
               Session.instances[PlayerSessionId[playerId]] or nil
end

function SetPlayerSession(playerId, sessionId)
    PlayerSessionId[playerId] = sessionId
end

function SendSessionsToPlayer(playerId)
    playerId = tonumber(playerId)
    if not playerId then return end

    if playerId == -1 then
        printlog('SendSessionsToPlayer', 'Sending to all players')
        for _, playerId in pairs(GetPlayers()) do
            SendSessionsToPlayer(playerId)
        end
        return
    end

    printlog('SendSessionsToPlayer', 'Sending to ' .. GetPlayerName(playerId))
    local playerInstance = GetPlayerInstanceFromPlayerId(playerId)
    local playerUId = playerInstance and playerInstance.uId or nil

    local sessions = {}
    for i, sessionInstance in pairs(Session.instances) do
        sessions[i] = sessionInstance:FetchContent()
    end

    MONGO:find({
        collection = COLLECTION_SESSIONS,
        query = {},
        options = {projection = {_id = 0, id = 1, ownerId = 1, whitelist = 1, whitelistDisabled = 1}}
    }, function(success, result)
        if not success then return end

        local whitelistedSessionsForPlayer = {}
        for _, session in pairs(result) do
            local authorized = false
            if session.whitelistDisabled then
                authorized = true

            elseif playerUId then
                if session.ownerId == playerUId then
                    authorized = true

                else
                    local whitelist = type(session.whitelist) == 'table' and
                                          session.whitelist or {}
                    for _, uId in pairs(whitelist) do
                        if tostring(uId) == tostring(playerUId) then
                            authorized = true
                            break
                        end
                    end
                end
            end

            if authorized then
                table.insert(whitelistedSessionsForPlayer, session.id)
            end
        end

        local callbackResult = {}
        for _, sessionId in pairs(whitelistedSessionsForPlayer) do
            callbackResult[sessionId] = sessions[sessionId]
        end

        TriggerClientEvent('editor:requestSessionsCallback', playerId,
                           callbackResult)
    end)
end
