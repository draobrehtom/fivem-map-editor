function IsPlayerClient(playerId)
    return PlayerId() == GetPlayerFromServerId(playerId)
end

function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(true, true)
end
RegisterNetEvent('editor:showNotification')
AddEventHandler('editor:showNotification', ShowNotification)

function HelpNotification(text, sound)
    AddTextEntry(GetCurrentResourceName(), text)
    BeginTextCommandDisplayHelp(GetCurrentResourceName())
    EndTextCommandDisplayHelp(0, 0, (sound == true), -1)
end
RegisterNetEvent('editor:helpNotification')
AddEventHandler('editor:helpNotification', HelpNotification)

function round(num, numDecimalPlaces)
    if numDecimalPlaces and numDecimalPlaces > 0 then
        local mult = 10 ^ numDecimalPlaces
        return math.floor(num * mult + 0.5) / mult
    end
    return math.floor(num + 0.5)
end
