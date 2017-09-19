--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Event queue runner

]]

local util = require('util')

local EventQueue = {}

function EventQueue.new(obj)
    local self = obj or {}
    setmetatable(self, {__index=EventQueue})

    self.queue = {}

    return self
end

function EventQueue:addEvent(event)
    -- TODO normalize timepos to actual timecode

    assert(event.when)
    assert(event.what)

    table.insert(self.queue, event)
    if not self.nextEvent or util.arrayLT(event.when, self.nextEvent) then
        self.nextEvent = event.when
    end
end

-- Copy in a bunch of events at once
function EventQueue:addEvents(tbl)
    for _,event in ipairs(tbl) do
        self:addEvent(event)
    end
end

-- Run all the events up to and including the current time. Events get the time in their callback
function EventQueue:runEvents(time)
    if not self.nextEvent or util.arrayLT(time, self.nextEvent) then
        return
    end

    self.nextEvent = nil

    util.runQueue(self.queue, function(event)
        if not util.arrayLT(time, event.when) then
            event.what(time)
            return true
        elseif not self.nextEvent or util.arrayLT(event.when, self.nextEvent) then
            self.nextEvent = event.when
        end
    end)
end

return EventQueue