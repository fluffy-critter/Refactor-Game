--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Configuration values:

retain - whether to retain spawned items (for future killing)

]]

local Spawner = {}

function Spawner.new(game, o)
    local self = o or {}
    setmetatable(self, {__index = Spawner})

    self.game = game
    self:onInit()

    return self
end

function Spawner:onInit()
    self.time = 0

    -- TODO this could probably just use EventQueue

    self.nextEvent = nil
    self.queue = {}
end

--[[ Spawn a bunch of things starting with the current time
targets - a list of lists to insert the object into
class - the class to spawn
items - a list of config objects for the class
interval - how often to spawn a group
count - the size of each spawn group
delay - how long to wait before spawning these objects (optional)
]]
function Spawner:spawn(targets, class, items, interval, count, delay)
    local time = self.time + (delay or 0)
    if not self.nextEvent or time < self.nextEvent then
        self.nextEvent = time
    end

    local n = 0
    for _,item in pairs(items) do
        table.insert(self.queue, {when = time, targets = targets, class = class, item = item})
        n = n + 1
        if n == count then
            time = time + interval
            n = 0
        end
    end
end

function Spawner:update(dt)
    self.time = self.time + dt

    if not self.nextEvent or self.time < self.nextEvent then
        return
    end

    local removes = {}
    self.nextEvent = nil

    for idx,spawn in ipairs(self.queue) do
        if spawn.when <= self.time then
            local obj = spawn.class.new(self.game, spawn.item)
            for _,tgt in pairs(spawn.targets) do
                table.insert(tgt, obj)
            end
            table.insert(removes, idx)
        elseif not self.nextEvent or spawn.when < self.nextEvent then
            self.nextEvent = spawn.when
        end
    end

    for i = #removes,1,-1 do
        self.queue[removes[i]] = self.queue[#self.queue]
        self.queue[#self.queue] = nil
    end
end

function Spawner:kill()
    self.queue = {}
    self.nextEvent = nil
end

return Spawner