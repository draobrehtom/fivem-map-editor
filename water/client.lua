-- local currentPedPosition = GetEntityCoords(PlayerPedId())


explosions = {
{1643.379, 26.0746269, 172.2623},
{1646.981, 14.51238, 172.145889},
{1653.06775, 6.83159637, 172.6793},
{1658.44812, 0.6161213, 172.706085},
{1664.57507, -9.88547, 172.37352},
{1664.57507, -9.88547, 172.37352},
{1669.71228, -26.0003757, 172.427383},
{1671.13562, -33.82772, 172.427383},
{1672.04736, -40.98436, 172.514084},
{1671.29968, -50.3017, 172.8118},
{1653.95459, -1.27398729, 165.5556},
{1660.40027, -14.5051908, 160.788361},
{1661.329, -20.6655369, 141.3111},
{1660.47791, -27.2854137, 151.600983},
{1664.58716, -37.99884, 150.718918},
{1666.16748, -41.8842468, 161.118073},
{1677.05444, -50.3017, 166.180222},
{1677.05444, -37.6959076, 166.180222},
{1670.975, -9.222134, 166.180222},
{1660.23657, 8.183165, 166.180222},
{1652.88892, 17.8668213, 169.5238},
{1662.49744, 28.17554, 171.10733},
{1662.49744, 34.03029, 171.10733},
}
RemoveIpl('map1')
ResetWater()
CreateThread(function()
    local explosionType = 31
    local damageScale = 10.0
    local isAudible = true 
    local isInvisible = false
    local cameraShake = true
    for k,v in ipairs(explosions) do
        AddExplosion(
            v[1], v[2], v[3], 
            explosionType,
            damageScale,
            isAudible,
            isInvisible,
            cameraShake
        )
        Wait(100)
    end
    RequestIpl('map1')

    lowerWater()
end)

function lowerWater()
    local quads = {
        {1695.39, 18.144},
        {1669.474, 19.3},
        {1672.978, -4.389},
        {1673.489, -22.3},
        {1694.001, -19.022},
        {2008.293, 185.534},
        {1901.78, 187.882},
        {1973.662, 81.521},
        {1872.724, 65.684},
        {1804.932, 55.047},
        {1806.982, 28.036},
        {1662.224, 15.98},
        {1665.63, -2.83},
        {1656.647, 17.725},
        {1866.698, -30.5},
        {1770.095, 19.777},
        {1803.086, -69.154},
        {1993.349, 627.885},
        {2029.683, 641.391},
    }
    local waterQuads = {}
    local function isProcessed(waterQuadIndex)
        return waterQuadIndex ~= -1 and waterQuads[waterQuadIndex]
    end
    local function setProcessed(waterQuadIndex)
        waterQuads[waterQuadIndex] = 1
    end
    local function resetProcessed()
        waterQuads = {}
    end
    
    while true do
        for k,v in ipairs(quads) do
            local waterQuadIndex = GetWaterQuadAtCoords(v[1], v[2])
            if not isProcessed(waterQuadIndex) then
                local success, minX, minY, maxX, maxY = GetWaterQuadBounds(waterQuadIndex)
                local success = SetWaterQuadBounds(waterQuadIndex, minX, minY, maxX, maxY)
                local success, waterQuadLevel = GetWaterQuadLevel(waterQuadIndex)
                local success = SetWaterQuadLevel(waterQuadIndex, waterQuadLevel -0.01)
                setProcessed(waterQuadIndex)
            end
        end
        resetProcessed()
        Wait(0)
    end
end


local function drawQuadLines(waterQuad)
    local success, minX, minY, maxX, maxY = GetWaterQuadBounds(waterQuad)
    if success then
        local success, waterQuadLevel = GetWaterQuadLevel(waterQuad)
        
        minX, minY, maxX, maxY = minX + 0.0, minY + 0.0, maxX + 0.0, maxY + 0.0
        local lines = {
            {minX, minY, maxX, minY},
            {maxX, minY, maxX, maxY},
            {maxX, maxY, minX, maxY},
            {minX, maxY, minX, minY},
        }
        local red, green, blue, alpha = 0, 255, 0, 255
        for k,v in ipairs(lines) do
            local x1, y1, z1 = v[1], v[2], waterQuadLevel + 5.0
            local x2, y2, z2 = v[3], v[4], waterQuadLevel + 5.0
            DrawLine(x1, y1, z1, x2, y2, z2, red, green, blue, alpha)
        end

        DrawLine(minX, minY, waterQuadLevel, minX, minY, waterQuadLevel + 100.0, 255, 0, 0, alpha)


        local text = ("[ %s ]"):format(waterQuad)
        Draw3DText(minX, minY, waterQuadLevel, 1.0, text)
        print(text)
    end
end

local quads = {}
CreateThread(function()
    while true do
        Wait(0)
        for k,_ in pairs(quads) do
            drawQuadLines(k)
        end
    end
end)

-- Command for drawing water quad bounds
RegisterCommand('scanOne', function()
    local currentPedPosition = GetEntityCoords(PlayerPedId())
    local waterQuadIndex = GetWaterQuadAtCoords(currentPedPosition.x, currentPedPosition.y)
    local success, minX, minY, maxX, maxY = GetWaterQuadBounds(waterQuadIndex)
    quads[waterQuadIndex] = true
end)


local dist = 100.0
RegisterCommand('scanAll', function()
    local i = 0
    local currentPedPosition = GetEntityCoords(PlayerPedId())
    for x=currentPedPosition.x - dist, currentPedPosition.x + dist, 1 do
        for y=currentPedPosition.y - dist, currentPedPosition.y + dist, 1 do
            local waterQuadIndex = GetWaterQuadAtCoords(x, y)
            if waterQuadIndex ~= -1 then
                if not quads[waterQuadIndex] then
                    quads[waterQuadIndex] = true
                    i = i + 1
                end
            end
        end
    end
    print("Scanned " .. i .. " quads")
end)

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



-- Citizen.CreateThread(function()
--     -- Load the water.xml file
--     local success = LoadWaterFromPath(GetCurrentResourceName(), 'water.xml')
--     print(success)
-- end)
-- AddEventHandler("onResourceStop", function(resource)
--     -- Reset to default water.xml
--     ResetWater()
-- end)


--[[
    Взлом дамбы - слив воды (свет отключен)
    Противодействие - наполнение воды

    Пока вода наполняется свет ещё отключен
    Служит индикатором того, сколько времени осталось
    До включения электричества

    Пока электричество выключено, то что:
]]