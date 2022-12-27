-- Locals
local ActiveThreads, Promises = {}, {}
local LastCallback, LastBulkAction

local function DoCreateEntities(entities)
    LastBulkAction = 'CreateEntities'

    ActiveThreads['CreateEntitiesText'] =
        ActiveThreads['CreateEntitiesText'] or EditorThread:Create({
            callFunction = function()
                DrawDebugText(0.8, 0.05,
                              '~b~Loading ~s~environment, please wait...')
            end
        }):Run()

    if type(entities) ~= 'table' then
        if ActiveThreads['CreateEntitiesText'] then
            ActiveThreads['CreateEntitiesText']:Terminate()
            ActiveThreads['CreateEntitiesText'] = nil
        end
        printlog('DoCreateEntities', 'Failed to get entities.')
        return
    end

    local actionTerminated = false
    for _, properties in pairs(entities) do
        CurrentSession.CreateEntity(properties, properties.class == 1)
    end

    if ActiveThreads['CreateEntitiesText'] then
        ActiveThreads['CreateEntitiesText']:Terminate()
        ActiveThreads['CreateEntitiesText'] = nil
    end

    if LastBulkAction ~= 'CreateEntities' then return end

    Editor.StreamEntities(true)
    TriggerEvent('session:allEntitiesCreated')
end

-- bulk create entities
function CurrentSession.CreateEntities(entities)
    if Promises['DeleteEntities'] then
        Promises['DeleteEntities']:reject()
        Promises['DeleteEntities'] = nil
    end

    local p = promise:new()
    CurrentSession.DeleteEntities(function(result)
        if result then
            printlog('CurrentSession.CreateEntities', 'DoCreateEntities',
                     #entities)
            p:resolve(DoCreateEntities(entities))
        else
            p:reject()
            printlog('CurrentSession.CreateEntities',
                     'Action aborted. Promise was not resolved.')
        end
    end)
    Promises['DeleteEntities'] = p
    Citizen.Await(p)
end
RegisterNetEvent('session:createEntities')
AddEventHandler('session:createEntities', CurrentSession.CreateEntities)

-- bulk delete entities
function CurrentSession.DeleteEntities(callback)
    LastBulkAction = 'DeleteEntities'

    TriggerEvent('session:preAllEntitiesDeleted')
    Editor.StreamEntities(false)

    -- terminate awaiting callback
    if type(LastCallback) == 'function' then
        LastCallback(false)
        LastCallback = nil
    end
    LastCallback = callback

    ActiveThreads['DeleteEntitiesText'] =
        ActiveThreads['DeleteEntitiesText'] or EditorThread:Create({
            callFunction = function()
                DrawDebugText(0.8, 0.05,
                              '~r~Cleaning ~s~environment, please wait...')
            end
        }):Run()

    for entityEId, entityInstance in pairs(Editor.entities) do
        Editor.entities[entityEId] = nil
        ClearEntityHandlerId(entityInstance.objectHandler)
        entityInstance:Delete()
    end

    TriggerEvent('session:allEntitiesDeleted')

    if ActiveThreads['DeleteEntitiesText'] then
        ActiveThreads['DeleteEntitiesText']:Terminate()
        ActiveThreads['DeleteEntitiesText'] = nil
    end

    if LastBulkAction ~= 'DeleteEntities' then return end

    if type(LastCallback) == 'function' then
        LastCallback(true)
        LastCallback = nil
    end
end
RegisterNetEvent('session:deleteEntities')
AddEventHandler('session:deleteEntities', CurrentSession.DeleteEntities)
AddEventHandler('session:clientLeft', CurrentSession.DeleteEntities)

-- bulk restore entities
function CurrentSession.RestoreEntities()
    LastBulkAction = 'RestoreEntities'

    Editor.StreamEntities(false)
    ActiveThreads['RestoreEntitiesText'] =
        ActiveThreads['RestoreEntitiesText'] or EditorThread:Create({
            callFunction = function()
                DrawDebugText(0.8, 0.05,
                              '~p~Restoring ~s~environment, please wait...')
            end
        }):Run()

    for _, entityInstance in pairs(Editor.entities) do
        entityInstance:DeleteHandler()
        entityInstance:CreateHandler()
    end

    if ActiveThreads['RestoreEntitiesText'] then
        ActiveThreads['RestoreEntitiesText']:Terminate()
        ActiveThreads['RestoreEntitiesText'] = nil
    end

    if LastBulkAction ~= 'RestoreEntities' then return end

    Editor.StreamEntities(true)
end
