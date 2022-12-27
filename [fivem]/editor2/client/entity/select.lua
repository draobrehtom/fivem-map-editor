local ENTITY_BOUND_COLOR = {
    ['hit'] = {255, 255, 255},
    ['selected'] = {0, 255, 0},
    ['rotate'] = {255, 255, 0}
}
local CHECK_BOUNDING_BOX, CHECK_WATER = true, false

-- Locals
local DraggingDistance, DraggingDistanceMinimum, DraggingDistanceMaximum =
    100.0, 20.0, 300.0
local SelectedEntityClass, SelectedEntityLocked, SelectedEntityFrozen,
      SelectedEntityRotationType
local RotX, RotY, RotZ
local RotFlipped = false
local LockToAxes
local OriginEntity, OriginEntityEId

function Editor.GetSelectedEntity() return Editor.selectedEntity end

function Editor.IsEntitySelected(entityId)
    return IsAnEntity(entityId) == 1 and Editor.selectedEntity == entityId
end

local function SelectEntity(entityId, initial)
    if type(entityId) ~= 'number' or entityId == 0 then return end

    if initial then Editor.ToggleCursor(false) end

    Editor.selectedEntity = entityId
    Editor.dragSelectedEntity = initial == true

    local entityInstance = GetEntityInstance(entityId)
    SelectedEntityClass = entityInstance and entityInstance.class or nil
    SelectedEntityLocked = entityInstance and entityInstance.locked == 1
    SelectedEntityFrozen = IsEntityPositionFrozen(entityId)
    SelectedEntityRotationType =
        entityInstance and entityInstance.rotationType or nil

    local rotation = GetEntityRotation(entityId)
    RotX, RotY, RotZ = rotation.x, rotation.y, rotation.z

    FreezeEntityPosition(entityId, true)
    TriggerEvent('editor:entitySelected', entityId)

    -- World entity warning
    if not IsEditorEntity(entityId) then
        HelpNotification(
            'This is a ~b~world entity, ~s~any change you will make on this entity will ~r~not be saved.')
    end

    DisplayInstructionalButton(68, true, 'Drag', 1)
    DisplayInstructionalButton(224, true, 'Rotate', 1)
    DisplayInstructionalButton(26, true, 'Clone', 1)
    DisplayInstructionalButton(73, true, 'Axes lock', 1)

    if IsEditorEntity(entityId) then
        DisplayInstructionalButton(178, true, 'Delete', 1)
        DisplayInstructionalButton(80, true, 'Rotation', 1)
        DisplayInstructionalButton(170, true, 'Properties', 1)
    end
end

local function ShouldDragEntity()
    return Editor.dragSelectedEntity or IsDisabledControlPressed(0, INPUT_AIM)
end

AddEventHandler('editor:entityHandlerUpdated', function(instance)
    if Editor.selectedEntity and instance.objectHandler == Editor.selectedEntity then
        -- is locked
        SelectedEntityLocked = instance.locked == 1

        -- is frozen
        SelectedEntityFrozen = instance.frozen

        -- rotation type
        SelectedEntityRotationType = instance.rotationType
    end
end)

function Editor.SelectEntity(entityId, initial)
    if Editor.selectedEntity then
        if IsAnEntity(Editor.selectedEntity) then
            Editor.SyncEntityToServer(Editor.selectedEntity)
            FreezeEntityPosition(Editor.selectedEntity, SelectedEntityFrozen)
        end
        Editor.selectedEntity = nil
        Editor.dragSelectedEntity = nil
        TriggerServerEvent('editor:requestSelectEntity', 0)

        DisplayInstructionalButton(68, false)
        DisplayInstructionalButton(224, false)
        DisplayInstructionalButton(26, false)
        DisplayInstructionalButton(73, false)
        DisplayInstructionalButton(178, false)
        DisplayInstructionalButton(80, false)
        DisplayInstructionalButton(170, false)
    end

    if Editor.CurrentMode() ~= 'edit' then return end

    if IsAnEntity(entityId) then
        if not IsEditorEntity(entityId) then
            SelectEntity(entityId)
        else
            TriggerServerEvent('editor:requestSelectEntity',
                               GetEntityEditorId(entityId), initial)
        end
    end
end
AddEventHandler('editor:stateChanged', function() Editor.SelectEntity(-1) end)
AddEventHandler('editor:modeChanged', function() Editor.SelectEntity(-1) end)
AddEventHandler('editor:captureModeStateChanged',
                function() Editor.SelectEntity(-1) end)

RegisterNetEvent('editor:entitySelectFailCallback')
AddEventHandler('editor:entitySelectFailCallback',
                function(entityEId, controllerName)
    local entityInstance = GetEntityInstanceFromId(entityEId)
    if not entityInstance then return end

    ShowNotification('~r~Cannot select entity ~s~' ..
                         entityInstance.objectHandler ..
                         ', because it is ~y~already selected ~s~by ' ..
                         controllerName)
end)

RegisterNetEvent('editor:entitySelectCallback')
AddEventHandler('editor:entitySelectCallback', function(entityEId, initial)
    local entityInstance = GetEntityInstanceFromId(entityEId)
    if not entityInstance then return end

    printlog('editor:entitySelectCallback',
             'Now controlling entity ' .. entityEId)
    SelectEntity(entityInstance.objectHandler, initial)
end)

local function StateAllowsSelection()
    return Editor.IsEnabled() and IsFreecamActive() and
               not Editor.IsEntityPreviewActive()
end

function SetDraggingDistance(value)
    if type(value) == 'number' then
        if value < DraggingDistanceMinimum then
            value = DraggingDistanceMinimum
        elseif value > DraggingDistanceMaximum then
            value = DraggingDistanceMaximum
        end
        DraggingDistance = round(value, 3)
    end
end

function GetWorldDraggingPosition() return GetFreecamTarget(DraggingDistance) end

function Editor.SetOriginEntity(entityId)
    if entityId == -1 and (OriginEntity or OriginEntityEId) then
        OriginEntity = nil
        OriginEntityEId = nil
        return
    end

    if not IsAnEntity(entityId) then return end

    OriginEntity = entityId
    local eId = GetEntityEditorId(entityId)
    OriginEntityEId = eId and eId or nil
end

function Editor.GetOriginEntity()
    return OriginEntity, OriginEntityEId
end

AddEventHandler('editor:entityHandlerCreated', function(entityInstance)
    if not OriginEntityEId or not entityInstance then return end

    if entityInstance.id == OriginEntityEId then
        OriginEntity = entityInstance.objectHandler
    end
end)

AddEventHandler('editor:entityDeleted', function(entityInstance)
    if not OriginEntityEId or not entityInstance then return end

    if entityInstance.id == OriginEntityEId then
        OriginEntity = nil
        OriginEntityEId = nil
    end
end)

-- Optimization
local IsPauseMenuActive = IsPauseMenuActive
local IsControlPressed = IsControlPressed
local IsControlJustReleased = IsControlJustReleased
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local Draw3DText = Draw3DText
local GetSmartControlNormal = GetSmartControlNormal
local GetFrameTime = GetFrameTime
local GetEntityArchetypeName = GetEntityArchetypeName
local GetEntityCoords = GetEntityCoords
local Wait = Citizen.Wait

AddEventHandler('editor:modeChanged', function(modeOld, modeNew)
    if modeNew == 'edit' then
        CreateThread(function()
            while Editor.CurrentMode() == 'edit' do
                if not IsPauseMenuActive() then
                    local selectedEntity = Editor.GetSelectedEntity()
                    local selectedEntityInstance = GetEntityInstance(
                                                       selectedEntity)

                    if selectedEntity then
                        if IsControlPressed(0, INPUT_RELOAD) then
                            if SelectedEntityRotationType == 'heading' and
                                ShouldDragEntity() then
                                local heading = GetFreecamRotation().z
                                SetEntityHeading(selectedEntity, heading)
                            end

                            -- 'R' to switch rotation mode
                        elseif IsControlJustReleased(0, INPUT_RELOAD) and
                            not ShouldDragEntity() then
                            if SelectedEntityRotationType == 'heading' then
                                SelectedEntityRotationType = 'world'
                            else
                                SelectedEntityRotationType = 'heading'
                            end

                            if selectedEntityInstance then
                                selectedEntityInstance.rotationType =
                                    SelectedEntityRotationType
                            end

                            ShowNotification(
                                'Switched to: ~b~' .. SelectedEntityRotationType)
                        end
                    end
                end
                Wait(1)
            end
        end)
    end

    DisplayInstructionalButton(24, modeNew == 'edit', 'Select', 1)
end)

-- Wrap function, SetEntityCoords caused some how rotation to change
local _SetEntityCoords = SetEntityCoords
local function SetEntityCoords(entity, coords)
    if IsAnEntity(entity) then
        -- Pre store rotation
        local rotation = GetEntityRotation(entity)

        local x, y, z = round(coords.x, 3), round(coords.y, 3),
                        round(coords.z, 3)
        _SetEntityCoords(entity, x, y, z)

        -- Rotation fix
        SetEntityRotation(entity, rotation)
    end
end

local _SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local function SetEntityCoordsNoOffset(entity, coords)
    if IsAnEntity(entity) then
        -- Pre store rotation
        local rotation = GetEntityRotation(entity)

        local x, y, z = round(coords.x, 3), round(coords.y, 3),
                        round(coords.z, 3)
        _SetEntityCoordsNoOffset(entity, x, y, z)

        -- Rotation fix
        SetEntityRotation(entity, rotation)
    end
end

local function ToggleAxesLock()
    LockToAxes = not LockToAxes
    ShowNotification('Entity axes lock is now ' .. (LockToAxes and '~g~enabled' or '~r~disabled'))
end
RegisterCommand('axeslock', ToggleAxesLock)
RegisterKeyMapping('axeslock', 'Toggle entity axes lock', 'keyboard', 'x')

CreateThread(function()
    while true do
        if Editor.CurrentMode() == 'edit' and not IsPauseMenuActive() and
            IsFreecamActive() and not NUI.IsVisible() and
            not Editor.captureModeEnabled then
            local selectedEntity, allowSelection = Editor.selectedEntity,
                                                   StateAllowsSelection()

            -- check selected entity exists
            if selectedEntity and
                (not IsAnEntity(selectedEntity) or not allowSelection) then
                Editor.SelectEntity(-1)
            end

            if OriginEntity and not GetEntityInstanceFromId(OriginEntityEId) then
                OriginEntity = nil
                OriginEntityEId = nil
            end

            -- raytrace
            local ignoredEntity = selectedEntity
            local checkBoundingBox, checkWater = CHECK_BOUNDING_BOX, CHECK_WATER
            local point1 = GetFreecamPosition()
            local point2 = GetFreecamTarget(
                               selectedEntity and DraggingDistance or
                                   DraggingDistanceMaximum)
            local hitPos, hitEntity = Raytrace(point1, point2, ignoredEntity,
                                               checkBoundingBox, checkWater)

            local canSelect = allowSelection and CanSelectEntity(hitEntity)
            if hitEntity and canSelect then
                local color = ENTITY_BOUND_COLOR['hit']
                DrawEntityBoundingBox(hitEntity, color[1], color[2], color[3], 0)
            end

            -- check blank click
            if IsDisabledControlJustPressed(0, INPUT_ATTACK) then
                if selectedEntity then
                    Editor.SelectEntity(-1)
                    selectedEntity = Editor.selectedEntity
                end

                if canSelect then Editor.SelectEntity(hitEntity) end
            end

            -- drag distance
            if not IsControlPressed(0, INPUT_DUCK) then
                local slowNormal = GetSmartControlNormal(INPUT_CHARACTER_WHEEL)
                local fastNormal = GetSmartControlNormal(INPUT_VEH_MOVE_UP_ONLY)

                local additionSlow = 1.0 - (0.9 * slowNormal)
                local additionFast = 1.0 + (4.0 * fastNormal)
                local addition = GetFrameTime() * 90 *
                                     GetDisabledControlNormalBetween(0,
                                                                     INPUT_WEAPON_WHEEL_PREV,
                                                                     INPUT_WEAPON_WHEEL_NEXT) *
                                     additionSlow * additionFast

                if addition ~= 0 then
                    SetDraggingDistance(DraggingDistance + addition)
                end
            end

            local crosshairR, crosshairG, crosshairB = 255, 255, 255

            if selectedEntity then
                local slowNormal = GetSmartControlNormal(INPUT_CHARACTER_WHEEL)
                local fastNormal = GetSmartControlNormal(INPUT_VEH_MOVE_UP_ONLY)

                -- set rotation
                if IsControlPressed(0, INPUT_DUCK) then
                    if not SelectedEntityLocked then
                        local multiplierSlow = 1.0 - (0.9 * slowNormal)
                        local multiplierFast = 1.0 + (4.0 * fastNormal)
                        local multiplier =
                            GetFrameTime() * 90 * multiplierSlow *
                                multiplierFast

                        -- heading
                        if SelectedEntityRotationType == 'heading' then
                            local moveLeftOrRight, moveUpOrDown, moveWheel,
                                  heading

                            -- arrow left - arrow right
                            if IsControlPressed(0, INPUT_CELLPHONE_LEFT) or
                                IsControlPressed(0, INPUT_CELLPHONE_RIGHT) then
                                moveLeftOrRight =
                                    GetDisabledControlNormalBetween(0,
                                                                    INPUT_CELLPHONE_LEFT,
                                                                    INPUT_CELLPHONE_RIGHT)

                                -- arrow up - arrow down
                            elseif IsControlPressed(0, INPUT_CELLPHONE_UP) or
                                IsControlPressed(0, INPUT_CELLPHONE_DOWN) then
                                moveUpOrDown =
                                    GetDisabledControlNormalBetween(0,
                                                                    INPUT_CELLPHONE_UP,
                                                                    INPUT_CELLPHONE_DOWN)

                                -- mouse wheel
                            elseif IsControlPressed(0, INPUT_WEAPON_WHEEL_PREV) or
                                IsControlPressed(0, INPUT_WEAPON_WHEEL_NEXT) then
                                moveWheel =
                                    GetDisabledControlNormalBetween(0,
                                                                    INPUT_WEAPON_WHEEL_PREV,
                                                                    INPUT_WEAPON_WHEEL_NEXT)
                            end

                            if moveLeftOrRight then
                                heading =
                                    GetEntityHeading(selectedEntity) +
                                        multiplier * moveLeftOrRight
                            elseif moveUpOrDown then
                                heading =
                                    GetEntityHeading(selectedEntity) +
                                        multiplier * moveUpOrDown
                            elseif moveWheel then
                                heading =
                                    GetEntityHeading(selectedEntity) +
                                        multiplier * moveWheel
                            end

                            if heading then
                                SetEntityHeading(selectedEntity, heading)
                            end

                            -- world
                        elseif SelectedEntityRotationType == 'world' then
                            local moveX, moveY, moveZ

                            -- arrow up - arrow down
                            if IsControlPressed(0, INPUT_CELLPHONE_DOWN) or
                                IsControlPressed(0, INPUT_CELLPHONE_UP) then
                                moveX = GetDisabledControlNormalBetween(0,
                                                                        INPUT_CELLPHONE_DOWN,
                                                                        INPUT_CELLPHONE_UP)
                            end

                            -- page up - page down
                            if IsControlPressed(0, INPUT_SCRIPTED_FLY_ZDOWN) or
                                IsControlPressed(0, INPUT_SCRIPTED_FLY_ZUP) then
                                moveY = GetDisabledControlNormalBetween(0,
                                                                        INPUT_SCRIPTED_FLY_ZDOWN,
                                                                        INPUT_SCRIPTED_FLY_ZUP)
                            end

                            -- arrow left - arrow right
                            if IsControlPressed(0, INPUT_CELLPHONE_LEFT) or
                                IsControlPressed(0, INPUT_CELLPHONE_RIGHT) then
                                moveZ = GetDisabledControlNormalBetween(0,
                                                                        INPUT_CELLPHONE_LEFT,
                                                                        INPUT_CELLPHONE_RIGHT)
                            end

                            local tempRotX, tempRotY, tempRotZ = RotX, RotY,
                                                                 RotZ

                            -- roll
                            if moveY then
                                if RotFlipped then
                                    tempRotY =
                                        tempRotY + multiplier * moveY * -1
                                else
                                    tempRotY = tempRotY + multiplier * moveY
                                end
                            end

                            -- not sure why, maybe rotation conversion has singularity
                            if tempRotY > 90.0 or tempRotY < -90.0 then
                                RotFlipped = not RotFlipped

                                local dirX = math.rad(tempRotX) > 0 and 1 or -1
                                tempRotX = tempRotX + 180 * dirX

                                local dirZ = math.rad(tempRotZ) > 0 and 1 or -1
                                tempRotZ = tempRotZ + 180 * dirZ
                            end

                            -- pitch
                            if moveX then
                                tempRotX = tempRotX + multiplier * moveX
                            end

                            -- yaw
                            if moveZ then
                                tempRotZ = tempRotZ + multiplier * moveZ
                            end

                            if SelectedEntityClass == 1 then
                                SetEntityRotation(selectedEntity, 0.0, 0.0,
                                                  tempRotZ)
                            else
                                SetEntityRotation(selectedEntity, tempRotX,
                                                  tempRotY, tempRotZ)
                            end

                            RotX, RotY, RotZ = tempRotX, tempRotY, tempRotZ
                        end
                    end
                    local color = SelectedEntityLocked and {255, 0, 0} or
                                      ENTITY_BOUND_COLOR['rotate']
                    DrawEntityAxis(selectedEntity, 5)
                    DrawEntityBoundingBox(selectedEntity, color[1], color[2],
                                          color[3], 0)
                    DrawEntityMarker(selectedEntity, 24, color[1], color[2],
                                     color[3], 155)

                    crosshairR, crosshairG, crosshairB = color[1], color[2],
                                                         color[3]

                    -- set position
                else
                    if not SelectedEntityLocked then
                        -- drag
                        if (Editor.dragSelectedEntity or
                            IsDisabledControlPressed(0, INPUT_AIM)) and hitPos then
                            if IsEntityAVehicle(selectedEntity) then
                                SetEntityCoords(selectedEntity, hitPos)
                            else
                                SetEntityCoordsNoOffset(selectedEntity, hitPos)
                            end
                        else -- set position
                            local multiplierSlow = 1.0 - (0.9 * slowNormal)
                            local multiplierFast = 1.0 + (4.0 * fastNormal)
                            local multiplier =
                                GetFrameTime() * 10 * multiplierSlow *
                                    multiplierFast
                            local moveRotation = LockToAxes and
                                                     GetEntityRotation(
                                                         selectedEntity).z or
                                                     GetFreecamRotation().z
                            moveRotation = moveRotation % 360

                            local rad = math.rad(moveRotation)
                            local cos = math.cos(rad)
                            local sin = math.sin(rad)

                            local movePosX =
                                GetDisabledControlNormalBetween(0,
                                                                INPUT_CELLPHONE_RIGHT,
                                                                INPUT_CELLPHONE_LEFT)
                            local movePosY =
                                GetDisabledControlNormalBetween(0,
                                                                INPUT_CELLPHONE_UP,
                                                                INPUT_CELLPHONE_DOWN)
                            local movePosZ =
                                GetDisabledControlNormalBetween(0,
                                                                INPUT_SCRIPTED_FLY_ZUP,
                                                                INPUT_SCRIPTED_FLY_ZDOWN)

                            local distanceX = (movePosX * cos) -
                                                  (movePosY * sin)
                            local distanceY = (movePosX * sin) +
                                                  (movePosY * cos)
                            local distanceZ = multiplier * movePosZ

                            distanceX = distanceX * multiplier
                            distanceY = distanceY * multiplier

                            ApplyEntityPosition(selectedEntity, distanceX,
                                                distanceY, distanceZ, true)
                        end
                    end
                    local color = SelectedEntityLocked and {255, 0, 0} or
                                      ENTITY_BOUND_COLOR['selected']
                    DrawEntityAxis(selectedEntity, 5)
                    DrawEntityBoundingBox(selectedEntity, color[1], color[2],
                                          color[3], 0)
                    DrawEntityMarker(selectedEntity, 0, color[1], color[2],
                                     color[3], 155)

                    crosshairR, crosshairG, crosshairB = color[1], color[2],
                                                         color[3]
                end
            end

            if OriginEntity then
                DrawEntityBoundingBox(OriginEntity, 255, 0, 255, 55)
            end

            DrawCrosshair(crosshairR, crosshairG, crosshairB, 255)
        end
        Wait(0)
    end
end)
