-- Locals
local Blips = {}

local function AddBlipForPlayer(playerServerId)
    local playerClientId = GetPlayerFromServerId(playerServerId)
    if not playerClientId or playerClientId == -1 or
        (Blips[playerServerId] and DoesBlipExist(Blips[playerServerId])) then
        return
    end

    local ped = GetPlayerPed(playerClientId)
    if ped == 0 or not ped then return end

    printlog('AddBlipForPlayer', playerServerId, playerClientId)
    local blip = AddBlipForEntity(ped)
    SetBlipAsFriendly(blip, true)
    Blips[playerServerId] = blip
end

local function RemoveBlipForPlayer(playerServerId)
    if not playerServerId or not Blips[playerServerId] then return end

    printlog('RemoveBlipForPlayer', playerServerId,
             GetPlayerFromServerId(playerServerId), Blips[playerServerId])

    RemoveBlip(Blips[playerServerId])
    Blips[playerServerId] = nil
end

local function RemoveAllBlips()
    for playerServerId in pairs(Blips) do RemoveBlipForPlayer(playerServerId) end
    Blips = {}
end
AddEventHandler('session:clientLeft', RemoveAllBlips)

AddEventHandler('session:clientJoined', function()
    CreateThread(function()
        while true do
            local currentSession = GetSessionFromId(CurrentSession.GetId())
            if not currentSession then
                RemoveAllBlips()
                return

            else
                -- Remove unnecessary blips
                for playerServerId in pairs(Blips) do
                    if not currentSession.players[playerServerId] then
                        RemoveBlipForPlayer(playerServerId)
                    end
                end

                -- Add missing
                for playerServerId in pairs(currentSession.players) do
                    local playerClientId = GetPlayerFromServerId(playerServerId)
                    if not IsPlayerClient(playerServerId) then
                        AddBlipForPlayer(playerServerId)
                    end
                end
            end
            Wait(1000)
        end
    end)
end)
