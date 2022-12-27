local MAXIMUM_POINTS_TO_DRAW = 100
local RECORD_FREQUENCY = 250
local ToolMovementRecorder = {recording = false, points = {}}
local LastCoords

function ToolMovementRecorder.DoRecord(state)
    if state and not ToolMovementRecorder.recording and
        #ToolMovementRecorder.points > 0 then
        AddChatMessage('[Replay] Clearing lines...', 'information')
        return ToolMovementRecorder.Clear()
    end

    if ToolMovementRecorder.recording == state then return end

    printlog('ToolMovementRecorder.DoRecord', state)
    if state then
        AddChatMessage('[Replay] Started recording...', 'success')
        ToolMovementRecorder.Clear()
        CreateThread(function()
            while ToolMovementRecorder.recording do
                ToolMovementRecorder.Tick()
                Wait(RECORD_FREQUENCY)
            end
        end)
    else
        AddChatMessage('[Replay] Stopped recording...', 'error')
    end
    ToolMovementRecorder.recording = state
end

function ToolMovementRecorder.DoDraw(state)
    if ToolMovementRecorder.drawing == state then return end

    printlog('ToolMovementRecorder.DoDraw', state)
    if state then
        CreateThread(function()
            while ToolMovementRecorder.drawing do
                local total = #ToolMovementRecorder.points
                local startIndex = math.max(total - MAXIMUM_POINTS_TO_DRAW, 1)
                for k = startIndex + 1, total, 1 do
                    local current = ToolMovementRecorder.points[k]
                    local previous = ToolMovementRecorder.points[k - 1]
                    DrawLine(previous.coords, current.coords, 255, 255, 255, 255)
                    DrawMarker(2, current.coords.x, current.coords.y,
                               current.coords.z + 0.125, 0.0, 0.0, 0.0, 180.0,
                               0.0, 0.0, 0.25, 0.25, 0.25, 255, 0, 64, 255,
                               false, true, 2, nil, nil, false)
                end
                Wait(0)
            end
        end)
    end
    ToolMovementRecorder.drawing = state
end

local function ToggleRecordingShortcut()
    if Editor.CurrentMode() == 'test' then
        ToolMovementRecorder.DoRecord(not ToolMovementRecorder.recording)
        if ToolMovementRecorder.recording then
            ToolMovementRecorder.DoDraw(true)
        end
    end
end
RegisterCommand('rec', ToggleRecordingShortcut)
RegisterKeyMapping('rec', 'Toggle movement recorder', 'keyboard', 'k')

function ToolMovementRecorder.Tick()
    local ped = PlayerPedId()
    local player = PlayerId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local coords = GetEntityCoords(vehicle > 0 and vehicle or ped)
    if not LastCoords or GetDistanceBetweenCoords(LastCoords, coords) > 1.0 then
        table.insert(ToolMovementRecorder.points,
                     {coords = coords, tick = GetGameTimer()})
        LastCoords = coords
    end
end

function ToolMovementRecorder.Clear()
    ToolMovementRecorder.DoDraw(false)
    ToolMovementRecorder.points = {}
    LastCoords = nil
    NearestCoordsId = nil
end

AddEventHandler('editor:modeChanged', function(modeOld, modeNew)
    if modeOld == 'test' then
        ToolMovementRecorder.DoRecord(false)
    end

    DisplayInstructionalButton(311, modeNew == 'test', 'Toggle movement recorder', 1)
end)
