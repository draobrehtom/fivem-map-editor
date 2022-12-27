RegisterNUICallback('nui.ready', function() TriggerEvent('nui:ready') end)

RegisterNUICallback('nui.formShown', function(post)
    TriggerEvent('nui:formShown', tostring(post.id))
end)

RegisterNUICallback('nui.formHid', function(post)
    TriggerEvent('editor:formHid', tostring(post.id))
end)

RegisterNUICallback('nui.keyPressed', function(post)
    if not NUI.IsVisible() or CurrentSession.GetId() < 1 then return end
    if post.key == 113 then
        NUI.SetVisible(false)
    elseif post.key == 112 then
        Editor.SetEnabled(false)
    end
end)
