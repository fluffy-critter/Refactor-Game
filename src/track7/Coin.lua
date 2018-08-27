--[[
Refactor: 7 - flight

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

a coin

]]

local util = require 'util'
local geom = require 'geom'
local config = require 'config'

local Coin = {}

function Coin.new(o)
    local self = o or {}

    util.applyDefaults(self, {
        vy = 0,
        vx = 0,
        x = 0,
        y = 0,
        r = 30,
        elastic = 0.3,
        color = {1,1,1},
        age = 0,
        frameSpeed = 12,
        frameTime = 0,
        baseSize = 125
    })

    setmetatable(self, {__index = Coin})
    return self
end

function Coin:update(dt, maxY)
    self.age = self.age + dt

    self.frameTime = self.frameTime + dt*self.frameSpeed

    if self.channel then
        local nrm = self.channel:checkCollision(self.x, self.y, self.r)
        if nrm then
            local oldV = geom.vectorLength({self.vx, self.vy})

            self.x = self.x + nrm[1]
            self.y = self.y + nrm[2]
            self.vx, self.vy = geom.reflectVector(nrm, self.vx*self.elastic, self.vy*self.elastic)

            local newV = geom.vectorLength({self.vx, self.vy})

            self.frameSpeed = util.clamp((self.frameSpeed + nrm[1]*10)*(newV + 100)/(oldV + 100)/self.elastic,
                -60, 60)
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
    love.graphics.setColor(unpack(self.color))
    if config.debug then
        love.graphics.circle("line", self.x, self.y, self.r)
    end

    if self.spriteSheetMultiply and self.quadsMultiply then
        local frame = math.floor(self.frameTime) % #self.quadsMultiply + 1
        local quad = self.quadsMultiply[frame]
        if not quad then
            print("frame=" .. frame .. " frameSpeed=" .. self.frameSpeed)
        end
        local _,_,w,h = quad:getViewport()
        love.graphics.setBlendMode("multiply", "premultiplied")
        love.graphics.draw(self.spriteSheetMultiply, quad, self.x, self.y, 0,
            self.r*2/self.baseSize, self.r*2/self.baseSize, w/2, h/2)
    end

    if self.spriteSheet and self.quads then
        local frame = math.floor(self.frameTime) % #self.quads + 1
        local quad = self.quads[frame]
        if not quad then
            print("frame=" .. frame .. " frameSpeed=" .. self.frameSpeed)
        end
        local _,_,w,h = quad:getViewport()
        love.graphics.setBlendMode("alpha", "alphamultiply")
        love.graphics.draw(self.spriteSheet, quad, self.x, self.y, 0,
            self.r*2/self.baseSize, self.r*2/self.baseSize, w/2, h/2)
    end
end

return Coin
