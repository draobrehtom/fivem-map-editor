function IsEditorEntity(entityId)
    return type(entityId) == 'number' and Editor.handlerId[entityId] ~= nil
end

function GetEntityEditorId(entityId)
    return type(entityId) == 'number' and Editor.handlerId[entityId] or nil
end

function GetEntityInstance(entityId)
    local entityId =
        type(entityId) == 'number' and Editor.handlerId[entityId] or nil
    return entityId and Editor.entities[entityId] or nil
end

function GetEntityInstanceFromId(entityEId)
    return entityEId and Editor.entities[entityEId] or nil
end
