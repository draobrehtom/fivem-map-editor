-- Locals
local Vehicles = {}

-- @param properties [table]
function Editor.CreateVehicle(properties)
    if Editor.CurrentMode() ~= 'edit' then return end

    if type(properties) ~= 'table' or type(properties.model) ~= 'string' or
        type(properties.coords) ~= 'vector3' then
        return printlog('Editor.CreateVehicle', 'Action aborted. Invalid or missing argument(s).')
    end

    properties.class = 3
    Editor.RequestEntity(properties)
end

AddEventHandler('editor:entityHandlerCreated', function(entityInstance)
    if not entityInstance then return end

    if entityInstance.class == 3 then
        Vehicles[entityInstance.id] = true
        if Editor.CurrentMode() ~= 'test' then
            SetVehicleDoorsLocked(entityInstance.objectHandler, 2)
            SetVehicleUndriveable(entityInstance.objectHandler, true)
        end
    end
end)
