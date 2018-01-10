--[[
Refactor: 7 - flight

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

a coin

]]

local util = require('util')
local geom = require('geom')

local Coin = {}

function Coin.new(o)
    local self = o or {}

    util.applyDefaults(self, {
        vy = 0,
        vx = 0,
        x = 0,
        y = 0,
        r = 30,
        elastic = 0.3
    })

    setmetatable(self, {__index = Coin})
    return self
end

function Coin:update(dt, maxY)
    if self.channel then
        local nrm = self.channel:checkCollision(self.x, self.y, self.r)
        if nrm then
            self.x = self.x + nrm[1]
            self.y = self.y + nrm[2]
            self.vx, self.vy = geom.reflectVector(nrm, self.vx*self.elastic, self.vy*self.elastic)
        end
    end

    self.x = self.x + dt*self.vx
    self.y = self.y + dt*(self.vy + 0.5*dt*self.ay)
    self.vy = self.vy + dt*self.ay

    -- despawn if the coin has fallen off the bottom of the screen forever
    -- TODO make the despawn logic based on a bit more useful stuff
    return self.y > maxY and self.vy > 0
end

function Coin:draw()
    love.graphics.circle("line", self.x, self.y, self.r)
    -- love.graphics.draw(self.sprite, self.quad, self.x, self.y)
end

return Coin
