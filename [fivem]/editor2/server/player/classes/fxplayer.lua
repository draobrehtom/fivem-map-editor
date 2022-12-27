FxPlayer = {}
FxPlayer.__index = FxPlayer
FxPlayer.instances = {}

function FxPlayer:New(uId)
    if type(uId) ~= 'string' then return nil end
    if FxPlayer.instances[uId] then return FxPlayer.instances[uId] end

    FxPlayer.instances[uId] = setmetatable({uId = uId, data = {}}, self)
    MONGO:findOne({collection = COLLECTION_PLAYERS, query = {uId = uId}},
                    function(success, result)
        if not success then return end
        if #result < 1 then return FxPlayer.instances[uId]:Save() end
        local data = type(result[1].data) == 'table' and result[1].data or {}
        FxPlayer.instances[uId].data = data
        TriggerEvent('player:setup', uId, data)
    end)

    printlog('FxPlayer:New', 'Creating instance with identifier ' .. uId)
    return FxPlayer.instances[uId]
end

function FxPlayer:Set(key, value)
    if type(key) ~= 'string' then return end

    printlog('FxPlayer:Set', self.uId, key, value)
    self.data[key] = value
    MONGO:updateOne({
        collection = COLLECTION_PLAYERS,
        query = {uId = self.uId},
        update = {["$set"] = {data = {[key] = value}}}
    })
    TriggerEvent('player:dataChanged', FxPlayer.instances[self.uId], key,
                 value)
end

function FxPlayer:Get(key) return
    type(key) == 'string' and self.data[key] or nil end

function FxPlayer:Save()
    printlog('FxPlayer:Save', 'Saving player with identifier ' .. self.uId)
    MONGO:findOne({collection = COLLECTION_PLAYERS, query = {uId = self.uId}},
                    function(success, result)
        if not success then return end

        if #result > 0 then
            MONGO:updateOne({
                collection = COLLECTION_PLAYERS,
                query = {uId = self.uId},
                update = {["$set"] = {data = self.data}}
            }, function(success, result)
                if not success then return end
                TriggerEvent('player:updated', self.uId, self.data)
            end)
        else
            MONGO:insertOne({
                collection = COLLECTION_PLAYERS,
                document = {uId = self.uId, data = self.data}
            }, function(success, result, insertedIds)
                if not success then return end
                TriggerEvent('player:created', self.uId, self.data)
            end)
        end
    end)
end

function FxPlayer:Destroy()
    self:Save()
    FxPlayer.instances[self.uId] = nil
    self.uId = 0
end
