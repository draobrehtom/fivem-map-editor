_G.CurrentSession = {}

local RANDOM_MODELS = {'a_m_y_skater_01', 'a_m_y_skater_02', 'a_m_y_stwhi_02'}
local DEFAULT_SPAWNPOINT = {
    coords = vector3(215, 215, 105.287),
    model = RANDOM_MODELS[math.random(#RANDOM_MODELS)],
    heading = 0
}

RegisterNetEvent('session:playerJoined')
AddEventHandler('session:playerJoined',
                function(sessionId, playerId, playerName)
    if not IsPlayerClient(playerId) then return end

    CurrentSession.id = tonumber(sessionId)
    CurrentSession.currentMap = nil
    TriggerEvent('session:clientJoined', sessionId)
end)

RegisterNetEvent('session:playerLeft')
AddEventHandler('session:playerLeft', function(sessionId, playerId, playerName)
    if not IsPlayerClient(playerId) then return end

    CurrentSession.id = -1
    TriggerEvent('session:clientLeft', sessionId)
end)

RegisterNetEvent('session:fetched')
AddEventHandler('session:fetched', function(post)
    local session = GetSessionFromId(CurrentSession.id)
    if not session then return end

    for key, value in pairs(post) do
        CurrentSession[key] = value
        TriggerEvent('session:dataChanged', key, value)
    end
end)

function CurrentSession.GetId() return CurrentSession.id or -1 end

function CurrentSession.SpawnPlayer(args, ensureSpawned)
    if CurrentSession.GetId() < 0 then return end

    printlog('CurrentSession.SpawnPlayer', 'Spawning player...')

    if type(args) ~= 'table' then args = {} end
    if type(args.coords) ~= 'vector3' then
        args.coords = DEFAULT_SPAWNPOINT.coords
    end
    if type(args.model) ~= 'string' then
        args.model = DEFAULT_SPAWNPOINT.model
    end
    if type(args.heading) ~= 'number' then
        args.heading = DEFAULT_SPAWNPOINT.heading
    end

    if ensureSpawned then CurrentSession.awaitingSpawnCallback = true end

    exports.spawnmanager:setAutoSpawnCallback(function()
        printlog('CurrentSession.SpawnPlayer', 'Calling spawnmanager...')
        exports.spawnmanager:spawnPlayer({
            x = args.coords.x,
            y = args.coords.y,
            z = args.coords.z,
            model = args.model,
            heading = args.heading
        }, function()
            CurrentSession.awaitingSpawnCallback = nil
            AddChatMessage('You have been spawned!', 'success')
        end)
    end)

    exports.spawnmanager:setAutoSpawn(true)
    exports.spawnmanager:forceRespawn()

    if ensureSpawned then
        SetTimeout(3000, function()
            if CurrentSession.awaitingSpawnCallback or not IsScreenFadedIn() then
                printlog('CurrentSession.SpawnPlayer',
                         'Player did not spawn after 3 seconds, attempting to spawn again.')
                CurrentSession.SpawnPlayer()
            end
        end)
    end
end

function CurrentSession.SpawnPlayerAtNearestSpawnpoint()
    local spawnpoint = Editor.GetNearestSpawnpoint()
    if not spawnpoint then return end

    CurrentSession.SpawnPlayer({
        coords = spawnpoint.coords,
        heading = spawnpoint.rotation.z
    })
end

function CurrentSession.MapContent()
    local coords = GetEntityCoords(PlayerPedId())
    local entities = {}
    local statistics = {
        removeWorlds = 0,
        spawnpoints = 0,
        objects = 0,
        vehicles = 0
    }

    for entityEId, entityInstance in pairs(Editor.entities) do
        table.insert(entities, {
            id = entityEId,
            class = entityInstance.class,
            name = tostring(entityInstance.name),
            locked = entityInstance.locked
        })

        if entityInstance.class == 0 then
            statistics.removeWorlds = statistics.removeWorlds + 1

        elseif entityInstance.class == 1 then
            statistics.spawnpoints = statistics.spawnpoints + 1

        elseif entityInstance.class == 2 then
            statistics.objects = statistics.objects + 1

        elseif entityInstance.class == 3 then
            statistics.vehicles = statistics.vehicles + 1
        end
    end

    table.sort(entities, function(a, b) return a.class < b.class end)
    return entities, statistics
end

AddEventHandler('session:clientJoined',
                function(sessionId) CurrentSession.SpawnPlayer() end)

AddEventHandler('playerSpawned',
                function() CurrentSession.awaitingSpawnCallback = nil end)
