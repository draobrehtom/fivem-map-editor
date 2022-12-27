EditorEntity = {}
EditorEntity.__index = EditorEntity
EditorEntity.instances = {}

-- Locals
local LoadModelPromises, CreateHandlerCallbacks = {}, {}

-- Optimization
local Wait = Citizen.Wait
local IsAnEntity = IsAnEntity
local GetEntityCoords = GetEntityCoords
local CreateObjectNoOffset = CreateObjectNoOffset
local CreateVehicle = CreateVehicle
local IsModelAVehicle = IsModelAVehicle
local SetVehicleAsNoLongerNeeded = SetVehicleAsNoLongerNeeded
local DeleteEntity = DeleteEntity
local DeleteVehicle = DeleteVehicle
local DeleteObject = DeleteObject

local function CancelAwaitingPromisesOfEntity(entityEId)
    if entityEId then
        if LoadModelPromises[entityEId] then
            LoadModelPromises[entityEId]:reject()
            LoadModelPromises[entityEId] = nil
        end
        CreateHandlerCallbacks[entityEId] = nil
    end
end

function EditorEntity:Create(id)
    if type(id) ~= 'string' then
        printlog('EditorEntity:Create',
                 'Action aborted. Argument type mismatch. (id)', id)
        return nil
    end

    if EditorEntity.instances[id] then return EditorEntity.instances[id] end

    EditorEntity.instances[id] = setmetatable({id = id}, self)
    TriggerEvent('editor:entityCreated', EditorEntity.instances[id])
    return EditorEntity.instances[id]
end

function EditorEntity:DoesHandlerExist()
    return DoesEntityExist(self.objectHandler) == 1
end

function EditorEntity:HandlerIsAnEntity()
    return IsAnEntity(self.objectHandler) == 1
end

function EditorEntity:CurrentModel()
    return IsAnEntity(self.objectHandler) and
               GetEntityArchetypeName(self.objectHandler) or nil
end

function EditorEntity:MatchProperties(properties)
    if type(properties) ~= 'table' then return end

    for key, value in pairs(properties) do
        if not PROTECTED_ENTITY_KEYS[key] then self[key] = value end
    end
end

function EditorEntity:DeleteHandler()
    CancelAwaitingPromisesOfEntity(self.id)
    SetEntityAsMissionEntity(self.objectHandler, false, false)
    ClearEntityHandlerId(self.objectHandler)
    SetModelAsNoLongerNeeded(self.model)
    SafeDeleteEntity(self.objectHandler)

    if not self:DoesHandlerExist() then return end
    TriggerEvent('editor:entityHandlerDeleted', EditorEntity.instances[self.id])
end

-- Terminate all awaiting promises when entities are bulk deleted
AddEventHandler('session:preAllEntitiesDeleted', function()
    printlog('session:preAllEntitiesDeleted',
             'Rejecting all create handler promises.')
    for entityEId in pairs(CreateHandlerCallbacks) do
        CancelAwaitingPromisesOfEntity(entityEId)
    end
end)

function EditorEntity:CreateHandler()
    if self.class == 0 then return end

    if self:HandlerIsAnEntity() and self:CurrentModel() == self.model then
        printlog('EditorEntity:CreateHandler', 'Action aborted. Models matched.')
        return false
    end

    self:DeleteHandler()
    if type(CreateHandlerCallbacks[self.id]) ~= 'function' then
        CreateHandlerCallbacks[self.id] = function()
            if self:DoesHandlerExist() then
                printlog('EditorEntity:CreateHandler',
                         'Action aborted. Handler already exists.')
                return
            end

            if IsModelAVehicle(self.model) then
                self.objectHandler = CreateVehicle(self.model, self.coords.x,
                                                   self.coords.y, self.coords.z,
                                                   0.0, false, false)
            else
                self.objectHandler = CreateObjectNoOffset(self.model,
                                                          self.coords.x,
                                                          self.coords.y,
                                                          self.coords.z, false,
                                                          false, false)
            end

            if not (self.objectHandler > 0) then
                self:DeleteHandler()
                printlog('EditorEntity:CreateHandler',
                         'Could not create handler for editor entity ' ..
                             self.id .. ' (' .. self.model .. ')')
                return false
            end

            SetEntityAsMissionEntity(self.objectHandler, true, true)
            while not DoesEntityExist(self.objectHandler) do
                if not CreateHandlerCallbacks[self.id] then break end

                printlog('EditorEntity:CreateHandler',
                         'Handler still does not exist.', self.id)
                Wait(500)
            end

            StoreEntityHandlerId(self.objectHandler, self.id)
            CancelAwaitingPromisesOfEntity(self.id)
            self:UpdateHandler()
            TriggerEvent('editor:entityHandlerCreated',
                         EditorEntity.instances[self.id])

            if self.class == 3 and not self.colors then
                local primaryColor, secondaryColor = GetVehicleColours(
                                                         self.objectHandler)
                self.colors = {primaryColor, secondaryColor}
            end
        end
    end

    self.modelNotLoaded = nil
    local p = promise:new()
    LoadModel(self.model, function(result, model, message)
        if not p or model ~= self.model then return end

        if result then
            local callback =
                type(CreateHandlerCallbacks[self.id]) == 'function' and
                    CreateHandlerCallbacks[self.id] or nil
            if callback then
                p:resolve(callback())
            else
                p:resolve()
            end
        else
            p:reject()
            LoadModelPromises[self.id] = nil
        end
    end)
    LoadModelPromises[self.id] = p
    Citizen.Await(p)

    if not LoadModelPromises[self.id] or LoadModelPromises[self.id].state ~=
        PROMISE.RESOLVED then
        self:DeleteHandler()
        self.modelNotLoaded = true
        printlog('EditorEntity:CreateHandler',
                 'Action failed. Model promise was not resolved.', self.id,
                 self.model)
        return false
    end

    LoadModelPromises[self.id] = nil
    return self.objectHandler
end

function EditorEntity:UpdateHandler()
    if self.class == 0 then
        local entityId = GetClosestObjectOfType(self.coords.x, self.coords.y,
                                                self.coords.z, 0.1, self.model)
        if entityId > 0 then
            printlog('Removing world entity', entityId)
            SetEntityAsMissionEntity(entityId, true, true)
            SafeDeleteEntity(entityId)
        end
        return
    end

    if not self.objectHandler or not IsAnEntity(self.objectHandler) then
        return printlog('EditorEntity:UpdateHandler',
                        'Action aborted. Handler does not exist, or is not an entity.')
    end

    -- Coords
    SetEntityCoordsNoOffset(self.objectHandler, self.coords)

    -- Rotation
    SetEntityRotation(self.objectHandler,
                      self.rotation or vector3(0.0, 0.0, 0.0))

    -- Alpha
    SetEntityAlpha(self.objectHandler, tonumber(self.alpha) or 255)

    -- LOD
    SetEntityLodDist(self.objectHandler,
                     type(self.lod) == 'number' and self.lod ~= 0 and self.lod or
                         100)

    -- Visibility
    SetEntityVisible(self.objectHandler, self.visible == 1, 0)

    -- Freeze
    local frozen = self.frozen == 1
    if Editor.CurrentMode() == 'test' and IsModelAVehicle(self.model) then
        frozen = false
    end
    FreezeEntityPosition(self.objectHandler, frozen)

    -- Lights
    SetEntityLights(self.objectHandler, self.lights == 0)

    -- Collisions
    SetEntityCollision(self.objectHandler, self.collisions ~= 0, true)

    -- Invincibility
    SetEntityInvincible(self.objectHandler, self.invincible == 1)

    -- Dynamic
    SetEntityDynamic(self.objectHandler, self.dynamic == 1)

    -- HasGravity
    SetEntityHasGravity(self.objectHandler, self.gravity == 1)

    -- Decals
    SetObjectTextureVariation(self.objectHandler,
                              type(self.decals) == 'number' and self.decals or 0)

    -- Colors (for vehicles)
    if type(self.colors) == 'table' then
        SetVehicleColours(self.objectHandler, self.colors[1], self.colors[2])
    end

    if self.class == 1 then
        SetEntityCollision(self.objectHandler, false, false)
        if Editor.CurrentMode() == 'test' then
            SetEntityVisible(self.objectHandler, false)
        end
    end

    TriggerEvent('editor:entityHandlerUpdated', EditorEntity.instances[self.id])
end

function EditorEntity:SetModel(model, instant)
    if type(model) ~= 'string' or not IsModelValid(model) then
        return printlog('EditorEntity:SetModel',
                        'Action aborted. Model does not exist in game.', model)

    elseif model == self:CurrentModel() then
        return printlog('EditorEntity:SetModel',
                        'Action aborted. Models matched.', model)
    end

    self:DeleteHandler()
    self.model = model
    self.name = string.format("%s", self.model)
    if instant then self:CreateHandler() end
end

function EditorEntity:PlaceDown()
    if not self:DoesHandlerExist() then return end

    local yaw = GetEntityRotation(self.objectHandler).z

    -- Locate object near to the ground first
    local coords = GetEntityCoords(self.objectHandler)
    local hitPos = Raytrace(
                       vector3(coords.x, coords.y, math.max(coords.z, 500)),
                       vector3(coords.x, coords.y, -50.0), self.objectHandler,
                       true, true)
    if hitPos then
        SetEntityCoords(self.objectHandler, hitPos)
        Wait(0)
    end

    if IsModelAVehicle(self.model) then
        SetVehicleOnGroundProperly(self.objectHandler)
    else
        PlaceObjectOnGroundProperly(self.objectHandler)
    end

    if self.class == 1 then
        SetEntityRotation(self.objectHandler, 0.0, 0.0, yaw)
    end
end

local RenderDistance = 1000 * 1000
local function IsCoordNear(p1, p2)
    local diff = p2 - p1
    local distance = (diff.x * diff.x) + (diff.y * diff.y)
    return (distance < RenderDistance)
end

function EditorEntity:CheckExists(selectedEntity)
    if not self.id or self.id == 0 or self.modelNotLoaded then return end

    if self.class == 0 then return self:UpdateHandler() end

    local playerPed = GetPlayerPed(-1)
    local coords = IsFreecamActive() and GetFreecamPosition() or
                       GetEntityCoords(playerPed)
    local selectedEntity = Editor.GetSelectedEntity()
    local entityExists = self:DoesHandlerExist()
    local entityCoords = entityExists and GetEntityCoords(self.objectHandler) or
                             self.coords
    local isNear = selectedEntity and selectedEntity == self.objectHandler and
                       true or IsCoordNear(entityCoords, coords)

    if isNear and not entityExists then
        self:CreateHandler()

    elseif not isNear and entityExists then
        self:DeleteHandler()
    end
end

function EditorEntity:IsHandlerOnScreen()
    return IsEntityOnScreen(self.objectHandler) == 1
end

function EditorEntity:Delete()
    TriggerEvent('editor:entityDeleted', EditorEntity.instances[self.id])
    self:DeleteHandler()
    EditorEntity.instances[self.id] = nil
    self.id = 0
end
