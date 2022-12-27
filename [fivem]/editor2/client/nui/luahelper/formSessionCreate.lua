RegisterNUICallback('formSessionCreate.create', function(post)
    if type(post.name) ~= 'string' or string.len(post.name) < 3 then return end

    NUI.Call('formSessionCreate.waitUntilCreated')
    TriggerServerEvent('session:requestCreate', post)
end)

RegisterNetEvent('session:createCallback')
AddEventHandler('session:createCallback', function(err, createdSession)
    NUI.Call('formSessionCreate.createCallback')
    if err ~= 0 then return end

    TriggerEvent('editor:addNotification', {
        title = 'Session',
        message = 'You have successfuly created session: ' ..
            createdSession.name,
        icon = 'circle'
    })
end)
