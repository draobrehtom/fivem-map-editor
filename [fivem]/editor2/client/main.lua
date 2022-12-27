_G.Editor = {entities = {}, handlerId = {}}

function Editor.SetEnabled(state)
    state = state and true or false
    if state and CurrentSession.GetId() < 1 then return end

    if Editor.enabled == state then return end
    Editor.enabled = state

    -- SFX
    PlaySoundFrontend(-1, state and 'Hit_In' or 'Hit_Out',
                      'PLAYER_SWITCH_CUSTOM_SOUNDSET', 1)
    ShowNotification('Editor is now ' ..
                         (state and '~g~enabled' or '~r~disabled'))

    -- Initial mode
    Editor.SwitchMode(state and 'edit' or 'none')
    TriggerEvent('editor:stateChanged', state)

    DisplayInstructionalButton(288, not Editor.enabled, 'Enable Editor', 1)
end
RegisterCommand('editor', function() Editor.SetEnabled(not Editor.enabled) end)
RegisterKeyMapping('editor', 'Toggle editor', 'keyboard', 'F1')

function Editor.IsEnabled() return Editor.enabled end

function Editor.ToggleCaptureMode(state)
    state = state and true or false
    if not Editor.IsEnabled() then return end

    Editor.captureModeEnabled = state
    ThefeedFlushQueue()
    AddChatMessage('Editor screen capture mode is now ' ..
                         (state and '~g~enabled' or '~r~disabled'), 'information')
    TriggerEvent('editor:captureModeStateChanged', state)
end
RegisterCommand('capture', function()
    Editor.ToggleCaptureMode(not Editor.captureModeEnabled)
end)
RegisterKeyMapping('capture', 'Toggle editor picture mode', 'keyboard', 'O')

AddEventHandler('session:clientJoined',
                function(sessionId) Editor.SetEnabled(false) end)

AddEventHandler('session:clientLeft', function(sessionId)
    Editor.SetEnabled(false)
    DoScreenFadeOut(0)
    Wait(0)
end)

-- Client identifiying
RegisterNetEvent('editor:playerIdentified')
AddEventHandler('editor:playerIdentified', function(playerIdentifier)
    Editor.playerUId = playerIdentifier
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent('editor:playerReady')
        SetNoLoadingScreen(true)
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then Editor.SetEnabled(false) end
end)
