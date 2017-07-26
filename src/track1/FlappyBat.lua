--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Flappy Bat, Flap-Flappy Bat, Flappy Bat, god dammit
]]

local geom = require('geom')
local util = require('util')
local imagepool = require('imagepool')

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
        color = {255, 192, 64},
        flapInterval = 60/self.game.BPM,
        flapVY = -600,
        scoreHit = 100,
        scoreDead = 100,
        spawnTime = 0.25,
        deathTime = 1.0,
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

    self.spriteSheet = imagepool.load("images/flappybat.png", {nearest=true,mipmaps=false})
    self.frames = {}
    for i = 1, 4 do
        self.frames[i] = love.graphics.newQuad((i - 1)*64, 0, 64, 64, 64*4, 64)
    end
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
        local frame
        if self.state == FlappyBat.states.dying then
            alpha = math.max(0, 255*(1 - self.stateAge/self.deathTime))
        elseif self.state == FlappyBat.states.spawning then
            alpha = 255*self.stateAge/self.spawnTime
        elseif self.state == FlappyBat.states.hit then
            local flash = math.floor(self.stateAge/self.hitFlashRate) % 2
            alpha = 127 + 128*flash
        end

        if self.state == FlappyBat.states.dying then
            frame = 4
        elseif self.vy >= self.flapVY/3 then
            frame = 1
        elseif self.flapTime > 0.2 then
            frame = 3
        else
            frame = 2
        end

        local flipX = self.x < self.game.paddle.x and 1 or -1

        love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
        love.graphics.draw(self.spriteSheet, self.frames[frame], self.x, self.y, 0, flipX, 1, 32, 32)
    end)
end


return FlappyBat

