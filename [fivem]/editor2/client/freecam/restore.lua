local Saves = {}

function SaveFreecamState(stateName)
    if type(stateName) ~= 'string' then return end

    Saves[stateName] = {
        position = GetFreecamPosition(),
        rotation = GetFreecamRotation()
    }
    printlog('SaveFreecamState', 'Saving freecam state with the name ' .. stateName)
end

function RestoreFreecamState(stateName)
    if type(stateName) ~= 'string' or not Saves[stateName] then return end

    local state = Saves[stateName]
    printlog('RestoreFreecamState', 'Restoring freecam state from save ' .. stateName)
    SetFreecamPosition(state.position.x, state.position.y, state.position.z)
    SetFreecamRotation(state.rotation.x, state.rotation.y, state.rotation.z)
    Saves[stateName] = nil
end
