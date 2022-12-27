-- Optimization
local RemoveMultiplayerHudCash = RemoveMultiplayerHudCash
local RemoveMultiplayerBankCash = RemoveMultiplayerBankCash
local Wait = Citizen.Wait

CreateThread(function()
    while true do
        RemoveMultiplayerHudCash(0x968F270E39141ECA)
        RemoveMultiplayerBankCash(0xC7C6789AA1CFEDD0)
        Wait(0)
    end
end)
