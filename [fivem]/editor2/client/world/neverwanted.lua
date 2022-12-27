-- Optimization
local GetPlayerWantedLevel = GetPlayerWantedLevel
local SetPlayerWantedLevel = SetPlayerWantedLevel
local SetPlayerWantedLevelNow = SetPlayerWantedLevelNow
local Wait = Citizen.Wait
local PlayerId = PlayerId()

CreateThread(function()
    while true do
        if GetPlayerWantedLevel(PlayerId) ~= 0 then
            SetPlayerWantedLevel(PlayerId, 0, false)
            SetPlayerWantedLevelNow(PlayerId, false)
        end
        Wait(0)
    end
end)
