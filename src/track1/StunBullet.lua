--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

RoamingEye - it looks at you piercingly
]]

local geom = require 'geom'
local util = require 'util'

local Ball = require 'track1.Ball'
local StunBullet = {}
setmetatable(StunBullet, {__index = Ball})

function StunBullet.new(game, o)
    local self = o or {}
    setmetatable(self, {__index = StunBullet})

    self.game = game
    self:onInit()
    return self
end

function StunBullet:onInit()
    util.applyDefaults(self, {
        lives = 1,
        r = 5,
        haloR = 10,
        haloLength = 0.1,
        isBullet = true,
        shots = 1,
        bulletColor = {1, .5, .25},
        safeColor = {.5, 1, 1},
        stunTime = self.game.BPM/180,
        recoil = 50
    })

    self.game:renderWater(0, function()
        love.graphics.circle("fill", self.x, self.y, self.r*2)
    end)

    Ball.onInit(self)
end

function StunBullet:onHitPaddle(nrm, paddle)
    self.shots = self.shots - 1
    if self.shots == 0 then
        self.isBullet = false
        self.onHitPaddle = Ball.onHitPaddle
    end

    self.game:renderWater(-1, function()
        love.graphics.circle("fill", self.x, self.y, self.r)
    end)

    paddle:stun(self.stunTime)

    Ball.onHitPaddle(self, nrm, paddle)
end

function StunBullet:draw()
    love.graphics.setBlendMode("alpha")

    if self.isBullet then
        love.graphics.setColor(unpack(self.bulletColor))
    else
        love.graphics.setColor(unpack(self.safeColor))
    end
    love.graphics.circle("fill", self.x, self.y, self.haloR)

    -- TODO halo length flicker

    local tx, ty = unpack(geom.normalize(geom.getNormal(0, 0, self.vx, self.vy), self.haloR))
    love.graphics.polygon("fill", {self.x + tx, self.y + ty,
        self.x - tx, self.y - ty,
        self.x - self.vx*self.haloLength, self.y - self.vy*self.haloLength
    })

    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", self.x, self.y, self.r)
end


return StunBullet
