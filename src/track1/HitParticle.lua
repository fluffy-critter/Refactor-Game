--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local HitParticle = {}

function HitParticle.new(cx, cy, w, h, color, duration)
    local self = {}
    setmetatable(self, {__index=HitParticle})

    self.x = cx - w/2
    self.y = cy - h/2
    self.w = w
    self.h = h
    self.color = color
    self.time = 0
    self.duration = duration

    return self
end

function HitParticle:update(dt)
    self.time = self.time + dt
    return self.time >= 0 and self.time < self.duration
end

function HitParticle:draw()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], (self.color[4] or 255)*(1 - self.time/self.duration))
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return HitParticle