function PlayerConnected(playerId)
    return playerId and Players[playerId] and true or false
end

function GetPlayerInstanceFromPlayerId(playerId)
    return playerId and Players[playerId] or nil
end

function GetPlayerInstanceFromIdentifier(identifier)
    return identifier and PlayerFromIdentifier[identifier] and
               Players[PlayerFromIdentifier[identifier]] or nil
end

function GetPlayerIdFromIdentifier(identifier)
    return identifier and PlayerFromIdentifier[identifier] or nil
end
