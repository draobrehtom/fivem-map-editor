local SelectedEntityBackupData

-- When client closes properties window without saving, we need these data to restore
local function SaveBackupData(entityInstance)
    SelectedEntityBackupData = table.copy(entityInstance)
end

local function ClearBackupData() SelectedEntityBackupData = nil end

-- Simply applying these stored data
local function ApplyBackupData()
    if SelectedEntityBackupData then
        local entityInstance = GetEntityInstance(Editor.GetSelectedEntity())
        if entityInstance then
            entityInstance:MatchProperties(SelectedEntityBackupData)
            entityInstance:UpdateHandler()
        end
        ClearBackupData()
    end
end

local function FetchProperties(entityInstance)
    local entityInstance = type(entityInstance) == 'table' and entityInstance or
                               GetEntityInstance(Editor.GetSelectedEntity())
    if not entityInstance then return end

    local entityProperties = table.copy(entityInstance)
    entityProperties.coords = {
        x = round(entityInstance.coords.x, 3),
        y = round(entityInstance.coords.y, 3),
        z = round(entityInstance.coords.z, 3)
    }
    entityProperties.rotation = {
        x = round(entityInstance.rotation.x, 3),
        y = round(entityInstance.rotation.y, 3),
        z = round(entityInstance.rotation.z, 3)
    }

    NUI.Call('formEntityProperties.display', {post = entityProperties})
end

function Editor.ShowSelectedEntityProperties()
    local selectedEntity = Editor.GetSelectedEntity()
    if not selectedEntity or not IsAnEntity(selectedEntity) then return end

    local entityInstance = GetEntityInstance(selectedEntity)
    if not entityInstance then return end

    -- Sync local entity to update it's properties
    Editor.LocalSyncEntity(selectedEntity)

    -- Store instance data to be able load back
    SaveBackupData(entityInstance)

    -- Fetch NUI
    NUI.Call('nui.switch', {value = 'form_entity_properties'})
    FetchProperties(entityInstance)
end
RegisterCommand('eproperties', Editor.ShowSelectedEntityProperties)
RegisterKeyMapping('eproperties', 'Show selected entity properties', 'keyboard',
                   'F3')

-- 'Update'
RegisterNUICallback('formEntityProperties.update', function(post)
    if type(post) ~= 'table' or type(post.property) ~= 'string' then return end

    local entityInstance = GetEntityInstance(Editor.GetSelectedEntity())
    if not entityInstance or not entityInstance[post.property] then
        return printlog('formEntityProperties.update',
                        'Action aborted. Could not get property from entity instance. (' ..
                            post.property .. ')')
    end

    -- coords
    if post.property == 'coords' then
        if entityInstance.locked ~= 1 then
            local x, y, z = post.value.coord_x or 0.0,
                            post.value.coord_y or 0.0, post.value.coord_z or 0.0
            x, y, z = round(x, 3), round(y, 3), round(z, 3)

            entityInstance.coords = vector3(x, y, z)
            entityInstance:UpdateHandler()
        end

        -- rotation
    elseif post.property == 'rotation' then
        if entityInstance.locked ~= 1 then
            local rx, ry, rz = post.value.rot_pitch or 0.0,
                               post.value.rot_roll or 0.0,
                               post.value.rot_yaw or 0.0
            rx, ry, rz = round(rx, 3), round(ry, 3), round(rz, 3)

            entityInstance.rotation = vector3(rx, ry, rz)
            entityInstance:UpdateHandler()

            if entityInstance.class ~= 1 and entityInstance.rotationType ~=
                'world' then
                entityInstance.rotationType = 'world'
                FetchProperties(entityInstance)
            end
        end

        -- decals
    elseif post.property == 'decals' then
        local value = post.value >= 0 and post.value <= 15 and post.value or 0
        if entityInstance.decals ~= value then
            entityInstance.decals = value
            entityInstance:UpdateHandler()
        end

        -- other
    elseif entityInstance[post.property] ~= post.value then
        entityInstance[post.property] = post.value
        entityInstance:UpdateHandler()
        FetchProperties(entityInstance)
    end
end)

RegisterNUICallback('formEntityProperties.setAsOrigin', function()
    local entityInstance = GetEntityInstance(Editor.GetSelectedEntity())
    if not entityInstance then
        return printlog('formEntityProperties.invert',
                        'Action aborted. Could not get entity instance.')
    end

    local originEntity = Editor.GetOriginEntity()
    if originEntity and originEntity == entityInstance.objectHandler then
        return Editor.SetOriginEntity(-1)
    end
    
    Editor.SetOriginEntity(entityInstance.objectHandler)
end)

RegisterNUICallback('formEntityProperties.originMove', function(post)
    if type(post) ~= 'table' or type(post.axis) ~= 'string' then return end

    local entityInstance = GetEntityInstance(Editor.GetSelectedEntity())
    if not entityInstance then
        return printlog('formEntityProperties.invert',
                        'Action aborted. Could not get entity instance.')
    end

    local originEntityId = Editor.GetOriginEntity()
    if not originEntityId then return end

    local originCoords = GetEntityCoords(originEntityId)
    local coords = GetEntityCoords(entityInstance.objectHandler)
    if post.axis == 'x' then
        local offset = coords.x - originCoords.x
        entityInstance.coords = vector3(originCoords.x - offset, coords.y, coords.z)
        entityInstance:UpdateHandler()
        FetchProperties(entityInstance)

    elseif post.axis == 'y' then
        local offset = coords.y - originCoords.y
        entityInstance.coords = vector3(coords.x, originCoords.y - offset, coords.z)
        entityInstance:UpdateHandler()
        FetchProperties(entityInstance)

    elseif post.axis == 'z' then
        local offset = coords.z - originCoords.z
        entityInstance.coords = vector3(coords.x, coords.y, originCoords.z - offset)
        entityInstance:UpdateHandler()
        FetchProperties(entityInstance)
    end
end)

RegisterNUICallback('formEntityProperties.invert', function(post)
    if type(post) ~= 'table' or type(post.axis) ~= 'string' then return end

    local entityInstance = GetEntityInstance(Editor.GetSelectedEntity())
    if not entityInstance then
        return printlog('formEntityProperties.invert',
                        'Action aborted. Could not get entity instance.')
    end

    local itype = tonumber(post.itype) or 0
    local add = itype == 1 and 90 or 180
    local rotation = GetEntityRotation(entityInstance.objectHandler)
    if post.axis == 'x' then
        if entityInstance.class == 1 then return end

        entityInstance.rotation = vector3((rotation.x + add) % 360, rotation.y,
                                          rotation.z)
        entityInstance:UpdateHandler()
        FetchProperties(entityInstance)

    elseif post.axis == 'y' then
        if entityInstance.class == 1 then return end
        
        entityInstance.rotation = vector3(rotation.x, (rotation.y + add) % 360,
                                          rotation.z)
        entityInstance:UpdateHandler()
        FetchProperties(entityInstance)

    elseif post.axis == 'z' then
        entityInstance.rotation = vector3(rotation.x, rotation.y,
                                          (rotation.z + add) % 360)
        entityInstance:UpdateHandler()
        FetchProperties(entityInstance)
    end
end)

RegisterNUICallback('formEntityProperties.save', function(post)
    ClearBackupData()
    Editor.SelectEntity(-1)
    NUI.Call('nui.aform.hide')
end)

AddEventHandler('editor:formHid', function(formId)
    if formId == 'form_entity_properties' then
        ApplyBackupData()
        Editor.SelectEntity(-1)
    end
end)

local function PlaceDownEntityShortcut(fromNUI)
    local entityInstance = GetEntityInstance(Editor.GetSelectedEntity())
    if not entityInstance then return end

    entityInstance:PlaceDown()

    if fromNUI then
        Editor.LocalSyncEntity(entityInstance.objectHandler)
        FetchProperties(entityInstance)
    end
end
RegisterCommand('eplaced', PlaceDownEntityShortcut)
RegisterKeyMapping('eplaced', 'Place down selected entity', 'keyboard', 'g')
RegisterNUICallback('formEntityProperties.placeDown',
                    function() PlaceDownEntityShortcut(true) end)
