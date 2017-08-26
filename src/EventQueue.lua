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

function EventQueue:addEvent(when, what)
    -- TODO normalize timepos to actual timecode

    table.insert(self.queue, {when = when, what = what})
    if not self.nextEvent or util.arrayLT(when, self.nextEvent) then
        self.nextEvent = when
    end
end

-- Copy in a bunch of events at once
function EventQueue:addEvents(tbl)
    for _,event in ipairs(tbl) do
        table.insert(self.queue, event)
        if not self.nextEvent or util.arrayLT(event.when, self.nextEvent) then
            self.nextEvent = event.when
        end
    end
end

-- Run all the events up to and including the current time. Events get the time in their callback
function EventQueue:runEvents(time)
    if not self.nextEvent or util.arrayLT(time, self.nextEvent) then
        return
    end

    local removes = {}
    self.nextEvent = nil

    for idx,event in ipairs(self.queue) do
        if not util.arrayLT(time, event.when) then
            event.what(time)
            table.insert(removes, idx)
        elseif not self.nextEvent or util.arrayLT(event.when, self.nextEvent) then
            self.nextEvent = event.when
        end
    end

    for i = #removes,1,-1 do
        self.queue[removes[i]] = self.queue[#self.queue]
        self.queue[#self.queue] = nil
    end
end

return EventQueue
