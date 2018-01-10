--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Event queue runner

]]

local util = require('util')
local heap = require('thirdparty.binary_heap')

local EventQueue = {}

function EventQueue.new(obj)
    local self = obj or {}
    setmetatable(self, {__index=EventQueue})

    self.queue = heap:new(util.arrayLT)

    return self
end

-- Return the timestamp of the next event
function EventQueue:next()
    if self.queue:empty() then
        return nil
    end
    return self.queue:next_key()
end

function EventQueue:insert(...)
    for _,event in ipairs({...}) do
        assert(event.when, "missing event.when")
        assert(event.what and type(event.what) == "function", "event.what must be a function")

        self.queue:insert(event.when, event.what)
    end
end

-- Run all the events up to and including the current time. Events get the time in their callback
function EventQueue:run(time)
    while not self.queue:empty() and not util.arrayLT(time, self.queue:next_key()) do
        local _,event = self.queue:pop()
        event(time)
    end
end

return EventQueue
