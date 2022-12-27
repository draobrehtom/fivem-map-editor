function ApplyEntityPosition(entity, posX, posY, posZ, relativeToWorld)
    if posX == 0.0 and posY == 0.0 and posZ == 0.0 then return end
    local offset = vector3(posX, posY, posZ)
    if relativeToWorld then
        local position = GetEntityCoords(entity) + offset
        SetEntityCoordsNoOffset(entity, position)
    else
        local position = GetOffsetFromEntityInWorldCoords(entity, offset)
        SetEntityCoordsNoOffset(entity, position)
    end
end

function GetEntityTypeString(entity)
    local typeFromId = {[1] = 'ped', [2] = 'vehicle', [3] = 'object'}
    local type = GetEntityType(entity)
    return type and typeFromId[type] or nil
end

function IsEntityAnObject(entity) return GetEntityType(entity) == 2 end

function CanSelectEntity(entity)
    local validIds = {[2] = true, [3] = true}
    local type = GetEntityType(entity)
    return type and validIds[type] or false
end

function GetEntityClassName(class)
    local nameFromId = {[1] = 'spawnpoint', [2] = 'object', [3] = 'vehicle'}
    return nameFromId[class] or nil
end

function GetEntityDimensions(entity)
    local box = GetEntityBoundingBox(entity)
    return math.abs(box[2].x - box[1].x), math.abs(box[3].y - box[2].y),
           math.abs(box[6].z - box[2].z)
end

function IsEntityModelAVehicle(model)
    return model and GetDisplayNameFromVehicleModel(model) ~= 'CARNOTFOUND' and
               true or false
end

local LastRequestedModel

function LoadModel(model, callback)
    if type(model) ~= 'string' then
        return callback(false, model, 'There was no valid model specified.')

    elseif not IsModelInCdimage(model) then
        return callback(false, model,
                        'Model ' .. model .. ' cannot be previewed.')

    elseif HasModelLoaded(model) then
        return callback(true, model)
    end

    RequestModel(model)
    LastRequestedModel = model
    local delay = 0
    printlog('LoadModel', 'Loading model ' .. model)
    while not HasModelLoaded(model) do
        if LastRequestedModel ~= model then break end

        Wait(50)
        delay = delay + 50
        if delay > 5000 then
            return callback(false, model,
                            'Model could not load after 5 seconds.')
        end
    end
    local loaded = HasModelLoaded(model) == 1
    if loaded then
        printlog('LoadModel',
                 'Loaded model ' .. model .. ' after ' .. delay .. ' ms')
    end
    return callback(loaded, model)
end
