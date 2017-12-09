--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local util = require('util')
local gfx = require('gfx')

local SparkParticle = {}

function SparkParticle.new(cfg)
    local self = cfg or {}
    setmetatable(self, {__index=SparkParticle})

    util.applyDefaults(self, {
        r = 1,
        h = 1,
        gamma = 1,
        blendMode = "add",
        vx = 0,
        vy = 0,
        ax = 0,
        ay = 0
    })

    self.time = 0

    return self
end

function SparkParticle:update(dt)
    self.time = self.time + dt

    self.vx = self.vx + dt*self.ax
    self.vy = self.vy + dt*self.ay

    self.x = self.x + dt*self.vx
    self.y = self.y + dt*self.vy

    return self.time >= 0 and self.time < self.lifetime
end

function SparkParticle:draw()
    local size = util.clamp(1 - self.time/self.lifetime, 0, 1)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3],
        (self.color[4] or 255)*math.pow(size, self.gamma))
    gfx.circle(true, self.x, self.y, self.r)
end

return SparkParticle
