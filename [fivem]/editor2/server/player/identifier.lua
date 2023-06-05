function CollectPlayerIdentifiers(playerId)
    playerId = tonumber(playerId)
    local fivemid, steamid, license, discord, liveid, ip
    for _, identifier in pairs(GetPlayerIdentifiers(playerId)) do
        -- FiveM id
        if string.sub(identifier, 1, string.len('fivem:')) == 'fivem:' then
            fivemid = string.sub(identifier, string.len('fivem:') + 1,
                                 string.len(identifier))

            -- Steam id
        elseif string.sub(identifier, 1, string.len('steam:')) == 'steam:' then
            steamid = v

            -- License
        elseif string.sub(identifier, 1, string.len('license:')) == 'license:' then
            license = v

            -- IP
        elseif string.sub(identifier, 1, string.len('ip:')) == 'ip:' then
            ip = string.sub(identifier, string.len('ip:') + 1,
            string.len(identifier))
            -- Discord
        elseif string.sub(identifier, 1, string.len('discord:')) == 'discord:' then
            discord = v

            -- Live id
        elseif string.sub(identifier, 1, string.len('live:')) == 'live:' then
            liveid = v
        end
    end
    return {
        fivemid = fivemid,
        steamid = steamid,
        license = license,
        discord = discord,
        liveid = liveid,
        ip = ip
    }
end
