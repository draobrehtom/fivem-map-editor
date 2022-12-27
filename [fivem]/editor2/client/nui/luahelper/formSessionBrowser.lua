AddEventHandler('editor:sessionsUpdated', function(sessions)
    NUI.Call('formSessionBrowser.list.refresh',
             {sessions = sessions, inSession = CurrentSession.GetId() > 0})
end)

local function DisplaySessionInfo(sessionId)
    local session = GetSessionFromId(sessionId)
    if not session then return end

    NUI.Call('formSessionBrowser.session.display', {details = session})
end

AddEventHandler('nui:formShown', function(formId)
    if formId == 'form_session_browser' then EditorSessions.Request() end
end)

RegisterNUICallback('formSessionBrowser.session.select',
                    function(post) DisplaySessionInfo(post.id) end)

RegisterNUICallback('formSessionBrowser.session.join', function(post)
    TriggerServerEvent('session:requestJoin', post.id, post.password)
end)

RegisterNUICallback('formSessionBrowser.session.leave',
                    function() TriggerServerEvent('session:requestLeave') end)

RegisterNUICallback('formSessionBrowser.session.edit', function(post)
    local session = GetSessionFromId(tonumber(post.id))
    if not session then return end

    local post = {
        name = session.name,
        maximumSlots = session.maximumSlots,
        password = session.password
    }

    NUI.Call('formSessionEdit.updateFields', {fields = post})
end)
