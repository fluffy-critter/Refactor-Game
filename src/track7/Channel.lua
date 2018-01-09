--[[
Refactor: 7 - flight

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

the channel through which we are descending

]]

local util = require('util')

local Channel = {}

function Channel.new(o)
    local self = o or {}

    util.applyDefaults(self, {
        interval = 100,
        edges = {},
        bottom = 0,
    })

    setmetatable(self, {__index = Channel})
    return self
end

-- given a Y position and a height, return the minimal extents for safe passage as left,right
function Channel:getExtents(y0, y1)
    local maxL, minR
    for i = math.floor(y0/self.interval), math.ceil(y1/self.interval) do
        local cur = self.edges[i]
        if cur then
            maxL = math.max(maxL or cur[1], cur[1])
            minR = math.min(minR or cur[2], cur[2])
        end
    end

    return maxL, minR
end

-- fill out the bottom of the channel, calling the onNeeded callback when we need new values
-- onNeeded takes (channel,y), returns {left,right}
function Channel:update(bottom, onNeeded)
    local startIdx = math.floor(self.bottom/self.interval)
    local endIdx = math.ceil(bottom/self.interval)

    for i = startIdx, endIdx do
        if not self.edges[i] then
            self.edges[i] = onNeeded(i*self.interval)
        end
    end

    self.bottom = endIdx*self.interval
end

function Channel:draw(startY, endY)
    local startIdx = math.floor(startY/self.interval)
    local endIdx = math.ceil(endY/self.interval)
    for i = startIdx, endIdx do
        -- TODO put in rocky texture thing
        local y0 = i*self.interval
        local edges = self.edges[i]
        if edges then
            local left,right = unpack(edges)
            love.graphics.setColor(0,0,0)
            love.graphics.rectangle("fill", -1000, y0, left + 800, self.interval)
            love.graphics.rectangle("fill", right + 200, y0, 1000, self.interval)

            love.graphics.setColor(255,255,255)
            if self.leftQuad and self.spriteSheet then
                love.graphics.draw(self.spriteSheet, self.leftQuad, left - 430, y0 - 10)
            end
            if self.rightQuad and self.spriteSheet then
                love.graphics.draw(self.spriteSheet, self.rightQuad, right, y0 - 10)
            end
        end
    end
end

return Channel
