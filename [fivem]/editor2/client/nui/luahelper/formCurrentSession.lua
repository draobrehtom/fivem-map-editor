local AwaitingEntityToSelect

local function RefreshMapContent()
    local entities, statistics = CurrentSession.MapContent()
    NUI.Call('formCurrentSession.entities.cache',
             {entities = entities, statistics = statistics})
end
AddEventHandler('session:allEntitiesCreated', RefreshMapContent)
AddEventHandler('session:allEntitiesDeleted', RefreshMapContent)

AddEventHandler('editor:entityDeleted', function()
    if Editor.StreamingEntities() then RefreshMapContent() end
end)

local function DisplayMapTitle(data)
    NUI.Call('formCurrentSession.map.title', data)
end

AddEventHandler('session:dataChanged', function(key, value)
    if key == 'currentMap' then DisplayMapTitle(value) end
end)

AddEventHandler('nui:formShown', function(formId)
    if formId == 'form_current_session' then
        RefreshMapContent()
        DisplayMapTitle(CurrentSession.currentMap)
    end
end)

RegisterNUICallback('formCurrentSession.entities.select', function(post)
    local entityEId = post.value
    local entityInstance = entityEId and GetEntityInstanceFromId(entityEId) or
                               nil
    if not entityInstance then return end

    -- Hide NUI
    NUI.SetVisible(false)

    -- Get object size to locate camera properly
    local dx, dy, dz = GetEntityDimensions(entityInstance.objectHandler)
    local x, y, z = entityInstance.coords.x, entityInstance.coords.y,
                    entityInstance.coords.z
    z = z + dz + 50.0

    -- Update camera
    SetFreecamPosition(x, y, z)
    SetFreecamRotation(-90, 0, 0)

    AwaitingEntityToSelect = entityEId
    while AwaitingEntityToSelect == entityEId and
        not entityInstance:DoesHandlerExist() do Wait(100) end

    if AwaitingEntityToSelect ~= entityEId or Editor.GetSelectedEntity() then return end

    -- Force select entity (may fail if already selected)
    Editor.SelectEntity(entityInstance.objectHandler)
end)

RegisterNUICallback('formCurrentSession.entities.delete', function(post)
    local entityEId = post.value
    local entityInstance = entityEId and GetEntityInstanceFromId(entityEId) or
                               nil
    if not entityInstance then return end

    TriggerServerEvent('editor:deleteEntity', entityEId)
end)

RegisterNUICallback('formCurrentSession.map.load', function(post)
    TriggerServerEvent('session:requestLoadMap', post)
end)

RegisterNUICallback('formCurrentSession.map.save', function(post)
    TriggerServerEvent('session:requestSaveMap', post)
end)

RegisterNUICallback('formCurrentSession.map.unload', function()
    TriggerServerEvent('session:requestUnloadMap')
end)

RegisterNUICallback('formCurrentSession.map.exportAsYmap', function(post)
    TriggerServerEvent('session:requestExportAsYmap', post)
end)