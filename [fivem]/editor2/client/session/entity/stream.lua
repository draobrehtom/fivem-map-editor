-- Locals
local StreamEntities

function Editor.StreamingEntities() return StreamEntities end

function Editor.StreamEntities(state)
    if StreamEntities == state then return end

    StreamEntities = state
    printlog('Editor.StreamEntities', state)

    local function DoStreamEntities(fast)
        local counter = 0
        for _, entityInstance in pairs(Editor.entities) do
            if not StreamEntities then break end

            entityInstance:CheckExists(Editor.GetSelectedEntity())
            counter = counter + 1
            if not fast and (counter % 75) == 0 then Wait(15) end
        end
    end

    if state then
        DoStreamEntities(true)
        CreateThread(function()
            while StreamEntities do
                Wait(250)
                DoStreamEntities()
            end
        end)
    end
end
