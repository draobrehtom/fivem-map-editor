_G.DebugEnabled = false

-- Optimization
local IsPauseMenuActive = IsPauseMenuActive
local IsControlJustReleased = IsControlJustReleased
local GetEntityCoords = GetEntityCoords
local DrawDebugText = DrawDebugText
local Wait = Citizen.Wait

local function ToggleDebugShortcut()
    DebugEnabled = not DebugEnabled

    if DebugEnabled then
        CreateThread(function()
            while true do
                if DebugEnabled then
                    local offsetY = 0.1
                    
                    DrawDebugText(0.01, offsetY, 'Debug Screen ~b~(F9 to toggle)')
                    offsetY = offsetY + 0.03
    
                    local coords = GetEntityCoords(PlayerPedId())
                    if coords then
                        DrawDebugText(0.01, offsetY,
                                    'X: ' .. round(coords.x, 3) .. ' Y: ' ..
                                        round(coords.y, 3) .. ' Z: ' ..
                                        round(coords.z, 3))
                        offsetY = offsetY + 0.02
                    end
    
                    local freecamState = IsFreecamActive() and '~g~activated' or
                                            '~r~deactivated'
                    DrawDebugText(0.01, offsetY, 'Freecam is ' .. freecamState)
                    offsetY = offsetY + 0.02
    
                    local cursorState =
                        Editor.GetCursorVisible() and '~g~visible' or '~r~hidden'
                    DrawDebugText(0.01, offsetY, 'Cursor is ' .. cursorState)
                    offsetY = offsetY + 0.02
    
                    local selectedEntity = Editor.GetSelectedEntity()
                    DrawDebugText(0.01, offsetY, 'Selected entity: ' ..
                                    (selectedEntity and '~b~' .. selectedEntity or
                                        '~y~none'))
                    offsetY = offsetY + 0.02
    
                    if selectedEntity then
                        local coords = GetEntityCoords(selectedEntity)
                        local rotation = GetEntityRotation(selectedEntity)
    
                        DrawDebugText(0.02, offsetY,
                                    '- coords: ' .. tostring(coords))
                        offsetY = offsetY + 0.02
    
                        DrawDebugText(0.02, offsetY,
                                    '- rotation: ' .. tostring(rotation))
                        offsetY = offsetY + 0.02
    
                        --[[local box = GetEntityBoundingBox(selectedEntity)
                        if box then
                            for k, v in pairs(box) do
                                DrawMarker(10 + k, v.x, v.y, v.z, 0.0, 0.0, 0.0,
                                        0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 255, 255,
                                        255, 255, false, true, 2, nil, nil, false)
                            end
                        end]]--
                    end
                end
                Wait(0)
            end
        end)
    end
end
RegisterCommand('debug', ToggleDebugShortcut)
RegisterKeyMapping('debug', 'Toggle editor debug mode', 'keyboard', 'F9')
