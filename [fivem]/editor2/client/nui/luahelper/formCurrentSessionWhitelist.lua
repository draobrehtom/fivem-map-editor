local Players

AddEventHandler('nui:formShown', function(formId)
    if formId == 'form_current_session_whitelist' then
        TriggerServerEvent('session:requestWhitelist')
    else
        Players = nil
    end
end)

RegisterNetEvent('session:receiveWhitelist')
AddEventHandler('session:receiveWhitelist',
                function(err, players, whitelist, whitelistEnabled)
    if err ~= 0 then
        return NUI.Call('formCurrentSessionWhitelist.list', {err = 1})
    end

    if type(players) == 'table' and type(whitelist) == 'table' then
        for _, player in pairs(players) do
            for _, id in pairs(whitelist) do
                if tostring(id) == tostring(player.uId) then
                    player.aced = 1
                    break
                end
            end
            if not player.aced then player.aced = 0 end
        end

        table.sort(players, function(a, b) return a.aced > b.aced end)
        NUI.Call('formCurrentSessionWhitelist.list',
                 {players = players, whitelistEnabled = whitelistEnabled})
        Players = players
    end
end)

RegisterNUICallback('formCurrentSessionWhitelist.toggleAce', function(post)
    if type(Players) ~= 'table' then return end

    for _, player in pairs(Players) do
        if tostring(player.uId) == tostring(post.id) then
            player.aced = post.ace
            break
        end
    end
    NUI.Call('formCurrentSessionWhitelist.list', {players = Players})
end)

RegisterNUICallback('formCurrentSessionWhitelist.save', function(post)
    if type(Players) ~= 'table' then return end

    TriggerServerEvent('session:toggleWhitelist', post.disableWhitelist)
    if not post.disableWhitelist then
        local whitelist = {}
        for _, player in pairs(Players) do
            if player.aced == 1 then
                table.insert(whitelist, player.uId)
            end
        end
        TriggerServerEvent('session:saveWhitelist', whitelist)
    end
end)
