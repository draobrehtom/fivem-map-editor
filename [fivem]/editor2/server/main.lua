RegisterNetEvent('editor:registerEntity')
AddEventHandler('editor:registerEntity', function(properties)
    if type(properties) ~= 'table' or type(properties.class) ~= 'number' then
        return printlog('editor:registerEntity',
                        'Action aborted. Could not validate properties.')
    end

    local playerId = tonumber(source)
    local playerSession = GetPlayerSession(playerId)
    if not playerSession then return end

    properties.controllerId = playerId
    printlog('editor:registerEntity',
             playerSession.players[playerId] .. ' created an entity in session ' ..
                 playerSession.id)

    local entity = playerSession:RegisterEntity(properties)
    playerSession:SyncEntity(properties.select and playerId or -1, entity.id,
                             properties.select, properties.drag)
end)

RegisterNetEvent('editor:updateEntity')
AddEventHandler('editor:updateEntity', function(properties)
    local playerId = tonumber(source)
    local playerSession = GetPlayerSession(playerId)
    if not playerSession then return end

    local entityInstance = playerSession:GetEntityFromId(properties.id)
    if not entityInstance then return end

    entityInstance.controllerId = playerId

    for key, value in pairs(properties) do
        if not PROTECTED_ENTITY_KEYS[key] then
            entityInstance[key] = value
        end
    end

    printlog('editor:updateEntity',
             'Updating editor entity ' .. entityInstance.id .. ' in session ' ..
                 playerSession.id)
    playerSession:SyncEntity(-1, entityInstance.id)
end)

RegisterNetEvent('editor:requestSelectEntity')
AddEventHandler('editor:requestSelectEntity', function(entityEId, initial)
    local playerId = tonumber(source)
    local playerSession = GetPlayerSession(playerId)
    if not playerSession then return end

    -- Clear selection
    if entityEId == 0 then
        playerSession:FreeEntitiesControlled(playerId)
        return
    end

    -- Set new selection
    local entityInstance = playerSession:GetEntityFromId(entityEId)
    if not entityInstance then
        return printlog('editor:requestSelectEntity',
                        'Action failed. Could not get entity instance with id ' ..
                            entityEId .. ' in session ' .. playerSession.id)
    end

    -- Check if it is already controlled by someone else
    local controllerId = playerSession:GetEntityController(entityEId)
    if controllerId and controllerId ~= playerId then
        TriggerClientEvent('editor:entitySelectFailCallback', playerId,
                           entityEId, GetPlayerName(controllerId))
        return
    end

    -- Selection attempt
    local result, controllerId = playerSession:SetEntityController(entityEId,
                                                                   playerId)
    -- (Result: true) means selected
    if result and controllerId == playerId then
        entityInstance.controllerId = playerId
        printlog('editor:requestSelectEntity',
                 'Player ' .. playerSession.players[playerId] ..
                     ' selected entity ' .. entityEId .. ' in session ' ..
                     playerSession.id)
        TriggerClientEvent('editor:entitySelectCallback', playerId, entityEId,
                           initial)
        return
    end
end)

RegisterNetEvent('editor:deleteEntity')
AddEventHandler('editor:deleteEntity', function(entityEId)
    local playerId = tonumber(source)
    local playerSession = GetPlayerSession(playerId)
    if not playerSession then return end

    printlog('editor:deleteEntity', 'Deleting editor entity ' .. entityEId ..
                 ' in session ' .. playerSession.id)
    playerSession:DeleteEntity(entityEId)
end)

RegisterNetEvent('editor:deleteWorldEntity')
AddEventHandler('editor:deleteWorldEntity', function(properties)
    local playerId = tonumber(source)
    local playerSession = GetPlayerSession(playerId)
    if not playerSession then return end

    if not properties or type(properties.coords) ~= 'vector3' or
        type(properties.model) ~= 'string' then return end

    printlog('editor:deleteWorldEntity',
             'Deleting world editor entity at coords ' .. properties.coords ..
                 ' with the model ' .. properties.model .. ' in session ' ..
                 playerSession.id)

    properties.class = 0
    local entity = playerSession:RegisterEntity(properties)
    playerSession:SyncEntity(properties.select and playerId or -1, entity.id)
end)

function GetDateTime() return os.date("%d/%m/%y/ %X") end
