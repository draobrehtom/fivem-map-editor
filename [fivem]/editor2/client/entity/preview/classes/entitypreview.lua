EntityPreview = {}
EntityPreview.__index = EntityPreview
EntityPreview.instances = {}

-- Locals
local ActiveThreads = {}

-- Optimization
local GetFrameTime = GetFrameTime
local GetEntityRotation = GetEntityRotation
local SetEntityRotation = SetEntityRotation
local Wait = Citizen.Wait

function EntityPreview:New(model, coords)
    if type(model) ~= 'string' or type(coords) ~= 'vector3' then
        printlog('EntityPreview:New',
                 'Action aborted. Invalid or missing argument(s).')
        return nil
    end

    local id = #EntityPreview.instances + 1
    EntityPreview.instances[id] = setmetatable({id = id, coords = coords}, self)

    -- Create instance object initially
    EntityPreview.instances[id]:SetModel(model)

    if not ActiveThreads['EntityPreviewRender'] then
        ActiveThreads['EntityPreviewRender'] =
            EditorThread:Create({
                callFunction = function()
                    local yaw = GetFrameTime() * 20
                    for i, previewInstance in pairs(EntityPreview.instances) do
                        if previewInstance.objectHandler then
                            local rotation = GetEntityRotation(
                                                 previewInstance.objectHandler).z
                            SetEntityRotation(previewInstance.objectHandler,
                                              0.0, 0.0, rotation + yaw, false)
                        end
                    end
                end
            })
    end
    ActiveThreads['EntityPreviewRender']:Run()

    return EntityPreview.instances[id]
end

function EntityPreview:DeleteHandler()
    self.model = nil
    self.awaitingModel = nil
    self.loadModelCallback = nil
    self.createHandlerFunction = nil
    SetModelAsNoLongerNeeded(self.model)
    SafeDeleteEntity(self.objectHandler)
    Wait(0)

    if self.loadModelPromise then
        printlog('EntityPreview:DeleteHandler', 'Cancelling previous promise')
        if type(self.loadModelPromise.reject) == 'function' then
            self.loadModelPromise:reject()
        end
        self.loadModelPromise = nil
    end
end

function EntityPreview:SetModel(model)
    if type(model) ~= 'string' or self.model == model or self.awaitingModel then
        return false
    end

    if not IsModelInCdimage(model) then
        AddNotification('Entity Preview',
                        'Model ' .. tostring(model) .. ' cannot be previewed.')
        return false
    end

    printlog('EntityPreview:SetModel', model)
    self:DeleteHandler()
    self.awaitingModel = model
    self.createHandlerFunction = function()
        if IsAnEntity(self.objectHandler) or DoesEntityExist(self.objectHandler) then
            printlog('EntityPreview:SetModel',
                     'Action aborted. Handler does already exist.')
            return false
        end

        if model ~= self.awaitingModel or model == self.model then return end

        if IsEntityModelAVehicle(model) then
            self.objectHandler = CreateVehicle(model, self.coords.x,
                                               self.coords.y, self.coords.z,
                                               0.0, false, true)
        else
            self.objectHandler = CreateObjectNoOffset(model, self.coords.x,
                                                      self.coords.y,
                                                      self.coords.z, false,
                                                      false, false)
        end

        if not (self.objectHandler > 0) then
            self:DeleteHandler()
            printlog('EntityPreview:SetModel',
                     'Could not create handler for model ' .. model)
            AddNotification('Entity Preview', 'Model ' .. tostring(model) ..
                                ' could not be created.')
            return false
        end

        self.model = model
        local w, d, h = GetEntityDimensions(self.objectHandler)
        local distance = math.max(math.max(w, d), h)
        if distance < 10.0 then distance = distance + 10.0 end
        local target = GetFreecamTarget(distance)
        SetEntityCoordsNoOffset(self.objectHandler, target)

        if IsAnEntity(self.objectHandler) then
            FreezeEntityPosition(self.objectHandler, true)
            SetEntityCollision(self.objectHandler, false, true)
            return true
        end

        printlog('EntityPreview:SetModel', 'Action failed.', model)
        AddNotification('Entity Preview',
                        'Could not create entity with model ' .. tostring(model))
        self:DeleteHandler()
        return false
    end

    local p = promise:new()
    self.loadModelCallback = function(result, model, message)
        if result and self.awaitingModel == model then
            local callback = type(self.createHandlerFunction) == 'function' and
                                 self.createHandlerFunction or nil
            if callback then
                p:resolve(callback())
            else
                p:resolve()
            end
        else
            p:reject()
            if message then
                AddNotification('Entity Preview', 'Could not preview model. ' ..
                                    tostring(message))
            end
        end
        self.awaitingModel = nil
        self.loadModelCallback = nil
    end
    LoadModel(model, self.loadModelCallback)
    self.loadModelPromise = p
    Citizen.Await(p)
end

function EntityPreview:Destroy()
    self:DeleteHandler()
    EntityPreview.instances[self.id] = nil
    self.id = 0

    local count = 0
    for k in pairs(EntityPreview.instances) do k = k + 1 end

    if k == 0 and ActiveThreads['EntityPreviewRender'] then
        ActiveThreads['EntityPreviewRender']:Terminate()
    end
end
