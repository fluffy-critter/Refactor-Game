--[[
Refactor: 7 - flight

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

the channel through which we are descending

]]

local util = require('util')
local geom = require('geom')

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

-- determine if the circle at (x,y,r) collides with the channel, and provide the collision vector if so
function Channel:checkCollision(x, y, r)
    local startIdx = math.floor((y - r)/self.interval)
    local endIdx = math.ceil((y + r)/self.interval)

    local nrm

    -- cached polygons for garbage reduction
    local lpoly = {
        -10000, nil,
        nil, nil,
        nil, nil,
        -10000, nil
    }

    local rpoly = {
        nil, nil,
        10000, nil,
        10000, nil,
        nil, nil
    }

    local y0 = startIdx*self.interval
    local y1 = y0 + self.interval
    for i = startIdx, endIdx - 1 do
        local top = self.edges[i]
        local bottom = self.edges[i + 1]

        if top and bottom then
            if x - r < math.max(top[1], bottom[1]) then
                -- adjust the left polygon for here
                -- lpoly[1] = -10000
                lpoly[2] = y0

                lpoly[3] = top[1]
                lpoly[4] = y0

                lpoly[5] = bottom[1]
                lpoly[6] = y1

                -- lpoly[7] = -10000
                lpoly[8] = y1

                local ln = geom.pointPolyCollision(x, y, r, lpoly)
                if ln then
                    nrm = nrm and {nrm[1] + ln[1], nrm[2] + ln[2]} or ln
                end
            end

            if x + r > math.min(top[2], bottom[2]) then
                -- adjust the right polygon for here
                rpoly[1] = top[2]
                rpoly[2] = y0

                -- rpoly[3] = 10000
                rpoly[4] = y0

                -- rpoly[5] = 10000
                rpoly[6] = y1

                rpoly[7] = bottom[2]
                rpoly[8] = y1

                local rn = geom.pointPolyCollision(x, y, r, rpoly)
                if rn then
                    nrm = nrm and {nrm[1] + rn[1], nrm[2] + rn[2]} or rn
                end
            end
        end

        y0 = y0 + self.interval
        y1 = y1 + self.interval
    end

    return nrm
end

function Channel:draw(startY, endY)
    local startIdx = math.floor(startY/self.interval)
    local endIdx = math.ceil(endY/self.interval)

    local y0 = startIdx*self.interval
    local y1 = y0 + self.interval

    love.graphics.setColor(255,255,255)
    for i = startIdx, endIdx - 1 do
        local top = self.edges[i]
        local bottom = self.edges[i + 1]

        if top and bottom then
            love.graphics.line(top[1], y0, bottom[1], y1)
            love.graphics.line(top[2], y0, bottom[2], y1)
        end

        y0 = y0 + self.interval
        y1 = y1 + self.interval
    end
end

return Channel
