local CursorVisible

function Editor.ToggleCursor(state)
    state = state and true or false
    if CursorVisible == state then return end
    if Config.CURSOR_RESET then SetCursorLocation(0.5, 0.5) end

    if state then
        SetNuiFocus(true, true)
        Wait(0)
    else
        LeaveCursorMode()
        SetNuiFocus(false, false)
        Wait(0)
    end

    CursorVisible = state
    TriggerEvent('editor:cursorStateChanged', state)
end

function Editor.GetCursorVisible() return CursorVisible end

AddEventHandler('nui:formShown',
                function(formId) Editor.ToggleCursor(true) end)

AddEventHandler('editor:formHid', function(formId)
    if NUI.IsVisible() == false then Editor.ToggleCursor(false) end
end)

AddEventHandler('nui:stateChanged',
                function(state) Editor.ToggleCursor(state) end)
