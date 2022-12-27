local LoadedFxMapResources = {}

function LoadMap(resourceName)
    if type(resourceName) ~= 'string' then return end

    local metaAuthor = GetResourceMetadata(resourceName, 'fx_meta_author', 0)
    local metaDescription = GetResourceMetadata(resourceName,
                                                'fx_meta_description', 0)
    local totalMapFiles = GetNumResourceMetadata(resourceName, 'fx_map_file')
    local mapFiles = {}
    for i = 0, totalMapFiles - 1 do
        table.insert(mapFiles,
                     GetResourceMetadata(resourceName, 'fx_map_file', i))
    end

    LoadedFxMapResources[resourceName] = {entitySets = {}, handlers = {}}
    printlog('Loading map ' .. resourceName .. ' | Author: ' .. metaAuthor ..
                 ' | Description: ' .. metaDescription)

    for _, filePath in pairs(mapFiles) do
        local contentJSON = LoadResourceFile(resourceName, filePath)
        if type(contentJSON) == 'string' then
            local content = json.decode(contentJSON)
            if type(content) == 'table' then
                local setName = tostring(filePath)
                local entitySet = {
                    removeWorld = {},
                    spawnpoints = {},
                    objects = {},
                    vehicles = {}
                }

                for i, entity in pairs(content) do
                    if entity.class == 0 then
                        table.insert(entitySet.removeWorld, entity)

                    elseif entity.class == 1 then
                        table.insert(entitySet.spawnpoints, entity)

                    elseif entity.class == 2 then
                        table.insert(entitySet.objects, entity)

                    elseif entity.class == 3 then
                        table.insert(entitySet.vehicles, entity)

                        local handler = CreateVehicle(entity.model,
                                                      entity.coords.x,
                                                      entity.coords.y,
                                                      entity.coords.z, 0.0,
                                                      true, false)
                        if handler > 0 then
                            LoadedFxMapResources[resourceName].handlers[handler] =
                                true

                            -- Rotation
                            if entity.rotation then
                                SetEntityRotation(handler, entity.rotation.x,
                                                  entity.rotation.y,
                                                  entity.rotation.z)
                            end

                            -- Colours
                            if type(entity.colors) == 'table' then
                                SetVehicleColours(handler, entity.colors[1],
                                                  entity.colors[2])
                            end
                        else
                            DeleteVehicle(handler)
                        end
                    end
                end
                LoadedFxMapResources[resourceName].meta = {
                    author = metaAuthor,
                    description = metaDescription
                }
                LoadedFxMapResources[resourceName].entitySets[setName] =
                    entitySet
                TriggerClientEvent('loadMap', -1, resourceName, setName,
                                   entitySet)
            end
        end
    end
    TriggerEvent('mapStarted', resourceName, LoadedFxMapResources[resourceName],
                 LoadedFxMapResources[resourceName].meta)
    AddChatMessage('Map started: ' .. resourceName .. ' | Author: ' ..
                       metaAuthor, -1)
end

function UnloadMap(resourceName)
    if type(resourceName) ~= 'string' then return end

    if LoadedFxMapResources[resourceName] then
        for handler in pairs(LoadedFxMapResources[resourceName].handlers) do
            if DoesEntityExist(handler) then DeleteEntity(handler) end
        end
        TriggerClientEvent('deleteAllSets', -1, resourceName)
    end

    LoadedFxMapResources[resourceName] = nil
    TriggerEvent('mapStopped', resourceName)
    AddChatMessage('Stopped map: ' .. resourceName, -1)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == CURRENT_RESOURCE_NAME then return end

    local isFxMap = GetResourceMetadata(resourceName, 'fx_map')
    if not isFxMap then return end

    LoadMap(resourceName)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == CURRENT_RESOURCE_NAME then return end
    if LoadedFxMapResources[resourceName] then UnloadMap(resourceName) end
end)

RegisterNetEvent('clientReady')
AddEventHandler('clientReady', function()
    local playerId = tonumber(source)
    for resourceName in pairs(LoadedFxMapResources) do
        for setName in pairs(LoadedFxMapResources[resourceName].entitySets) do
            TriggerClientEvent('loadMap', playerId, resourceName, setName,
                               LoadedFxMapResources[resourceName].entitySets[setName])
        end
    end
end)
