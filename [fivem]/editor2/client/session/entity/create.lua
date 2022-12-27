-- @param properties [table]
function CurrentSession.CreateEntity(properties, instant)
    if type(properties) ~= 'table' or type(properties.id) ~= 'string' then
        printlog('CurrentSession.CreateEntity', 'Action aborted.',
                 'Could not get properties.', properties)
        return nil
    end

    local entityInstance = EditorEntity:Create(properties.id)

    -- Assign defaults
    for key, value in pairs(DEFAULT_ENTITY_PROPERTIES) do
        if tostring(type(properties[key])) == 'nil' then
            properties[key] = value
        end
    end

    if not properties.model then
        properties.model = properties.class == 1 and SPAWNPOINT_MODEL or
                               properties.model
    end
    properties.coords = type(properties.coords) == 'vector3' and
                            properties.coords or vector3(0.0, 0.0, 0.0)
    properties.rotation = type(properties.rotation) == 'vector3' and
                              properties.rotation or vector3(0.0, 0.0, 0.0)

    Editor.entities[properties.id] = entityInstance
    entityInstance:MatchProperties(properties)
    entityInstance:SetModel(properties.model, instant)
    if instant then entityInstance:UpdateHandler() end
    return entityInstance
end
