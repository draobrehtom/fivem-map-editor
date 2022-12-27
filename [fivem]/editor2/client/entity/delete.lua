function SafeDeleteEntity(entityId)
    local model = GetEntityArchetypeName(entityId)
    if IsModelAVehicle(model) then
        DeleteVehicle(entityId)
    else
        DeleteObject(entityId)
    end
    DeleteEntity(entityId)
    Citizen.InvokeNative(0x539E0AE3E6634B9F,
                         Citizen.PointerValueIntInitialized(entityId))
end

function Editor.DeleteEntity()
    if Editor.CurrentMode() ~= 'edit' then return end

    local selectedEntity = Editor.GetSelectedEntity()
    if not selectedEntity then return end

    if IsEditorEntity(selectedEntity) then
        TriggerServerEvent('editor:deleteEntity',
                           GetEntityEditorId(selectedEntity))
    else
        TriggerServerEvent('editor:deleteWorldEntity', {
            coords = GetEntityCoords(selectedEntity),
            model = GetEntityArchetypeName(selectedEntity)
        })
        SafeDeleteEntity(selectedEntity)
    end
end
RegisterCommand('edelete', Editor.DeleteEntity)
RegisterKeyMapping('edelete', 'Delete selected entity', 'keyboard', 'delete')
