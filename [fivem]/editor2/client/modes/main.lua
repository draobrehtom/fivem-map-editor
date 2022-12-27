local VALID_MODES = {['none'] = true, ['edit'] = true, ['test'] = true}

function Editor.SwitchMode(mode)
    if type(mode) ~= 'string' or not VALID_MODES[mode] then return end

    if Editor.mode == mode then return end

    local modeOld = Editor.mode or 'none'
    printlog('Editor.SwitchMode', 'Switching from <' .. modeOld .. '> to <' .. mode .. '>')
    Editor.mode = mode
    TriggerEvent('editor:modeChanged', modeOld, mode)
end

function Editor.CurrentMode()
    if not Editor.enabled then return 'none' end
    return Editor.mode or 'none'
end
