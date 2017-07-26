--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Flappy Bat, Flap-Flappy Bat, Flappy Bat, god dammit
]]

local geom = require('geom')
local util = require('util')

local Actor = require('track1.Actor')

local FlappyBat = {}
setmetatable(FlappyBat, {__index = Actor})

FlappyBat.states = util.enum("spawning", "alive", "hit", "dying", "dead")

function FlappyBat.new(game, o)
    local self = o or {}
    setmetatable(self, {__index = FlappyBat})

    self.game = game

    self:onInit()
    return self
end

function FlappyBat:onInit()
    local b = self.game.bounds

    util.applyDefaults(self, {
        lives = 3,
        r = 24,
        color = {127, 127, 255},
        flapInterval = 60/self.game.BPM,
        flapVY = -600,
        scoreHit = 100,
        scoreDead = 100,
        spawnTime = 0.25,
        hitTime = 0.25,
        hitFlashRate = 1/20,
        rebound = 0.1,
        rising = true,
    })

    util.applyDefaults(self, {
        vx = math.random(-200,200),
        vy = 0,
        -- -v = v + at -> a=-2v/t
        ay = -1.5*self.flapVY/self.flapInterval,

        minX = b.left + self.r,
        maxX = b.right - self.r,
        minY = b.top + self.r + 100,
        maxY = (b.bottom - b.top)*.75 - self.r
    })

    util.applyDefaults(self, {
        x = math.random(self.minX, self.maxX),
        y = math.random(self.minY, self.maxY),
    })

    self.state = FlappyBat.states.spawning
    self.stateAge = 0
    self.flapTime = 0
end

function FlappyBat:isAlive()
    return self.state ~= FlappyBat.states.dead
end

function FlappyBat:preUpdate(dt, rawt)
    self.stateAge = self.stateAge + rawt

    if self.state == FlappyBat.states.spawning and self.stateAge > self.spawnTime then
        self.stateAge = 0
        self.state = FlappyBat.states.alive
    elseif self.state == FlappyBat.states.hit and self.stateAge > self.hitTime then
        self.stateAge = 0
        self.state = FlappyBat.states.alive
        return
    elseif self.state == FlappyBat.states.dying and self.y > self.game.bounds.bottom + self.r then
        self.state = FlappyBat.states.dead
    end

    if self.state >= FlappyBat.states.hit then
        return
    end

    if self.x < self.minX then
        self.x = self.minX
        self.vx = math.abs(self.vx)
    elseif self.x > self.maxX then
        self.x = self.maxX
        self.vx = -math.abs(self.vx)
    end

    self.flapTime = self.flapTime + rawt

    local flap = false

    if self.y < self.minY then
        self.rising = false
    elseif self.y > self.maxY then
        self.rising = true
        flap = true
    end

    if self.rising and self.flapTime > self.flapInterval then
        flap = true
    end

    if flap then
        print(self.rising)
        self.flapTime = 0
        self.vy = self.flapVY
    end

end

function FlappyBat:postUpdate(dt)
    if self.state >= FlappyBat.states.dead then
        return
    end

    self.x = self.x + self.vx*dt
    self.y = self.y + (self.vy + self.ay*dt/2)*dt
    self.vy = self.vy + self.ay*dt
end

function FlappyBat:checkHitBalls(balls)
    for _,ball in pairs(balls) do
        if not ball.isBullet then
            -- TODO proper bounding test (or maybe we make flappybat a circle in a lazyass way)
            nrm = geom.pointPointCollision(ball.x, ball.y, ball.r, self.x, self.y, self.r)
            if nrm then
                self:onHitBall(nrm, ball)
            end
        end
    end
end

function FlappyBat:kill()
    if self.state < FlappyBat.states.dying then
        self.state = FlappyBat.states.dying
        self.stateAge = 0
    end
end

function FlappyBat:onHitBall(nrm, ball)
    -- keep it immune while balls are passing through it
    if self.state == FlappyBat.states.hit then
        self.stateAge = self.stateAge % (self.hitFlashRate * 2)
    end

    if self.state ~= FlappyBat.states.alive then
        return
    end

    ball:onHitActor(nrm, self)

    local nx, ny = unpack(nrm)
    self.vx = self.vx - self.rebound*nx*ball.r*ball.r/self.r/self.r
    self.vy = self.vy - self.rebound*nx*ball.r*ball.r/self.r/self.r

    self.lives = self.lives - 1
    if self.lives < 1 then
        self.game.score = self.game.score + self.scoreDead
        self:kill()
    else
        self.game.score = self.game.score + self.scoreHit
        self.state = FlappyBat.states.hit
        self.stateAge = 0
    end
end

function FlappyBat:draw()
    self.game.layers.overlay:renderTo(function()
        local alpha = 255
        if self.state == FlappyBat.states.dying then
            alpha = 127
        elseif self.state == FlappyBat.states.spawning then
            alpha = 255*self.stateAge/self.spawnTime
        elseif self.state == FlappyBat.states.hit then
            local flash = math.floor(self.stateAge/self.hitFlashRate) % 2
            alpha = 127 + 128*flash
        end

        love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
        love.graphics.circle("fill", self.x, self.y, self.r)
    end)
end


return FlappyBat

