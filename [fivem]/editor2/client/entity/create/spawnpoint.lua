local KEY_ADD_SPAWNPOINT = INPUT_INTERACTION_MENU

-- Locals
local Spawnpoints = {}

-- Optimization
local IsControlJustPressed = IsControlJustPressed
local GetEntityInstanceFromId = GetEntityInstanceFromId
local GetEntityCoords = GetEntityCoords
local Draw3DText = Draw3DText
local Wait = Citizen.Wait

-- @param properties [table]
function Editor.CreateSpawnpoint(properties)
    if Editor.CurrentMode() ~= 'edit' then end

    if type(properties) ~= 'table' or type(properties.coords) ~= 'vector3' then
        return printlog('Editor.CreateSpawnpoint',
                        'Action aborted. Invalid or missing argument(s).')
    end

    properties.class = 1
    properties.indicatorColor = {
        math.random(255), math.random(255), math.random(255)
    }
    Editor.RequestEntity(properties)
end

function Editor.GetCurrentSpawnpoints()
    local result = {}
    for instanceId in pairs(Spawnpoints) do
        table.insert(result, Editor.entities[instanceId])
    end
    return result
end

function Editor.GetNearestSpawnpoint()
    local currentSpawnpoints = Editor.GetCurrentSpawnpoints()
    if #currentSpawnpoints < 1 then return nil end

    local coords = GetEntityCoords(PlayerPedId())
    local closestId, closestDistance
    for k, entityInstance in pairs(currentSpawnpoints) do
        local distance = GetDistanceBetweenCoords(coords, entityInstance.coords)
        if not closestDistance or distance < closestDistance then
            closestId = k
            closestDistance = distance
        end
    end
    return currentSpawnpoints[closestId]
end

local function AddSpawnpointShortcut()
    if Editor.CurrentMode() ~= 'edit' then return end

    Editor.ClearEntityPreview()
    NUI.SetVisible(false)
    Wait(0)

    local point1 = GetFreecamPosition()
    local point2 = GetWorldDraggingPosition()
    local hitCoords = Raytrace(point1, point2, nil, true, true)
    if not hitCoords then return end

    Editor.CreateSpawnpoint({coords = hitCoords, select = true, drag = true})
end
RegisterCommand('aspawnpoint', AddSpawnpointShortcut)
RegisterKeyMapping('aspawnpoint', 'Add spawnpoint shortcut', 'keyboard', 'm')
RegisterNUICallback('formCreateEntity.create.spawnpoint', AddSpawnpointShortcut)

AddEventHandler('editor:entityHandlerCreated', function(entityInstance)
    if not entityInstance then return end

    if entityInstance.class == 1 then
        Spawnpoints[entityInstance.id] = {
            objectHandler = entityInstance.objectHandler,
            indicatorColor = entityInstance.indicatorColor
        }

        -- Render thread
        if #Editor.GetCurrentSpawnpoints() == 1 then
            CreateThread(function()
                while true do
                    if not IsPauseMenuActive() and not NUI.IsVisible() then
                        local counter = 0
                        for entityEId, entityValues in pairs(Spawnpoints) do
                            counter = counter + 1
                            if IsEntityOnScreen(entityValues.objectHandler) == 1 then
                                if DoesEntityExist(entityValues.objectHandler) ==
                                    1 then
                                    local coords = GetEntityCoords(
                                                       entityValues.objectHandler)
                                    local r, g, b = 255, 255, 255
                                    if entityValues.indicatorColor then
                                        r, g, b =
                                            entityValues.indicatorColor[1],
                                            entityValues.indicatorColor[2],
                                            entityValues.indicatorColor[3]
                                    end
                                    DrawMarker(25, coords.x, coords.y, coords.z,
                                               0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                               2.0, 2.0, 2.0, r, g, b, 255,
                                               false, true, 2, nil, nil, true)
                                else
                                    Spawnpoints[entityEId] = nil
                                end
                            end
                        end
                        if counter < 1 then return end
                    end
                    Wait(0)
                end
            end)
        end
    end
end)
