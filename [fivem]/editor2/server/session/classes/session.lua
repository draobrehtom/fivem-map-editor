Session = {}
Session.__index = Session
Session.instances = {}

local function GetNextSessionId()
    local id = 1
    while Session.instances[id] ~= nil do id = id + 1 end
    return id
end

function Session:New(config)
    config = SafeSessionConfig(config)
    if type(config) ~= 'table' then
        printlog('Session:New',
                 'Action aborted. Invalid or missing argument(s).', config)
        return nil
    end

    local id
    if type(config.id) == 'number' then
        if Session.instances[config.id] then
            return Session.instances[config.id]
        end
        id = config.id
    else
        id = GetNextSessionId()
    end

    printlog('Session:New', 'Creating session instance with id ' .. id)
    config.ownerId = config.ownerId or -1
    config.displayColor = config.displayColor or
                              RGBToHex(math.random(255), math.random(255),
                                       math.random(255))

    local session = setmetatable({
        id = id,
        routingBucket = id,
        entities = {},
        entityController = {},
        players = {},
        dataToSync = {
            ['id'] = true,
            ['players'] = true,
            ['ownerId'] = true,
            ['ownerName'] = true,
            ['currentMap'] = true,
            ['environment'] = true
        }
    }, self)

    for key, value in pairs(config) do
        if type(session[key]) == 'nil' then
            session[key] = value
            session:SyncKey(key, true)
        end
    end

    Session.instances[id] = session
    session:Fetch()
    return session
end

function Session:SyncKey(key, state)
    if type(key) ~= 'string' or type(self[key]) == 'nil' or key == 'password' then
        return
    end
    self.dataToSync[key] = state
end

function Session:FetchContent(keys)
    local post = {}
    keys = type(keys) == 'table' and keys or nil

    for key, value in pairs(self) do
        if (keys and keys[key]) or (not keys and self.dataToSync[key]) then
            post[key] = value
        end
    end

    if not keys then
        post.secure = type(self.password) == 'string' and
                          string.len(self.password) > 0
    end
    return post
end

function Session:Fetch(playerId, keys)
    local post = self:FetchContent(keys)

    if playerId and self.players[playerId] then
        TriggerClientEvent('session:fetched', playerId, post)
        return
    end

    for playerId in pairs(self.players) do
        TriggerClientEvent('session:fetched', playerId, post)
    end
end

function Session:Set(key, value)
    if type(key) == 'string' and key ~= 'id' then
        self[key] = value
        if self.dataToSync[key] then self:Fetch(-1, {[key] = true}) end
    end
end

function Session:Get(key) return type(key) == 'string' and self[key] or nil end

function Session:GetCurrentPlayerCount()
    local count = 0
    for playerId in pairs(self.players) do count = count + 1 end
    return count
end

function Session:AddPlayer(playerId)
    playerId = tonumber(playerId)
    if not playerId or self.players[playerId] then return end

    self.players[playerId] = GetPlayerName(playerId)
    SetPlayerRoutingBucket(playerId, self.routingBucket)
    printlog('Session:AddPlayer',
             'Player ' .. self.players[playerId] .. ' joined session ' ..
                 self.id .. ' [' .. self.name .. ']')

    -- server
    TriggerEvent('session:playerJoined', Session.instances[self.id], playerId)

    -- client
    TriggerClientEvent('session:playerJoined', -1, self.id, playerId,
                       self.players[playerId])
    self:Fetch()

    -- sync
    self:SyncAllEntities(playerId)
    return true
end

function Session:RemovePlayer(playerId)
    playerId = tonumber(playerId)
    if not playerId then return end

    -- server
    TriggerEvent('session:playerLeft', Session.instances[self.id], playerId)

    printlog('Session:RemovePlayer',
             'Player ' .. self.players[playerId] .. ' left session ' .. self.id ..
                 ' [' .. self.name .. ']')
    self:FreeEntitiesControlled(playerId)
    self.players[playerId] = nil
    ResetPlayerRoutingBucket(playerId)

    -- client
    TriggerClientEvent('session:playerLeft', -1, self.id, playerId,
                       self.players[playerId])

    self:Fetch()
    return true
end

function Session:GetNextEntityId(class)
    local prefix = 'entity'
    if class == 0 then
        prefix = 'remove_world'

    elseif class == 1 then
        prefix = 'spawnpoint'

    elseif class == 2 then
        prefix = 'object'

    elseif class == 3 then
        prefix = 'vehicle'
    end
    
    local id = 1
    while self.entities[string.format("%s_%d", prefix, id)] ~= nil do
        id = id + 1
    end

    return string.format("%s_%d", prefix, id)
end

function Session:RegisterEntity(properties)
    if type(properties) ~= 'table' or type(properties.class) ~= 'number' or
        type(properties.coords) ~= 'vector3' then
        printlog('Session:RegisterEntity', self.id,
                 'Action aborted. Invalid or missing argument(s).')
        return nil
    end

    local entityEId = self:GetNextEntityId(properties.class)
    local entityInstance = {}
    for key, value in pairs(properties) do
        if not PROTECTED_ENTITY_KEYS[key] then
            entityInstance[key] = value
        end
    end

    entityInstance.id = entityEId
    entityInstance.class = properties.class

    self.entities[entityEId] = entityInstance
    return entityInstance
end

function Session:GetEntityFromId(entityEId)
    return entityEId and self.entities[entityEId] or nil
end

function Session:SyncAllEntities(playerId)
    if playerId == -1 then
        for playerId in pairs(self.players) do
            TriggerClientEvent('session:createEntities', playerId, self.entities)
        end
        return
    elseif playerId and self.players[playerId] then
        TriggerClientEvent('session:createEntities', playerId, self.entities)
    end
end

function Session:SyncEntity(playerId, entityEId, selectEntity, dragEntity)
    playerId = tonumber(playerId)
    if not playerId then return end

    local entityInstance = entityEId and self.entities[entityEId] or nil
    if not entityInstance then return end

    local controllerId = self.entities[entityEId].controllerId or -1

    -- to a specific player
    if self.players[playerId] then
        printlog('Session:SyncEntity',
                 'Syncing entity ' .. entityEId .. ' to player ' ..
                     self.players[playerId] .. ' in session ' .. self.id)

        -- when specified player is also the controller
        local isController = controllerId == playerId
        TriggerClientEvent('session:syncEntity', playerId, entityInstance,
                           isController and selectEntity or nil,
                           isController and dragEntity or nil)

        -- to everyone from session
    elseif playerId == -1 then
        printlog('Session:SyncEntity',
                 'Syncing entity ' .. entityEId .. ' in session ' .. self.id)

        for _playerId in pairs(self.players) do
            local isController = controllerId == playerId
            TriggerClientEvent('session:syncEntity', _playerId, entityInstance,
                               isController and selectEntity or nil,
                               isController and dragEntity or nil)
        end
    end
end

function Session:SetEntityController(entityEId, playerId)
    playerId = tonumber(playerId)
    if type(entityEId) ~= 'string' or not self.entities[entityEId] then
        return
    end

    if playerId and self.players[playerId] then
        self.entityController[entityEId] = playerId
        printlog('Session:SetEntityController',
                 'Entity ' .. entityEId .. ' in session ' .. self.id ..
                     ' is now controlled by ' .. self.players[playerId])
        return true, playerId

        -- Reset
    elseif playerId and self.entityController[entityEId] == playerId then
        self.entityController[entityEId] = nil
        printlog('Session:SetEntityController',
                 'Entity ' .. entityEId .. ' in session ' .. self.id ..
                     ' is not controlled anymore.')
        return false, nil
    end
end

function Session:FreeEntitiesControlled(playerId)
    playerId = tonumber(playerId)
    if not playerId or not self.players[playerId] then return end

    for entityEId in pairs(self.entityController) do
        if self.entityController[entityEId] == playerId then
            self.entityController[entityEId] = nil
        end
    end
end

function Session:GetEntityController(entityEId)
    return entityEId and self.entityController[entityEId] or nil
end

function Session:DeleteEntity(entityEId)
    if type(entityEId) ~= 'string' or not self.entities[entityEId] then
        return
    end

    self.entities[entityEId] = nil
    self.entityController[entityEId] = nil

    for playerId in pairs(self.players) do
        TriggerClientEvent('session:deleteEntity', playerId, entityEId)
    end
end

function Session:DeleteAllEntities()
    self.entities = {}
    self.entityController = {}

    -- sync with players from session
    for playerId in pairs(self.players) do
        TriggerClientEvent('session:deleteEntities', playerId)
    end
end

function Session:AddChatMessage(messageText, messageType)
    for playerId in pairs(self.players) do
        AddChatMessage('* ' .. messageText, playerId, messageType)
    end
end

function Session:Destroy()
    for playerId in pairs(self.players) do self:RemovePlayer(playerId) end

    TriggerClientEvent('session:removed', -1, self.id)
    Session.instances[self.id] = nil
    self.id = 0
end

RegisterNetEvent('editor:playerReady')
AddEventHandler('editor:playerReady', function()
    local playerId = tonumber(source)
    for _, session in pairs(Session.instances) do session:Fetch(playerId) end
end)

function Session:SendWhitelistToPlayer(playerId)
    printlog('Session:SendWhitelistToPlayer',
             'Sending whitelist for session ' .. self.id .. ' to player ' ..
                 GetPlayerName(playerId))

    local playerInstance = GetPlayerInstanceFromPlayerId(playerId)
    local playerUId = playerInstance and playerInstance.uId or nil

    if not playerUId or self.ownerId ~= playerUId then
        TriggerClientEvent('session:receiveWhitelist', playerId, 1)
        return
    end

    MONGO:find({
        collection = COLLECTION_PLAYERS,
        query = {},
        options = {projection = {_id = 0, uId = 1, data = 1}}
    }, function(success, result)
        if not success then return end

        local players = result
        if playerUId then
            for k, player in pairs(players) do
                if player.uId == playerUId then
                    table.remove(players, k)
                    break
                end
            end
        end

        MONGO:findOne({
            collection = COLLECTION_SESSIONS,
            query = {id = self.id},
            options = {projection = {_id = 0, whitelist = 1}}
        }, function(success, result)
            if not success then return end

            local whitelist = type(result[1].whitelist) == 'table' and
                                  result[1].whitelist or {}
            TriggerClientEvent('session:receiveWhitelist', playerId, 0, players,
                               whitelist, self:Get('whitelistDisabled'))
        end)
    end)
end

function Session:ToggleWhitelist(state)
    printlog('Session:ToggleWhitelist',
             'Setting whitelist disabled state for session ' .. self.id ..
                 ' as ' .. tostring(state))
    self:Set('whitelistDisabled', state)
end

function Session:SaveWhitelist(whitelist, callback)
    if type(whitelist) ~= 'table' then return end

    printlog('Session:SaveWhitelist',
             'Updating whitelist for session ' .. self.id)
    MONGO:updateOne({
        collection = COLLECTION_SESSIONS,
        query = {id = self.id},
        update = {["$set"] = {whitelist = whitelist}}
    }, function(success, result)
        if not success then return end

        if type(callback) == 'function' then callback() end
        printlog('Session:SaveWhitelist',
                 'Updated whitelist for session ' .. self.id)
    end)
end

function Session:SendMapNamesToPlayer(playerId)
    if playerId == -1 or (playerId and self.players[playerId]) then
        MONGO:find({
            collection = COLLECTION_MAPS,
            query = {session = self.id},
            options = {
                projection = {_id = 0, name = 1, meta = 1, lastSaved = 1}
            }
        }, function(success, result)
            if not success then return end
            if playerId == -1 then
                for playerId in pairs(self.players) do
                    TriggerClientEvent('session:receiveMapNames', playerId,
                                       result)
                end
            else
                TriggerClientEvent('session:receiveMapNames', playerId, result)
            end
        end)
    end
end

function Session:LoadMap(name)
    if self:CurrentMap() then
        printlog('Session:LoadMap', self.id,
                 'Action aborted. A map is already loaded.')
        self:AddChatMessage(
            'Before loading a map, current map should be unloaded.', 'error')
        return false
    end

    if type(name) ~= 'string' then
        printlog('Session:LoadMap', self.id,
                 'Action aborted. Invalid or missing argument. (name)')
        return false
    end

    MONGO:findOne({
        collection = COLLECTION_MAPS,
        query = {session = self.id, name = name},
        options = {
            projection = {
                _id = 0,
                name = 1,
                meta = 1,
                content = 1,
                lastSaved = 1
            }
        }
    }, function(success, result)
        if not success then return end

        self:DeleteAllEntities()

        if #result > 0 then
            local content = json.decode(result[1].content)
            if type(content) == 'table' then
                for _, entity in pairs(content) do
                    entity.coords = type(entity.coords) == 'table' and
                                        vector3(entity.coords.x,
                                                entity.coords.y, entity.coords.z) or
                                        vector3(0, 0, 0)
                    entity.rotation = type(entity.rotation) == 'table' and
                                          vector3(entity.rotation.x,
                                                  entity.rotation.y,
                                                  entity.rotation.z) or
                                          vector3(0, 0, 0)
                    self:RegisterEntity(entity)
                end
                self:Set('currentMap', {
                    name = name,
                    meta = result[1].meta,
                    lastSaved = result[1].lastSaved or 'never'
                })
                self:SyncAllEntities(-1)
                printlog('Session:LoadMap', 'Loaded and synced map ' .. name ..
                             ' in session ' .. self.id)
                self:AddChatMessage('Successfuly loaded map ' .. name .. '.',
                                    'success')
            end
        else
            printlog('Session:LoadMap', 'Map ' .. name ..
                         ' map was not found in session ' .. self.id)
            self:AddChatMessage('Failed to load map ' .. name ..
                                    ', it was not found.', 'error')
        end
    end)
end

function Session:CurrentMap()
    return self.currentMap and self.currentMap ~= 0 and self.currentMap or nil
end

function Session:CurrentMapContent()
    local content = {}
    for _, entity in pairs(self.entities) do
        local entry = {}
        for key, value in pairs(entity) do
            if not KEYS_TO_NOT_EXPORT[key] then entry[key] = value end
        end
        table.insert(content, entry)
    end
    return json.encode(content)
end

function Session:SaveCurrentMap(name, meta, forced)
    local currentMap = self:CurrentMap()
    local name = name or (currentMap and currentMap.name) or nil
    local meta = type(meta) == 'table' and meta or
                     (currentMap and currentMap.meta) or {}

    if type(name) ~= 'string' or string.len(name) < 4 then
        printlog('Session:SaveCurrentMap',
                 'Action aborted. Name is either invalid or too short.')
        return false
    end

    meta.author = meta.author or ''
    meta.description = meta.description or ''

    local contentJSON = self:CurrentMapContent()
    MONGO:findOne({
        collection = COLLECTION_MAPS,
        query = {session = self.id, name = name}
    }, function(success, result)
        if not success then return end

        local saved
        if #result > 0 then
            MONGO:updateOne({
                collection = COLLECTION_MAPS,
                query = {session = self.id, name = name},
                update = {
                    ["$set"] = {
                        meta = meta,
                        content = contentJSON,
                        lastSaved = GetDateTime()
                    }
                }
            }, function(success, result)
                if not success or forced then return end
                self:AddChatMessage('Saved current map as: ' .. name, 'success')
                self:Set('currentMap', {name = name, meta = meta})
            end)
        else
            MONGO:insertOne({
                collection = COLLECTION_MAPS,
                document = {
                    session = self.id,
                    name = name,
                    meta = meta,
                    content = contentJSON,
                    lastSaved = GetDateTime()
                }
            }, function(success, result)
                if not success or forced then return end
                self:AddChatMessage('Saved current map as: ' .. name, 'success')
                self:Set('currentMap', {name = name, meta = meta})
            end)
        end
    end)
    return true
end

function Session:UnloadCurrentMap()
    if not self:CurrentMap() then
        printlog('Session:UnloadCurrentMap', self.id,
                 'Action aborted. No map is loaded at the moment.')
        return false
    end

    local name = self:CurrentMap().name
    printlog('Session:UnloadCurrentMap',
             'Unloading map ' .. name .. ' in session ' .. self.id)
    self:SaveCurrentMap(nil, nil, true)
    self:DeleteAllEntities()
    self:Set('currentMap', 0)
    self:AddChatMessage('Unloaded map: ' .. tostring(name), 'information')
end

function Session:SetEnvironmentVariable(key, value)
    if key == 'weather' then
        local weather = tonumber(value)
        if weather and WEATHER_FROM_NUMBER[weather] then
            local environment = self:Get('environment') or {}
            if environment.weather and environment.weather == weather then
                return
            end

            environment.weather = weather
            self:SyncKey('environment', true)
            self:Set('environment', environment)
            self:AddChatMessage('Session weather was set to: ' ..
                                    WEATHER_FROM_NUMBER[weather])
            printlog('Session:SetEnvironmentVariable', self.id, key, value)
        end

    elseif key == 'time' and type(value) == 'table' then
        local h, m = tonumber(value.hour), tonumber(value.minute)
        if (h and h >= 0 and h <= 23) and (m and m >= 0 and m <= 59) then
            local environment = self:Get('environment') or {}
            if environment.time and environment.time.hour == h and
                environment.time.minute == m then return end

            environment.time = {hour = h, minute = m}
            self:SyncKey('environment', true)
            self:Set('environment', environment)
            self:AddChatMessage('Session time was set to ' .. h .. ':' .. m)
            printlog('Session:SetEnvironmentVariable', self.id, key, value)
        end
    end
end

function Session:Save(callback)
    local document = {}
    for key in pairs({
        ['id'] = true,
        ['name'] = true,
        ['maximumSlots'] = true,
        ['password'] = true,
        ['ownerId'] = true,
        ['ownerName'] = true,
        ['displayColor'] = true,
        ['environment'] = true,
        ['whitelistDisabled'] = true
    }) do document[key] = self[key] end

    printlog('Session:Save', 'Saving session ' .. self.id)
    MONGO:findOne({collection = COLLECTION_SESSIONS, query = {id = self.id}},
                  function(success, result)
        if not success then return end
        if #result > 0 then
            MONGO:updateOne({
                collection = COLLECTION_SESSIONS,
                query = {id = self.id},
                update = {["$set"] = document}
            }, function(result)
                if not result then return end

                if type(callback) == 'function' then
                    callback(self)
                end
            end)
        else
            MONGO:insertOne({
                collection = COLLECTION_SESSIONS,
                document = document
            }, function(result)
                if not result then return end

                if type(callback) == 'function' then
                    callback(self)
                end
            end)
        end
    end)
end

function Session:Delete()
    printlog('Session:Delete', 'Deleting session ' .. self.id .. ' permanently')
    MONGO:update({
        collection = COLLECTION_MAPS,
        query = {session = self.id},
        update = {["$set"] = {session = 0, ownerId = self.ownerId}}
    })
    MONGO:deleteOne({collection = COLLECTION_SESSIONS, query = {id = self.id}})
    self:Destroy()
end

function Session:ExportMapForPlayer(playerId, mapName)
    if playerId and self.players[playerId] then
        printlog('Session:ExportMapForPlayer', playerId, mapName)
        MONGO:findOne({
            collection = COLLECTION_MAPS,
            query = {session = self.id, name = mapName},
            options = {
                projection = {
                    _id = 0,
                    name = 1,
                    meta = 1,
                    content = 1,
                    lastSaved = 1
                }
            }
        }, function(success, result)
            if not success then return end

            if #result > 0 then
                self:AddChatMessage(self.players[playerId] ..
                                        ' is exporting map: ' .. mapName,
                                    'information')
                SendContentToPlayer(playerId, mapName, result[1].meta,
                                    result[1].content)
                return
            end
        end)
    end
end
