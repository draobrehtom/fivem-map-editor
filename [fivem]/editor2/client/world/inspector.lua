_G.WorldInspectorEnabled = false

-- Locals
local Objects = {}
local InspectedObjectModels = {}

-- Optimization
local IsPauseMenuActive = IsPauseMenuActive
local IsControlJustReleased = IsControlJustReleased
local GetEntityCoords = GetEntityCoords
local DrawDebugText = DrawDebugText
local Wait = Citizen.Wait
local GetEntityCoords = GetEntityCoords
local GetEntityArchetypeName = GetEntityArchetypeName

local function GetVisibleObjects()
    Objects = {}
    for object in EnumerateObjects() do
        table.insert(Objects, object)
        local model = GetEntityArchetypeName(object)
        InspectedObjectModels[model] = true
    end
end

function Editor.GetInspectedObjectModels()
    return InspectedObjectModels
end

AddEventHandler('editor:modeChanged', function(modeOld, modeNew)
    if modeNew == 'edit' then
        -- Toggle thread
        CreateThread(function()
            while Editor.CurrentMode() == 'edit' do
                if not IsPauseMenuActive() and
                    IsControlJustReleased(0, INPUT_SELECT_CHARACTER_TREVOR) then
                    WorldInspectorEnabled = not WorldInspectorEnabled
                    ShowNotification('World Inspector is now ' ..
                                         (WorldInspectorEnabled and '~g~enabled' or
                                             '~r~disabled'))

                    if WorldInspectorEnabled then
                        -- Inspect thread
                        CreateThread(function()
                            while WorldInspectorEnabled do
                                GetVisibleObjects()
                                Wait(1000)
                            end
                        end)

                        -- Render thread
                        CreateThread(function()
                            while WorldInspectorEnabled do
                                if ShouldDXRender() then
                                    local debug = DebugEnabled
                                    for _, object in pairs(Objects) do
                                        local coords = GetEntityCoords(object)
                                        local model =
                                            GetEntityArchetypeName(object)
                                        Draw3DText(coords.x, coords.y, coords.z,
                                                   1.0, model)

                                        if debug then
                                            local entityInstance =
                                                GetEntityInstance(object)
                                            if entityInstance then
                                                Draw3DText(coords.x, coords.y,
                                                           coords.z + 1.0, 2.0,
                                                           tostring(
                                                               entityInstance.id))
                                            end
                                        end
                                    end
                                end
                                Wait(0)
                            end
                        end)
                    end
                end
                Wait(1)
            end
        end)
    end
end)
