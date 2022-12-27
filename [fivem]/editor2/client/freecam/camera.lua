-- Optimization
local floor = math.floor
local vector3 = vector3
local SetCamRot = SetCamRot
local IsCamActive = IsCamActive
local SetCamCoord = SetCamCoord
local LoadInterior = LoadInterior
local SetFocusArea = SetFocusArea
local LockMinimapAngle = LockMinimapAngle
local GetInteriorAtCoords = GetInteriorAtCoords
local LockMinimapPosition = LockMinimapPosition

-- Locals
local _internal_camera = nil
local _internal_isFrozen = false
local _internal_pos = nil
local _internal_rot = nil
local _internal_fov = nil
local _internal_vecX = nil
local _internal_vecY = nil
local _internal_vecZ = nil
local freecamVehicle

function GetInitialCameraPosition()
    if _G.CAMERA_SETTINGS.KEEP_POSITION and _internal_pos then
        return _internal_pos
    end
    return GetGameplayCamCoord()
end

function GetInitialCameraRotation()
    if _G.CAMERA_SETTINGS.KEEP_ROTATION and _internal_rot then
        return _internal_rot
    end
    local rot = GetGameplayCamRot()
    return vector3(rot.x, 0.0, rot.z)
end

function IsFreecamFrozen() return _internal_isFrozen end

function SetFreecamFrozen(frozen)
    local frozen = frozen == true
    _internal_isFrozen = frozen
end

function GetFreecamPosition() return _internal_pos end

function SetFreecamPosition(x, y, z)
    local pos = vector3(x, y, z)
    local int = GetInteriorAtCoords(pos)
    LoadInterior(int)
    SetFocusArea(pos)
    LockMinimapPosition(x, y)
    SetCamCoord(_internal_camera, pos)
    _internal_pos = pos
end

function GetFreecamCamCoord() return GetCamCoord(_internal_camera) end

function GetFreecamRotation() return _internal_rot end

function SetFreecamRotation(x, y, z)
    local rotX, rotY, rotZ = ClampCameraRotation(x, y, z)
    local vecX, vecY, vecZ = EulerToMatrix(rotX, rotY, rotZ)
    local rot = vector3(rotX, rotY, rotZ)
    LockMinimapAngle(floor(rotZ))
    SetCamRot(_internal_camera, rot)
    _internal_rot = rot
    _internal_vecX = vecX
    _internal_vecY = vecY
    _internal_vecZ = vecZ
end

function GetFreecamFov() return _internal_fov end

function SetFreecamFov(fov)
    local fov = Clamp(fov, 0.0, 90.0)
    SetCamFov(_internal_camera, fov)
    _internal_fov = fov
end

function GetFreecamMatrix()
    return _internal_vecX, _internal_vecY, _internal_vecZ, _internal_pos
end

function GetFreecamTarget(distance)
    return _internal_pos + (_internal_vecY * distance)
end

function IsFreecamActive() return IsCamActive(_internal_camera) == 1 end

function SetFreecamActive(active)
    if active == IsFreecamActive() then return end

    local enableEasing = _G.CAMERA_SETTINGS.ENABLE_EASING
    local easingDuration = _G.CAMERA_SETTINGS.EASING_DURATION
    if active then
        local pos = GetInitialCameraPosition()
        local rot = GetInitialCameraRotation()
        _internal_camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetFreecamFov(_G.CAMERA_SETTINGS.FOV)
        SetFreecamPosition(pos.x, pos.y, pos.z)
        SetFreecamRotation(rot.x, rot.y, rot.z)
        TriggerEvent('freecam:activated')
    else
        DestroyCam(_internal_camera)
        ClearFocus()
        UnlockMinimapPosition()
        UnlockMinimapAngle()
        TriggerEvent('freecam:deactivated')
    end
    RenderScriptCams(active, enableEasing, easingDuration, true, true)
end

local function EnableNoClip()
    local ped = PlayerPedId()
    local player = PlayerId()

    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    SetFreecamActive(true)
    StartFreecamThread()

    CreateThread(function()
        while IsFreecamActive() do
            FreezeEntityPosition(ped, true)
            SetEntityLocallyInvisible(ped)

            if freecamVehicle > 0 then
                if DoesEntityExist(freecamVehicle) then
                    SetEntityLocallyInvisible(freecamVehicle)
                else
                    freecamVehicle = 0
                end
            end

            DisablePlayerFiring(player, true)
            HudWeaponWheelIgnoreSelection()
            Wait(0)
        end
    end)
end

local function DisableNoClip(spawnOverGround)
    local ped = PlayerPedId()
    local player = PlayerId()

    SetFreecamActive(false)
    SetGameplayCamRelativeHeading(0)
    Wait(0)

    if spawnOverGround then
        local pos = GetFreecamPosition()
        local over, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)
        if not over then
            over, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, 1000.0, false)
        end
        pos = vector3(pos.x, pos.y, groundZ)
        SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z)
        SetEntityInvincible(ped, false)
        FreezeEntityPosition(ped, false)
        DisablePlayerFiring(player, false)
        if freecamVehicle > 0 and DoesEntityExist(freecamVehicle) then
            local coords = GetEntityCoords(ped)
            local rot = GetFreecamRotation().z
            NetworkSetEntityInvisibleToNetwork(freecamVehicle, false)
            SetEntityCollision(freecamVehicle, true, true)
            SetEntityCoords(freecamVehicle, coords[1], coords[2], coords[3])
            SetEntityRotation(freecamVehicle, 0.0, 0.0, rot)
            SetVehicleFixed(freecamVehicle)
            SetPedIntoVehicle(ped, freecamVehicle, -1)
        end
        freecamVehicle = 0
    end
end

function SetFreecamEnabled(enabled, spawnOverGround)
    local ped = PlayerPedId()
    local player = PlayerId()

    if enabled then
        freecamVehicle = GetVehiclePedIsIn(ped, false)
        if freecamVehicle > 0 then
            SetVehicleFixed(freecamVehicle)
            NetworkSetEntityInvisibleToNetwork(freecamVehicle, true)
            SetEntityCollision(freecamVehicle, false, false)
        end
    end

    if not IsFreecamActive() and enabled then EnableNoClip() end
    if IsFreecamActive() and enabled == false then
        DisableNoClip(spawnOverGround)
    end
    TriggerEvent('freecam:stateChanged', enabled and true or false)

    DisplayInstructionalButton(32, enabled, 'Move forward', 1)
    DisplayInstructionalButton(34, enabled, 'Move left', 1)
    DisplayInstructionalButton(33, enabled, 'Move backward', 1)
    DisplayInstructionalButton(35, enabled, 'Move right', 1)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then SetFreecamEnabled(false) end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then SetFreecamEnabled(false) end
end)
