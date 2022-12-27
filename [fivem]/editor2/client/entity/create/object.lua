-- @param properties [table]
function Editor.CreateObject(properties)
    if Editor.CurrentMode() ~= 'edit' then return end

    if type(properties) ~= 'table' or type(properties.model) ~= 'string' or
        type(properties.coords) ~= 'vector3' then
        return printlog('Editor.CreateObject',
                        'Action aborted. Invalid or missing argument(s).')
    end

    properties.class = 2
    Editor.RequestEntity(properties)
end
