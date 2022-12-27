-- Optimization
local Wait = Citizen.Wait
local vector3 = vector3
local IsPauseMenuActive = IsPauseMenuActive
local GetSmartControlNormal = GetSmartControlNormal
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord

-- Locals
local SETTINGS = _G.CONTROL_SETTINGS
local CONTROLS = _G.CONTROL_MAPPING

local function GetSpeedMultiplier()
    local fastNormal = GetSmartControlNormal(CONTROLS.MOVE_FAST)
    local slowNormal = GetSmartControlNormal(CONTROLS.MOVE_SLOW)

    local baseSpeed = SETTINGS.BASE_MOVE_MULTIPLIER
    local fastSpeed = 1 + ((SETTINGS.FAST_MOVE_MULTIPLIER - 1) * fastNormal)
    local slowSpeed = 1 + ((SETTINGS.SLOW_MOVE_MULTIPLIER - 1) * slowNormal)

    local frameMultiplier = GetFrameTime() * 60
    local speedMultiplier = baseSpeed * fastSpeed / slowSpeed

    return speedMultiplier * frameMultiplier
end

local function UpdateCamera()
    if not IsFreecamActive() or IsPauseMenuActive() then return end
    if not IsFreecamFrozen() then
        local vecX, vecY = GetFreecamMatrix()
        local vecZ = vector3(0, 0, 1)
        local pos = GetFreecamPosition()
        local rot = GetFreecamRotation()

        -- Get speed multiplier for movement
        local speedMultiplier = GetSpeedMultiplier()

        -- Get rotation input
        local lookX = GetSmartControlNormal(CONTROLS.LOOK_X)
        local lookY = GetSmartControlNormal(CONTROLS.LOOK_Y)

        -- Get position input
        local moveX = GetSmartControlNormal(CONTROLS.MOVE_X)
        local moveY = GetSmartControlNormal(CONTROLS.MOVE_Y)
        local moveZ = GetSmartControlNormal(CONTROLS.MOVE_Z)

        -- Calculate new rotation.
        local rotX = rot.x + (-lookY * SETTINGS.LOOK_SENSITIVITY_X)
        local rotZ = rot.z + (-lookX * SETTINGS.LOOK_SENSITIVITY_Y)
        local rotY = rot.y

        -- Adjust position relative to camera rotation.
        pos = pos + (vecX * moveX * speedMultiplier)
        pos = pos + (vecY * -moveY * speedMultiplier)
        pos = pos + (vecZ * moveZ * speedMultiplier)

        -- Adjust new rotation
        rot = vector3(rotX, rotY, rotZ)

        -- Update camera
        local over, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)
        if not over then
            pos = vector3(pos.x, pos.y, math.max(pos.z, groundZ))
        end
        SetFreecamPosition(pos.x, pos.y, pos.z)
        SetFreecamRotation(rot.x, rot.y, rot.z)

        return pos, rotZ
    end
    TriggerEvent('freecam:tick')
end

-- Camera/Pos updating thread
function StartFreecamThread()
    CreateThread(function()
        local ped = PlayerPedId()
        local initialPos = GetEntityCoords(ped)
        SetFreecamPosition(initialPos[1], initialPos[2], initialPos[3])
        
        local function UpdatePosition(pos, rotZ)
            if pos ~= nil and rotZ ~= nil then

                -- Update ped
                SetEntityCoords(ped, pos.x, pos.y, pos.z)
                SetEntityHeading(ped, rotZ)

                -- Update vehicle
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle and vehicle > 0 then
                    SetEntityCoords(vehicle, pos.x, pos.y, pos.z)
                end
            end
        end

        local loopPos, loopRotZ
        while IsFreecamActive() do
            loopPos, loopRotZ = UpdateCamera()
            UpdatePosition(loopPos, loopRotZ)
            Wait(0)
        end

        UpdatePosition(loopPos, loopRotZ)
    end)
end
