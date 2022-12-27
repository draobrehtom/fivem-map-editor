function GetSessionFromId(sessionId)
    local sessionId = tonumber(sessionId)
    return sessionId and EditorSessions.list[sessionId] or nil
end

function GetCurrentSessionInstance()
    return GetSessionFromId(CurrentSession.GetId())
end

function IsPlayerInSession(sessionId)
    return type(sessionId) == 'number' and CurrentSession.id == sessionId
end
