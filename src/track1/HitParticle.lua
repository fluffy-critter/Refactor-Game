--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local util = require 'util'

local HitParticle = {}

function HitParticle.new(cfg)
    local self = cfg or {}
    setmetatable(self, {__index=HitParticle})

    util.applyDefaults(self, {
        blendMode = "alpha",
        gamma = 1
    })

    self.time = 0

    return self
end

function HitParticle:update(dt)
    self.time = self.time + dt
    return self.time >= 0 and self.time < self.lifetime
end

function HitParticle:draw()
    love.graphics.setBlendMode(self.blendMode)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3],
        (self.color[4] or 255)*util.clamp(1 - self.time/self.lifetime, 0, 1))
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

return HitParticle
