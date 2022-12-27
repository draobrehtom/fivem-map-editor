function DrawCrosshair(r, g, b, a)
    local resX, resY = GetActiveScreenResolution()
    local lineW, lineH = 2, 8

    local scaleXW = lineW / resX
    local scaleYW = lineH / resY
    local scaleXH = lineH / resX
    local scaleYH = lineW / resY

    DrawRect(0.5, 0.5 - scaleYW, scaleXW, scaleYW, r, g, b, a)
    DrawRect(0.5, 0.5 + scaleYW, scaleXW, scaleYW, r, g, b, a)

    DrawRect(0.5 - scaleXH, 0.5, scaleXH, scaleYH, r, g, b, a)
    DrawRect(0.5 + scaleXH, 0.5, scaleXH, scaleYH, r, g, b, a)

    DrawRect(0.5, 0.5, scaleXW, scaleYH, r, g, b, a)
end

function DrawEntityAxis(entity, length)
    local vecX, vecY, vecZ, center = GetEntityMatrix(entity)
    local posX = center + (vecX * length)
    local posY = center + (vecY * length)
    local posZ = center + (vecZ * length)
    DrawLine(center, posX, 255, 0, 0, 255)
    DrawLine(center, posY, 0, 255, 0, 255)
    DrawLine(center, posZ, 0, 0, 255, 255)
end

function DrawEdgeMatrix(lines, r, g, b, a)
    for line in values(lines) do
        local x1, y1, z1 = table.unpack(line[1])
        local x2, y2, z2 = table.unpack(line[2])
        DrawLine(x1, y1, z1, x2, y2, z2, r, g, b, a)
    end
end

function DrawPolyMatrix(polies, r, g, b, a)
    for poly in values(polies) do
        local x1, y1, z1 = table.unpack(poly[1])
        local x2, y2, z2 = table.unpack(poly[2])
        local x3, y3, z3 = table.unpack(poly[3])
        DrawPoly(x1, y1, z1, x2, y2, z2, x3, y3, z3, r, g, b, a)
    end
end

function DrawBoundingBox(box, r, g, b, a)
    local polyMatrix = GetBoundingBoxPolyMatrix(box)
    local edgeMatrix = GetBoundingBoxEdgeMatrix(box)
    DrawPolyMatrix(polyMatrix, r, g, b, a)
    DrawEdgeMatrix(edgeMatrix, r, g, b, 255)
end

function DrawVirtualBoundingBox(pos, size, r, g, b, a)
    local p1 = pos - size / 2
    local p2 = pos + size / 2
    local box = GetBoundingBox(p1, p2)
    return DrawBoundingBox(box, r, g, b, a)
end

function DrawEntityBoundingBox(entity, r, g, b, a)
    local box = GetEntityBoundingBox(entity)
    return DrawBoundingBox(box, r, g, b, a)
end

function DrawDebugText(x, y, text)
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(0.3, 0.3)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 105)
    -- SetTextEdge(1, 0, 0, 0, 55)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

function Draw3DText(x, y, z, scaleFactor, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov * scaleFactor
    if onScreen then
        SetTextScale(0.0, scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 0)
        SetTextEdge(0, 0, 0, 0, 0)
        SetTextDropShadow(0, 0, 0, 0)
        SetTextOutline(0, 0, 0, 0)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- 'Entity marker'
function DrawEntityMarker(entity, marker, r, g, b, a, size, offset)
    if not IsAnEntity(entity) then return end
    local size = tonumber(size or 3.0)
    local offset = tonumber(offset or size)

    local top = 0
    for k, v in pairs(GetEntityBoundingBox(entity)) do
        top = math.max(v.z, top)
    end

    local forwardVector, rightVector, upVector, position = GetEntityMatrix(
                                                               entity)
    position = vector3(position.x, position.y, top) + vector3(0, 0, offset)

    DrawMarker(marker or 2, position.x, position.y, position.z, 0.0, 0.0, 0.0,
               0.0, 0.0, 0.0, size, size, size, r or 255, g or 255, b or 255,
               a or 255, false, true, 2, nil, nil, false)
end

-- 'Pointer'
function DrawPointer(coords)
    if type(coords) ~= 'vector3' then return end
    -- Marker
    local size = 1.0
    local r, g, b, a = 255, 255, 255, 255
    DrawMarker(2, coords.x, coords.y, coords.z + size * 0.5, 0.0, 0.0, 0.0, 0.0,
               180.0, 0.0, size, size, size, r, g, b, a, false, true, 2, nil,
               nil, false)

    -- Distance text
    if DebugEnabled then
        local distance
        -- Calculate the real distance if camera coords exist
        local cameraCoords = GetFreecamCamCoord()
        if cameraCoords then
            distance = round(GetDistanceBetweenCoords(cameraCoords, coords), 3)
        end
        if distance then
            Draw3DText(coords.x, coords.y, coords.z, 1.0, distance .. ' meters')
        end
    end
end

function DrawPointerOnEntity(entity)
    if not IsAnEntity(entity) then return end

    local top = 0
    for k, v in pairs(GetEntityBoundingBox(entity)) do
        top = math.max(v.z, top)
    end

    local forwardVector, rightVector, upVector, position = GetEntityMatrix(
                                                               entity)
    position = vector3(position.x, position.y, top) + vector3(0, 0, 0.5)

    -- Marker
    local size = 1.0
    local r, g, b, a = 255, 255, 255, 255
    DrawMarker(2, position.x, position.y, position.z + size * 0.5, 0.0, 0.0,
               0.0, 0.0, 180.0, 0.0, size, size, size, r, g, b, a, false, true,
               2, nil, nil, false)
end
