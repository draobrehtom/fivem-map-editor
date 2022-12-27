local function CloneInstance(entityInstance)
    if type(entityInstance) ~= 'table' then
        return printlog('CloneInstance',
                        'Action aborted. Invalid or missing argument. (entityInstance)')
    end

    local clonedInstance = {}
    for key in pairs({['model'] = true, ['coords'] = true, ['rotation'] = true}) do
        clonedInstance[key] = entityInstance[key]
    end

    for key in pairs(DEFAULT_ENTITY_PROPERTIES) do
        if entityInstance[key] then
            clonedInstance[key] = entityInstance[key]
        end
    end
    return clonedInstance
end

function Editor.CloneEntity()
    local selectedEntity = Editor.GetSelectedEntity()
    if not selectedEntity then return end

    Editor.LocalSyncEntity(selectedEntity)
    local selectedEntityInstance = GetEntityInstance(selectedEntity)
    local entityClass =
        selectedEntityInstance and selectedEntityInstance.class or 2
    local properties

    -- editor entity
    if selectedEntityInstance then
        properties = CloneInstance(selectedEntityInstance)
        printlog('Editor.CloneEntity',
                 'Cloning editor entity ' .. selectedEntity .. ' with class ' ..
                     entityClass .. ' and id ' .. selectedEntityInstance.id)

        -- world entity
    else
        properties = {
            model = GetEntityArchetypeName(selectedEntity),
            coords = GetEntityCoords(selectedEntity),
            rotation = GetEntityRotation(selectedEntity)
        }
        entityClass = 2
        printlog('Editor.CloneEntity', 'Cloning world entity ' .. selectedEntity)
    end

    if not properties then
        return printlog('Editor.CloneEntity',
                        'Action aborted. Could not collect properties.')
    end

    properties.select = true
    properties.drag = false

    -- spawnpoint
    if entityClass == 1 then
        Editor.CreateSpawnpoint(properties)

        -- object
    elseif entityClass == 2 then
        Editor.CreateObject(properties)

        -- vehicle
    elseif entityClass == 3 then
        Editor.CreateVehicle(properties)
    end
end
RegisterCommand('eclone', Editor.CloneEntity)
RegisterKeyMapping('eclone', 'Clone selected entity', 'keyboard', 'c')
