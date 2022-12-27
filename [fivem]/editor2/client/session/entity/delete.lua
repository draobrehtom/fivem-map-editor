function CurrentSession.DeleteEntity(entityEId)
    local entityInstance = GetEntityInstanceFromId(entityEId)
    if not entityInstance then
        return printlog('CurrentSession.DeleteEntity', 'Action failed. Could not get entity instance. (' .. entityEId .. ')')
    end

    Editor.entities[entityEId] = nil
    ClearEntityHandlerId(entityInstance.objectHandler)
    entityInstance:Delete()
    printlog('CurrentSession.DeleteEntity', 'Deleted editor entity ' .. entityEId)
end
RegisterNetEvent('session:deleteEntity')
AddEventHandler('session:deleteEntity', CurrentSession.DeleteEntity)
