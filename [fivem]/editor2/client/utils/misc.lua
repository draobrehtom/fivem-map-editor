function GetBoundingBox(min, max, pad)
    local pad = pad or 0.001
    return {
        -- Bottom
        vector3(min.x - pad, min.y - pad, min.z - pad), -- back right
        vector3(max.x + pad, min.y - pad, min.z - pad), -- back left
        vector3(max.x + pad, max.y + pad, min.z - pad), -- front left
        vector3(min.x - pad, max.y + pad, min.z - pad), -- front right
        -- Top
        vector3(min.x - pad, min.y - pad, max.z + pad), -- back right
        vector3(max.x + pad, min.y - pad, max.z + pad), -- back left
        vector3(max.x + pad, max.y + pad, max.z + pad), -- front left
        vector3(min.x - pad, max.y + pad, max.z + pad) -- front right
    }
end

function GetBoundingBoxEdgeMatrix(box)
    return {
        -- Bottom
        {box[1], box[2]}, {box[2], box[3]}, {box[3], box[4]}, {box[4], box[1]},

        -- Top
        {box[5], box[6]}, {box[6], box[7]}, {box[7], box[8]}, {box[8], box[5]},

        -- Sides
        {box[1], box[5]}, {box[2], box[6]}, {box[3], box[7]}, {box[4], box[8]}
    }
end

function GetBoundingBoxPolyMatrix(box)
    return {
        -- Bottom
        {box[3], box[2], box[1]}, {box[4], box[3], box[1]}, -- Top
        {box[5], box[6], box[7]}, {box[5], box[7], box[8]}, -- Front
        {box[3], box[4], box[7]}, {box[8], box[7], box[4]}, -- Back
        {box[1], box[2], box[5]}, {box[6], box[5], box[2]}, -- Left
        {box[2], box[3], box[6]}, {box[3], box[7], box[6]}, -- Right
        {box[5], box[8], box[4]}, {box[5], box[4], box[1]}
    }
end

function GetModelBoundingBox(model)
    local min, max = GetModelDimensions(model)
    return GetBoundingBox(min, max)
end

function GetEntityBoundingBox(entity)
    local model = GetEntityModel(entity)
    local box = GetModelBoundingBox(model)
    return map(box, function(corner)
        return GetOffsetFromEntityInWorldCoords(entity, corner)
    end)
end

function Clamp(x, min, max) return math.min(math.max(x, min), max) end

function SnapAngle(angle, snap)
    return math.floor(angle / 360 * snap + 0.5) % snap * (360 / snap)
end

function GetVisibleEntities()
    local entities = {}
    local iterators = {
        EnumerateObjects, EnumeratePeds, EnumerateVehicles, EnumeratePickups
    }
    for Enumerate in values(iterators) do
        for entity in Enumerate() do table.insert(entities, entity) end
    end
    return entities
end

function IsEntityModelBlacklisted(entity)
    local model = GetEntityModel(entity)
    local blacklist = {
        -- https://i.gyazo.com/099abb816415bda4e1c6bf99c58ac3a2.jpg
        [GetHashKey('prop_sprink_park_01')] = true
    }
    return blacklist[model] or false
end

function CanEntityReturnModel(entity)
    return IsEntityAnObject(entity) or IsEntityAVehicle(entity) or
               IsEntityAPed(entity) or DoesEntityHaveDrawable(entity)
end

function IsEntityTargetable(entity)
    return CanEntityReturnModel(entity) and not IsEntityModelBlacklisted(entity)
end
