_G.NUI = {visible = false}

function NUI.SetVisible(state)
    state = state and true or false
    if NUI.visible == state then return end

    NUI.visible = state

    NUI.Call('nui.display', {state = state and 1 or 0})
    ThefeedFlushQueue()
    DisplayRadar(not state)
    PlaySoundFrontend(-1, state and 'Short_Transition_In' or
                          'Short_Transition_Out',
                      'PLAYER_SWITCH_CUSTOM_SOUNDSET', 1)
    TriggerEvent('nui:stateChanged', state)
end
RegisterCommand('nui', function() NUI.SetVisible(not NUI.IsVisible()) end)
RegisterKeyMapping('nui', 'Toggle editor NUI', 'keyboard', 'F2')

function NUI.IsVisible() return NUI.visible end

function NUI.Call(functionName, args)
    local post = {
        action = 'callFunction',
        functionName = tostring(functionName)
    }
    if type(args) == 'table' then
        for key, value in pairs(args) do post[key] = value end
    end
    SendNUIMessage(post)
end

function NUI.CallEvent(eventName, args)
    local post = {
        action = 'triggerEvent',
        eventName = tostring(eventName),
        args = args
    }
    SendNUIMessage(post)
end

function ShouldDXRender()
    return Editor.CurrentMode() == 'edit' and not IsPauseMenuActive() and
               not NUI.IsVisible() and not Editor.captureModeEnabled
end

RegisterNetEvent('editor:addNotification')
AddEventHandler('editor:addNotification', function(content)
    if type(content) ~= 'table' then return end
    SendNUIMessage({
        action = 'notification',
        title = content.title,
        message = content.message,
        icon = content.icon or 'bell'
    })
end)

RegisterNUICallback('editor:addNotification', function(post)
    TriggerEvent('editor:addNotification', post)
end)
