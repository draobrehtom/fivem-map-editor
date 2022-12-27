-- @param properties [table]
function Editor.RequestEntity(properties)
    if type(properties) ~= 'table' or type(properties.class) ~= 'number' then
        return
    end
    Editor.SelectEntity(-1)
    TriggerServerEvent('editor:registerEntity', properties)
end

function Editor.SyncEntityToServer(entityId)
    entityId = tonumber(entityId)
    if not entityId then return end

    local properties = table.copy(GetEntityInstance(entityId))
    if not properties or properties.class == 0 then
        return printlog('Editor.SyncEntityToServer',
                        'Action aborted. Could not get properties.')
    end

    printlog('Editor.SyncEntityToServer', 'Syncing editor entity ' .. entityId .. ' to the server')
    properties.coords = GetEntityCoords(entityId)
    properties.rotation = GetEntityRotation(entityId)
    TriggerServerEvent('editor:updateEntity', properties)
end

function Editor.LocalSyncEntity(entityId)
    entityId = tonumber(entityId)
    if not entityId then return end

    local entityInstance = GetEntityInstance(entityId)
    if not entityInstance or entityInstance.class == 0 then
        return printlog('Editor.LocalSyncEntity',
                        'Action aborted. Could not get entity instance.')
    end

    printlog('Editor.LocalSyncEntity',
             'Syncing local properties for entity ' .. entityId)
    local coords = GetEntityCoords(entityId)
    local x, y, z = round(coords.x, 3), round(coords.y, 3), round(coords.z, 3)
    entityInstance.coords = vector3(x, y, z)

    local rotation = GetEntityRotation(entityId)
    local rx, ry, rz = round(rotation.x, 3), round(rotation.y, 3),
                       round(rotation.z, 3)
    entityInstance.rotation = vector3(rx, ry, rz)
end
