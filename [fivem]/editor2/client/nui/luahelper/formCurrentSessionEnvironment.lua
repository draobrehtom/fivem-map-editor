RegisterNUICallback('formCurrentSessionEnvironment.apply', function(post)
    TriggerServerEvent('session:changeEnvironment', post)
end)

AddEventHandler('nui:formShown', function(formId)
    if formId == 'form_current_session_environment' then
        NUI.Call('formCurrentSessionEnvironment.updateFields', {
            weather = CurrentSession.GetWeather(),
            time = {CurrentSession.GetTime()}
        })
    end
end)
