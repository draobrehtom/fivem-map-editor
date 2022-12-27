-- @param properties [table]
-- @param selectEntity [boolean]
-- @param dragEntity [boolean]
function CurrentSession.SyncEntity(properties, selectEntity, dragEntity)
    if type(properties) ~= 'table' or type(properties.id) ~= 'string' then
        return printlog('CurrentSession.SyncEntity',
                        'Action failed. Could not get properties.', properties,
                        selectEntity, dragEntity)
    end

    local syncedEntity = CurrentSession.CreateEntity(properties, true)
    if not syncedEntity then
        return printlog('session:syncEntity',
                        'Action failed. Could not get entity instance with id ' ..
                            properties.id)
    end

    printlog('CurrentSession.SyncEntity',
             'Syncing editor entity ' .. properties.id)
    if IsPlayerClient(syncedEntity.controllerId) and selectEntity then
        Editor.SelectEntity(syncedEntity.objectHandler, dragEntity)
    end

    Editor.StreamEntities(true)
end
RegisterNetEvent('session:syncEntity')
AddEventHandler('session:syncEntity', CurrentSession.SyncEntity)
