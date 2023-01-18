local RemoveWorld = {}
local EntitySets = {}

function GetSpawnpoints(resourceName, setName)
    if type(resourceName) ~= 'string' or not EntitySets[resourceName] then
        return nil
    end

    if type(setName) == 'string' and EntitySets[resourceName][setName] then
        return EntitySets[resourceName][setName].spawnpoints

    else
        local spawnpoints = {}
        for setName in pairs(EntitySets[resourceName]) do
            for _, spawnpoint in pairs(EntitySets[resourceName][setName]
                                           .spawnpoints) do
                table.insert(spawnpoints, spawnpoint)
            end
        end
        return spawnpoints
    end
end
exports('GetSpawnpoints')

local function CreateEntityFromSet(resourceName, setName, instance)
    RequestModel(instance.model)
    local gameTimer = GetGameTimer()
    while not HasModelLoaded(instance.model) do
        Wait(10)
        if (GetGameTimer() - gameTimer) > 2000 then
            printlog('Could not load model ' .. instance.model ..
                         ' after 2 seconds, skipping')
            break
        end
    end

    if HasModelLoaded(instance.model) then
        local handler = CreateObjectNoOffset(instance.model, instance.coords.x,
                                             instance.coords.y,
                                             instance.coords.z, false, false,
                                             false)
        if handler > 0 then
            if instance.rotation then
                SetEntityRotation(handler, instance.rotation.x,
                                  instance.rotation.y, instance.rotation.z)
            end
            SetEntityAlpha(handler, tonumber(instance.alpha) or 255)
            SetEntityLodDist(handler, type(instance.lod) == 'number' and
                                 instance.lod ~= 0 and instance.lod or 100)
            SetEntityVisible(handler, instance.visible == 1, 0)
            FreezeEntityPosition(handler, instance.frozen == 1)
            SetEntityLights(handler, instance.lights == 0)
            SetEntityCollision(handler, instance.collisions == 1, true)
            SetEntityInvincible(handler, instance.invincible == 1)
            SetEntityDynamic(handler, instance.dynamic == 1)
            SetEntityHasGravity(handler, instance.gravity == 1)
            SetObjectTextureVariation(handler,
                                      type(instance.decals) == 'number' and
                                          instance.decals or 0)
            SetEntityAsMissionEntity(handler, true, true)
            instance.handler = handler
        else
            DeleteEntity(handler)
            instance.handler = nil
        end
    end
end

RegisterNetEvent('loadMap')
AddEventHandler('loadMap', function(resourceName, setName, entities)
    if not RemoveWorld[resourceName] then RemoveWorld[resourceName] = {} end
    if not EntitySets[resourceName] then EntitySets[resourceName] = {} end

    if not RemoveWorld[resourceName][setName] then
        RemoveWorld[resourceName][setName] = {}
    end

    if not EntitySets[resourceName][setName] then
        EntitySets[resourceName][setName] = {spawnpoints = {}, entities = {}}
    end

    printlog('Client loading map ' .. resourceName)

    for k, entity in pairs(entities.removeWorld) do
        RemoveWorld[resourceName][setName][k] = entity
    end

    for _, spawnpoint in pairs(entities.spawnpoints) do
        local heading = 0.0
        if spawnpoint.rotation then heading = spawnpoint.rotation.z end
        table.insert(EntitySets[resourceName][setName].spawnpoints,
                     {coords = spawnpoint.coods, heading = heading})
    end

    for k, entity in pairs(entities.objects) do
        EntitySets[resourceName][setName].entities[k] = entity
    end

    CreateThread(function()
        while true do
            if not EntitySets[resourceName] or
                not EntitySets[resourceName][setName] then return end

            local playerPed = GetPlayerPed(-1)
            local playerCoords = GetEntityCoords(playerPed)

            for setName in pairs(RemoveWorld[resourceName]) do
                local set = RemoveWorld[resourceName][setName]
                local counter = 0
                for _, removeWorld in pairs(set) do
                    local entityId = GetClosestObjectOfType(
                                         removeWorld.coords.x,
                                         removeWorld.coords.y,
                                         removeWorld.coords.z, 0.1,
                                         removeWorld.model)
                    if entityId > 0 then
                        SetEntityAsMissionEntity(entityId, true, true)
                        DeleteEntity(entityId)
                    end
                end
            end

            for setName in pairs(EntitySets[resourceName]) do
                local set = EntitySets[resourceName][setName]
                local counter = 0
                for _, entityInstance in pairs(set.entities) do
                    local entityExists = DoesEntityExist(entityInstance.handler)
                    local entityCoords =
                        vector3(entityInstance.coords.x,
                                entityInstance.coords.y, entityInstance.coords.z)
                    local isNear = entityCoords and
                                       IsCoordNear(entityCoords, playerCoords) or
                                       false

                    if isNear and not entityExists then
                        CreateEntityFromSet(resourceName, setName,
                                            entityInstance)

                    elseif not isNear and entityExists then
                        DeleteEntity(entityInstance.handler)
                        entityInstance.handler = nil
                    end
                    counter = counter + 1
                    if (counter % 25) == 0 then Wait(200) end
                end
            end
            Wait(500)
        end
    end)

    TriggerEvent('mapStarted', resourceName, setName,
                 EntitySets[resourceName][setName])
end)

RegisterNetEvent('deleteAllSets')
AddEventHandler('deleteAllSets', function(resourceName)
    if not EntitySets[resourceName] then return end

    printlog('Client unloading map ' .. resourceName)
    for setName in pairs(EntitySets[resourceName]) do
        for _, entity in pairs(EntitySets[resourceName][setName].entities) do
            if DoesEntityExist(entity.handler) then
                SetEntityAsMissionEntity(entity.handler, false, false)
                DeleteEntity(entity.handler)
            end
            entity.handler = nil
        end
        EntitySets[resourceName][setName] = nil
        TriggerEvent('mapStopped', resourceName)
    end
    EntitySets[resourceName] = nil
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= CURRENT_RESOURCE_NAME then return end

    local ped = PlayerPedId()
    local time = GetGameTimer()
    while (not HasCollisionLoadedAroundEntity(ped) and (GetGameTimer() - time) <
        5000) do Wait(0) end

    TriggerServerEvent('clientReady')
end)

local RenderDistance = 5000 * 5000
function IsCoordNear(p1, p2)
    local diff = p2 - p1
    local distance = (diff.x * diff.x) + (diff.y * diff.y)
    return (distance < RenderDistance)
end
