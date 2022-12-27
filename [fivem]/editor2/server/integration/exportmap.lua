local API_EXPORT_PATH_URL = 'http://85.215.174.204:3000/export'

function SendContentToPlayer(playerId, mapName, meta, content)
    local playerInstance = GetPlayerInstanceFromPlayerId(tonumber(playerId))
    if not playerInstance then return end

    if type(mapName) ~= 'string' or type(content) ~= 'string' then return end
    
    printlog('[EXPORT] Player ' .. playerInstance:Get('playerName') .. ' wants to export map ' .. mapName)
    PerformHttpRequest(API_EXPORT_PATH_URL, function(err, response, header)
        local data = json.decode(response)
        printlog('[EXPORT] API response', err, data)
        if type(data) ~= 'table' then return end

        if data.success == 1 then
            AddChatMessage('You have successfully exported map: ' .. mapName ..'. Please check your Discord.', playerId, 'success')
        else
            if data.err then
                if data.err == '!authenticated' then
                    AddChatMessage('You must connect your Discord and FiveM accounts through our Discord server (#bot-channel) before exporting a map. (Your FiveM id is: ' .. playerInstance.uId .. ')', playerId, 'information')
                else
                    AddChatMessage('An unknown error occured.', playerId, 'error')
                end

            else
                AddChatMessage('An unknown error occured.', playerId, 'error')
            end
        end

    end, 'GET', json.encode({
        fivemId = playerInstance.uId,
        mapName = mapName,
        meta = meta,
        content = content
    }), {['Content-Type'] = 'application/json'})
end
