-- Locals
local ActiveThreads = {}
local TestVehicle

AddEventHandler('editor:modeChanged', function(modeOld, modeNew)
    -- From anything to 'test'
    if modeNew == 'test' then
        ShowNotification('~b~Entering ~s~test mode... This may take a while.')
        DoScreenFadeOut(0)
        Wait(0)
        CurrentSession.RestoreEntities()
        CurrentSession.SpawnPlayerAtNearestSpawnpoint()
        ShowNotification(
            '~b~Editor Test Mode ~s~is now ~g~enabled~s~. Hit ~o~F5 ~s~to exit.')
        ActiveThreads['TestModeText'] = ActiveThreads['TestModeText'] or
                                            EditorThread:Create({
                callFunction = function()
                    local ped = PlayerPedId()
                    local vehicle = ped and GetVehiclePedIsIn(ped, false) or 0
                    if vehicle and vehicle > 0 and
                        (not TestVehicle or not (TestVehicle > 0)) then
                        TestVehicle = vehicle
                        NetworkRegisterEntityAsNetworked(vehicle)
                        printlog('Networking test vehicle', vehicle)
                    end
                    DrawDebugText(0.8, 0.08,
                                  'You are currently in ~b~Editor Test Mode')
                end
            }):Run()

        DisplayInstructionalButton(318, true, 'Exit Test Mode', 1)
        -- From 'test' to 'none'
    else
        if ActiveThreads['TestModeText'] then
            ActiveThreads['TestModeText']:Terminate()
            ActiveThreads['TestModeText'] = nil
            TestVehicle = 0
        end

        if modeOld == 'test' then
            ShowNotification(
                '~y~Quitting ~s~test mode... This may take a while.')

            -- From 'test' to 'none'
            if modeNew == 'none' and CurrentSession.GetId() > 0 then
                DoScreenFadeOut(0)
                Wait(0)
                CurrentSession.RestoreEntities()
                DoScreenFadeIn(0)
                Wait(0)
            end
            ShowNotification('~b~Editor Test Mode ~s~is now ~r~disabled~s~')
        end

        if modeNew == 'edit' then
            DisplayInstructionalButton(318, true, 'Enter Test Mode', 1)
        else
            DisplayInstructionalButton(318, false)
        end
    end
end)

local function ToggleTestModeShortcut()
    if Editor.CurrentMode() == 'test' then
        Editor.SwitchMode('edit')
    elseif Editor.CurrentMode() == 'edit' then
        if #Editor.GetCurrentSpawnpoints() > 0 then
            Editor.SwitchMode('test')
        else
            ShowNotification(
                '~r~You cannot enter ~s~test mode at the moment, place a spawnpoint first.')
        end
    end
end
RegisterCommand('test', ToggleTestModeShortcut)
RegisterKeyMapping('test', 'Toggle editor test mode', 'keyboard', 'F5')

AddEventHandler('session:clientJoined', function()
    CreateThread(function()
        while true do
            local currentSession = GetSessionFromId(CurrentSession.GetId())
            if not currentSession then return end

            local vehicles = {}
            for _, entityInstance in pairs(Editor.entities) do
                if entityInstance.class == 3 then
                    table.insert(vehicles, entityInstance.objectHandler)
                end
            end

            for playerServerId in pairs(currentSession.players) do
                local playerClientId = GetPlayerFromServerId(playerServerId)
                if not IsPlayerClient(playerServerId) then
                    local ped = GetPlayerPed(playerClientId)
                    if ped > 0 then
                        local vehicle = GetVehiclePedIsIn(ped, false) or 0
                        if vehicle and vehicle > 0 then
                            for _, _vehicle in pairs(vehicles) do
                                if _vehicle ~= vehicle then
                                    SetEntityNoCollisionEntity(_vehicle,
                                                               vehicle, false)
                                end
                            end
                        end
                    end
                end
            end
            Wait(0)
        end
    end)
end)
