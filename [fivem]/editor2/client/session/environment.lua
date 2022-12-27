local function UpdateEnvironment(override)
    if override then SetOverrideWeather(WEATHER_FROM_NUMBER[CurrentSession.weather]) end
    NetworkOverrideClockTime(CurrentSession.timeH, CurrentSession.timeM, 0)
end

function CurrentSession.SetWeather(weather)
    if weather and WEATHER_FROM_NUMBER[weather] then
        CurrentSession.weather = weather
        if WEATHER_FROM_NUMBER[weather] == 'XMAS' then
            SetForceVehicleTrails(true)
            SetForcePedFootstepsTracks(true)
        else
            SetForceVehicleTrails(false)
            SetForcePedFootstepsTracks(false)
        end
        SetWeatherTypeOvertimePersist(WEATHER_FROM_NUMBER[weather], 15.0)
        UpdateEnvironment(true)
    end
end

function CurrentSession.SetTime(h, m)
    if (type(h) == 'number' and h >= 0 and h <= 23) and
        (type(m) == 'number' and m >= 0 and m <= 59) then
        CurrentSession.timeH, CurrentSession.timeM = h, m
        UpdateEnvironment(true)
    end
end

function CurrentSession.GetWeather() return CurrentSession.weather end

function CurrentSession.GetTime()
    return CurrentSession.timeH, CurrentSession.timeM
end

AddEventHandler('session:clientJoined', function()
    CurrentSession.SetWeather(2)
    CurrentSession.SetTime(12, 0)

    CreateThread(function()
        while CurrentSession.GetId() > 0 do
            UpdateEnvironment()
            Wait(1000)
        end
    end)
end)

AddEventHandler('session:dataChanged', function(key, value)
    if key == 'environment' then
        CurrentSession.SetWeather(value.weather or 2)
        if type(value.time) == 'table' then
            CurrentSession.SetTime(value.time.hour, value.time.minute)
        else
            CurrentSession.SetTime(12, 0)
        end
    end
end)
