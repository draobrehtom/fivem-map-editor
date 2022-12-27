_G.EditorSessions = {list = {}}

function EditorSessions.Request() TriggerServerEvent('editor:requestSessions') end

local function CountPlayersInSession(sessionId)
    local session = EditorSessions.list[tonumber(sessionId)]
    if not session then return end

    local count = 0
    for playerId in pairs(session.players) do count = count + 1 end
    session.playerCount = count
    return count
end

RegisterNetEvent('editor:requestSessionsCallback')
AddEventHandler('editor:requestSessionsCallback', function(sessions)
    EditorSessions.list = {}
    for sessionId, session in pairs(sessions) do
        session.editable = session.ownerId and Editor.playerUId and
                               session.ownerId == Editor.playerUId and 1 or 0
        EditorSessions.list[sessionId] = session
        CountPlayersInSession(sessionId)
    end
    TriggerEvent('editor:sessionsUpdated', EditorSessions.list)
end)

RegisterNetEvent('session:playerJoined')
AddEventHandler('session:playerJoined',
                function(sessionId, playerId, playerName)
    local session = EditorSessions.list[tonumber(sessionId)]
    if not session then return end

    session.players[playerId] = playerName
    CountPlayersInSession(sessionId)
    TriggerEvent('editor:sessionsUpdated', EditorSessions.list)
end)

RegisterNetEvent('session:playerLeft')
AddEventHandler('session:playerLeft',
                function(sessionId, playerId, playerName)
    local session = EditorSessions.list[tonumber(sessionId)]
    if not session then return end

    session.players[playerId] = nil
    CountPlayersInSession(sessionId)
    TriggerEvent('editor:sessionsUpdated', EditorSessions.list)
end)
