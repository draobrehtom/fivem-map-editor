-- @param state [boolean]
function Editor.ToggleEntityPreview(state)
    printlog('Editor.ToggleEntityPreview', state)
    if state then
        Editor.SelectEntity(-1)
        SaveFreecamState('stateBeforeEntityPreview')
        SetFreecamPosition(-1000, 0, 2500)
        SetFreecamRotation(-20, 0, 0)
        SetFreecamFrozen(true)
    else
        RestoreFreecamState('stateBeforeEntityPreview')
        SetFreecamFrozen(false)
    end
    Editor.StreamEntities(not state)
    Wait(0)
end

function Editor.PreviewEntity(model)
    printlog('Editor.PreviewEntity', model)
    if not Editor.IsEnabled() or not IsFreecamActive() then return end

    if Editor.EntityPreview then
        Editor.EntityPreview:SetModel(model)
    else
        Editor.EntityPreview = EntityPreview:New(model, GetFreecamPosition())
    end
end

function Editor.ClearEntityPreview()
    if Editor.EntityPreview then
        Editor.EntityPreview:Destroy()
        Editor.EntityPreview = nil
    end
    Editor.ToggleEntityPreview(false)
end

function Editor.CreateEntityFromPreview()
    if not Editor.EntityPreview then return end

    -- Store model first so its not nil after cleaning
    local model = Editor.EntityPreview.model

    -- Calculate target distance according to entity dimensions
    local w, d, h = GetEntityDimensions(Editor.EntityPreview.objectHandler)
    local DraggingDistance = math.floor(math.max(math.max(w, d), h)) * 3.0
    SetDraggingDistance(DraggingDistance)

    -- Clear
    Editor.ClearEntityPreview()
    NUI.SetVisible(false)
    Wait(0)

    local hitCoords = GetWorldDraggingPosition()
    if type(hitCoords) ~= 'vector3' then return end

    if IsModelAVehicle(model) then
        Editor.CreateVehicle({
            model = model,
            coords = hitCoords,
            select = true,
            drag = true
        })
    else
        Editor.CreateObject({
            model = model,
            coords = hitCoords,
            select = true,
            drag = true
        })
    end
end

-- Called from editor.js
RegisterNUICallback('formCreateEntity.preview',
                    function(post) Editor.PreviewEntity(post.model) end)

RegisterNUICallback('formCreateEntity.create',
                    function() Editor.CreateEntityFromPreview() end)

function Editor.IsEntityPreviewActive() return Editor.EntityPreview ~= nil end

-- Toggle checks
AddEventHandler('nui:formShown', function(formId)
    if formId == 'form_create_entity_preview' or formId == 'form_create_entity_vehicle' then
        if not Editor.IsEnabled() then
            return ShowNotification(
                       'This function works only when editor is ~g~enabled.')
        end
        Editor.ToggleEntityPreview(true)
    end
end)

AddEventHandler('editor:formHid', function(formId)
    if formId == 'form_create_entity_preview' or formId == 'form_create_entity_vehicle' then
        Editor.ClearEntityPreview()
    end
end)

AddEventHandler('editor:stateChanged', function(state)
    if state == false then Editor.ClearEntityPreview() end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        Editor.ClearEntityPreview()
    end
end)
