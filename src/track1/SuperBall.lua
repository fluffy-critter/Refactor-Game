--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local util = require('util')
local SparkParticle = require('track1.SparkParticle')
local Ball = require('track1.Ball')

local SuperBall = {}
setmetatable(SuperBall, {__index = Ball})

function SuperBall.new(game, o)
    local self = o or {}
    setmetatable(self, {__index = SuperBall})

    self.game = game
    self:onInit()
    self:onStart()

    return self
end

function SuperBall:onInit()
    util.applyDefaults(self, {
        r = 20,
        color = {255, 255, 127, 255},
        hitColor = {255, 255, 0, 255},
        spawnVelocity = 300,
        lives = 1,
        elasticity = 1.01,
        paddleScore = 5,
        paddleScoreInc = 0,
        scoreCooldown = 0.5,
        particleInterval = 0.01,
        particleLifetime = 0.3,
        particleVelocity = 50,
        particleCount = 3
    })

    Ball.onInit(self)

    self.particleTime = 0
end

function SuperBall:onStart()
    Ball.onStart(self)

    local tx, ty = unpack(self.game.paddle:tiltVector())
    self.vx = tx*self.spawnVelocity
    self.vy = ty*self.spawnVelocity
    self.x = self.game.paddle.x + tx*(self.r + self.game.paddle.h)
    self.y = self.game.paddle.y + ty*(self.r + self.game.paddle.h)
end

function SuperBall:onHitActor(nrm, actor)
    -- just barrel on through, getting slightly faster
    self.vx = self.vx*self.elasticity
    self.vy = self.vy*self.elasticity

    -- TODO bigger camera shake
end

function SuperBall:preUpdate(dt)
    Ball.preUpdate(self, dt)

    self.particleTime = self.particleTime + dt
    if self.particleTime > self.particleInterval then
        local particleCount = math.floor(self.particleTime/self.particleInterval)*self.particleCount
        for i=1,particleCount do
            local vx = math.random(-300, 300)
            local vy = math.random(-300, 300)
            if vx == 0 and vy == 0 then
                vx = math.random(0, 1)*2 - 1
                vy = math.random(0, 1)*2 - 1
            end

            local mag = math.sqrt(vx*vx + vy*vy)
            vx = vx/mag
            vy = vy/mag

            table.insert(self.game.particles,
                SparkParticle.new({
                    r = 4,
                    x = self.x + vx*self.r,
                    y = self.y + vy*self.r,
                    color = self.color,
                    blendMode = "add",
                    vx = vx * self.particleVelocity,
                    vy = vy * self.particleVelocity,
                    ax = vx * -0.2,
                    ay = vy * -0.2,
                    lifetime = self.particleLifetime
                }))
        end
        self.particleTime = self.particleTime - particleCount*self.particleInterval
    end
end

function SuperBall:draw()
    Ball.draw(self)

    -- TODO slight camera shake, draw into ripple layer
end

return SuperBall
