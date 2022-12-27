AddEventHandler('nui:ready', function() NUI.SetVisible(true) end)

local function HandleSessionStart() NUI.SetVisible(false) end
AddEventHandler('session:clientJoined', HandleSessionStart)

local function HandleSessionEnd() NUI.SetVisible(true) end
AddEventHandler('session:clientLeft', HandleSessionEnd)

AddEventHandler('editor:stateChanged', function(state)
    if state == false and CurrentSession.GetId() > 0 then
        NUI.SetVisible(false)
    end
end)
