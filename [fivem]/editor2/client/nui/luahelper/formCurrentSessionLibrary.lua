AddEventHandler('nui:formShown', function(formId)
    if formId == 'form_current_session_library' then
        TriggerServerEvent('session:requestMapNames')
    end
end)

RegisterNetEvent('session:receiveMapNames')
AddEventHandler('session:receiveMapNames', function(post)
    local currentMap = type(CurrentSession.currentMap) == 'table' and CurrentSession.currentMap.name or nil
    NUI.Call('formCurrentSessionLibrary.list', {maps = post, currentMap = currentMap})
end)

RegisterNUICallback('formCurrentSessionLibrary.load', function(post)
    TriggerServerEvent('session:requestLoadMap', post)
end)

RegisterNUICallback('formCurrentSessionLibrary.export', function(post)
    TriggerServerEvent('session:requestExportMap', post.name)
end)
