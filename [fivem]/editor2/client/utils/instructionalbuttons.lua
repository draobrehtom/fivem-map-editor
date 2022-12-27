local Entries = {}

function ButtonMessage(text)
    BeginTextCommandScaleformString('STRING')
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function Button(ControlButton) N_0xe83a3e3557a56640(ControlButton) end

function SetupScaleform(scaleform)
    local scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do Wait(0) end

    -- draw it once to set up layout
    DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 0, 0)

    PushScaleformMovieFunction(scaleform, 'CLEAR_ALL')
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, 'SET_CLEAR_SPACE')
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    for k, slot in pairs(Entries) do
        PushScaleformMovieFunction(scaleform, 'SET_DATA_SLOT')
        PushScaleformMovieFunctionParameterInt(k - 1)
        Button(GetControlInstructionalButton(2, slot.button, true))
        ButtonMessage(slot.text)
        PopScaleformMovieFunctionVoid()
    end

    PushScaleformMovieFunction(scaleform, 'DRAW_INSTRUCTIONAL_BUTTONS')
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, 'SET_BACKGROUND_COLOUR')
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(85)
    PopScaleformMovieFunctionVoid()
    return scaleform
end

function ShouldDXRenderInstructions()
    return not IsPauseMenuActive() and not NUI.IsVisible() and
               not Editor.captureModeEnabled
end

function DisplayInstructionalButton(button, toggle, text, index)
    if type(button) ~= 'number' then return end

    if toggle then
        local found
        for _, entry in pairs(Entries) do
            if entry.button == button then
                entry.text = tostring(text)
                found = true
            end
        end

        if not found then
            if type(index) == 'number' then
                table.insert(Entries, index,
                             {button = button, text = tostring(text)})
            else
                table.insert(Entries, {button = button, text = tostring(text)})
            end
        end

    else
        for k, entry in pairs(Entries) do
            if entry.button == button then
                table.remove(Entries, k)
                break
            end
        end
    end

    SetupScaleform('instructional_buttons')
end

AddEventHandler('session:clientJoined', function()
    Scaleform = SetupScaleform('instructional_buttons')
    CreateThread(function()
        while CurrentSession.GetId() > 0 do
            if ShouldDXRenderInstructions() then
                DrawScaleformMovieFullscreen(Scaleform, 255, 255, 255, 255, 0)
            end
            Wait(0)
        end
    end)
end)
