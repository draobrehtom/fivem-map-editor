EditorThread = {}
EditorThread.__index = EditorThread
EditorThread.instances = {}

function EditorThread:Create(params)
    if type(params) ~= 'table' then return nil
    elseif type(params.callFunction) ~= 'function' then return nil end

    local id = #EditorThread.instances + 1
    local instance = setmetatable({
        id = id,
        callFunction = params.callFunction,
        condition = type(params.condition) == 'function' and params.condition or nil,
        delay = tonumber(params.delay) or 0
    }, self)

    EditorThread.instances[id] = instance
    return instance
end

function EditorThread:Run()
    if self.running then return end

    CreateThread(function()
        while true do
            if self.condition and not self.condition() then
                self.running = false
                return
            end
            self.callFunction()
            Wait(self.delay)
        end
    end)
    self.running = true
    return EditorThread.instances[self.id]
end

function EditorThread:Terminate()
    if self.running then self.condition = function() return false end end

    EditorThread.instances[self.id] = nil
    self.id = 0
    self.callFunction = nil
end
