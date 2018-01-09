--[[
Refactor: 7 - flight

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

a coin

]]

local util = require('util')

local Coin = {}

function Coin.new(o)
    local self = o or {}

    util.applyDefaults(self, {
        ay = 100,
        vy = 0,
        vx = 0,
        x = 0,
        y = 0,
    })

    setmetatable(self, {__index = Coin})
    return self
end

function Coin:update(dt, maxY)
    self.x = self.x + dt*self.vx
    self.y = self.y + dt*(self.vy + 0.5*dt*self.ay)
    self.vy = self.vy + dt*self.ay

    -- despawn if the coin has been collected or if it's fallen off the bottom of the screen forever
    -- TODO make the despawn logic based on a bit more useful stuff
    return self.collected or self.y > maxY and self.vy > 0
end

function Coin:draw()
    love.graphics.draw(self.sprite, self.quad, self.x, self.y)
end

return Coin
