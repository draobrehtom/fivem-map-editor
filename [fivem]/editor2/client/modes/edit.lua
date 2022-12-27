AddEventHandler('editor:modeChanged', function(modeOld, modeNew)
    -- From anything to 'edit'
    if modeNew == 'edit' then
        SetFreecamEnabled(true)

        -- From 'test' to 'edit'
        if modeOld == 'test' then
            DoScreenFadeOut(0)
            Wait(0)

            CurrentSession.RestoreEntities()

            DoScreenFadeIn(0)
            Wait(0)

            RestoreFreecamState('stateBeforeTestMode')
        end
    
        -- From 'edit' to anything
    elseif modeOld == 'edit' then
        -- From 'test' to 'edit'
        if modeNew == 'test' then
            SaveFreecamState('stateBeforeTestMode')
            DisplayRadar(true)
        end
        SetFreecamEnabled(false, modeNew == 'none')
    end
end)
