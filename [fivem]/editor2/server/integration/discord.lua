local API_DO_AUTH_URL = 'http://85.215.174.204:3000/doauth'
local API_CHECK_AUTH_URL = 'http://85.215.174.204:3000/checkauth'

RegisterCommand('xauth', function(source, args)
    local playerInstance = GetPlayerInstanceFromPlayerId(tonumber(source))
    if not playerInstance then return end

    printlog('[XAUTH] ' .. playerInstance:Get('playerName') .. ' used command /xauth')
    local authKey = args[1]
    if authKey then
        PerformHttpRequest(API_CHECK_AUTH_URL, function(err, response, header)
            local data = json.decode(response)
            printlog('[XAUTH] API response', err, data)
            if type(data) ~= 'table' then return end

            if data.success == 1 then
                AddChatMessage('You have successfully authenticated yourself.', playerId, 'success')
            else
                if data.err then
                    if data.err == '!fivemId' or data.err == '!discordId' or data.err == '!document' then
                        AddChatMessage('You must connect your Discord and FiveM accounts through our Discord server (#bot-channel) first. (Your FiveM id is: ' .. playerInstance.uId .. ')', playerId, 'information')
                    else
                        AddChatMessage('An unknown error occured.', playerId, 'error')
                    end

                else
                    AddChatMessage('An unknown error occured.', playerId, 'error')
                end
            end

        end, 'GET', json.encode(
                               {fivemId = playerInstance.uId, authKey = authKey}),
                           {['Content-Type'] = 'application/json'})
    else
        PerformHttpRequest(API_DO_AUTH_URL, function(err, response, header)
            local data = json.decode(response)
            printlog('[XAUTH] API response', err, data)
            if type(data) ~= 'table' then return end

            if data.success == 1 then
                AddChatMessage('You will receive your authentication code soon. Please check your Discord.', playerId, 'information')
            else
                if data.err then
                    if data.err == '!authenticated' then
                        AddChatMessage('You have already authenticated yourself.', playerId, 'information')

                    elseif data.err == '!fivemId' or data.err == '!discordId' or data.err == '!document' then
                        AddChatMessage('You must connect your Discord and FiveM accounts through our Discord server (#bot-channel) first. (Your FiveM id is: ' .. playerInstance.uId .. ')', playerId, 'information')
                    
                    else
                        AddChatMessage('An unknown error occured.', playerId, 'error')
                    end

                else
                    AddChatMessage('An unknown error occured.', playerId, 'error')
                end
            end

        end, 'GET', json.encode({fivemId = playerInstance.uId}),
                           {['Content-Type'] = 'application/json'})
    end
end, false)

AddEventHandler('player:setup', function(uId, data)
    local playerId = GetPlayerIdFromIdentifier(uId)
    if not playerId then return end

    AddChatMessage('You have been successfully identified. Your FiveM id is: ' .. uId, playerId, 'information')
end)
