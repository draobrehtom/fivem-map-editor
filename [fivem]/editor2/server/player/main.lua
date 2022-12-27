_G.Players = {}
_G.PlayerFromIdentifier = {}

local function SyncPlayerIdentifier(playerId)
    playerId = tonumber(playerId)
    if not playerId then return end
    local playerInstance = GetPlayerInstanceFromPlayerId(playerId)
    if not playerInstance then return end
    TriggerClientEvent('editor:playerIdentified', playerId, playerInstance.uId)
end

function SetupPlayer(playerId, wasConnected)
    playerId = tonumber(playerId)
    if Players[playerId] then return end

    local identifier = CollectPlayerIdentifiers(playerId).fivemid
    if identifier then
        Players[playerId] = FxPlayer:New(identifier)
        PlayerFromIdentifier[identifier] = playerId
        Players[playerId]:Set('playerName', GetPlayerName(playerId))
        SyncPlayerIdentifier(playerId)
    else
        printlog('SetupPlayer',
                 'Action failed. No identifier found for player ' .. playerId)
    end
    ResetPlayerRoutingBucket(playerId)
end

AddEventHandler('playerConnecting', function()
    printlog('Player ' .. source .. ' is connecting.')
    SetupPlayer(source, true)
end)

RegisterNetEvent('playerJoining')
AddEventHandler('playerJoining', function(oldId)
    printlog('Player ' .. source .. ' is joining. (Connect id: ' .. oldId .. ')')
    local oldPlayer = Players[tonumber(oldId)]
    if oldPlayer then
        Players[tonumber(source)] = oldPlayer
        Players[tostring(oldId)] = nil
    else
        SetupPlayer(tonumber(source))
    end
    TriggerEvent('editor:playerJoining', tonumber(source))
end)

AddEventHandler('playerDropped', function()
    local playerId = tonumber(source)
    local playerName = GetPlayerName(playerId) or 'unnamed'
    local playerInstance = GetPlayerInstanceFromPlayerId(playerId)
    local playerIdentifier
    if playerInstance then
        playerIdentifier = playerInstance.uId
        playerName = playerInstance:Get('playerName') or 'unnamed'
        playerInstance:Destroy()
    end

    printlog('Player ' .. playerId .. ' (' .. playerName .. ') left.')
    TriggerEvent('editor:playerDropped', playerId, playerName)

    if playerIdentifier then PlayerFromIdentifier[playerIdentifier] = nil end
    Players[playerId] = nil
end)

RegisterNetEvent('editor:playerReady')
AddEventHandler('editor:playerReady', function()
    local playerId = tonumber(source)
    SyncPlayerIdentifier(playerId)
end)

local awaitingConnection = true
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == CURRENT_RESOURCE_NAME then
        if not MONGO:isConnected() then
            return printlog(
                       'Server is not connected to the database, awaiting connection to set players up.')
        end

        for _, playerId in pairs(GetPlayers()) do SetupPlayer(playerId) end
        awaitingConnection = nil
    end
end)

AddEventHandler('onDatabaseConnect', function(dbName)
    if awaitingConnection and dbName == 'editor2' then
        printlog('Server is now connected to the database, setting players up.')
        for _, playerId in pairs(GetPlayers()) do SetupPlayer(playerId) end
    end
end)
