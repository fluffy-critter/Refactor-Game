--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

An alien that goes and fucks shit up

]]

local util = require('util')
local geom = require('geom')
local Actor = require('track1.Actor')
local Ball = require('track1.Ball')
local SparkParticle = require('track1.SparkParticle')

local Randomizer = {}
setmetatable(Randomizer, {__index = Actor})

function Randomizer.new(game, o)
    local self = o or {}
    setmetatable(self, {__index = Randomizer})

    self.game = game

    self:onInit()
    return self
end

Randomizer.states = {
    alive = 1,
    hit = 2,
    dying = 3,
    dead = 4
}

Randomizer.functions = {
    {
        key = "w", val = function()
            return math.random(30, 120)
        end
    },
    {
        key = "h", val = function()
            return math.random(3, 20)
        end
    },
    {
        key = "speed", val = function()
            return math.random(2000, 36000)
        end
    },
    {
        key = "friction", val = function()
            return math.random() * 0.02
        end
    },
    {
        key = "rebound", val = function()
            return math.random()
        end
    },
    {
        key = "tiltFactor", val = function()
            return math.random() * math.random() * 0.2
        end
    },
    {
        key = "recoil", val = function()
            return math.random() * 20
        end
    },
    {
        key = "recovery", val = function()
            return math.random() * 5
        end
    }
}

function Randomizer:onInit()
    local b = self.game.bounds

    util.applyDefaults(self, {
        lives = 5,
        centerX = (b.left + b.right) / 2,
        centerY = (b.top*2 + b.bottom) / 3,
        travelX = (b.right - b.left) / 2,
        travelY = (b.bottom - b.top) / 8,
        xFrequency = 1.13,
        yFrequency = 5.2,
        hitTime = 0.25,
        deadTime = 3,
        position = math.random()*10000,
        spawnInterval = 1,
        w = 64,
        h = 64,
        sizefuck = 32,
        particleCount = 30,
        particleLifetime = 0.2,
        particleVelocity = 100,
        score = 262144
    })

    self.x = self.centerX + math.sin(self.position*self.xFrequency)*self.travelX
    self.y = self.centerY + math.sin(self.position*self.yFrequency)*self.travelY

    self.state = Randomizer.states.alive
    self.stateAge = 0
    self.time = 0
    self.nextSpawn = 0
end

function Randomizer:draw()
    self.game.layers.overlay:renderTo(function()
        love.graphics.setBlendMode("alpha")
        local alpha = 255
        if self.state == Randomizer.states.dying then
            alpha = util.clamp(255*(1 - self.stateAge/self.deadTime), 0, 255)
        end
        love.graphics.setColor(math.random(192,255), math.random(192,255), math.random(192,255), alpha)
        local w = math.random(self.w - self.sizefuck, self.w)
        local h = math.random(self.h - self.sizefuck, self.h)
        -- TODO draw static instead
        love.graphics.rectangle("fill", self.x - w/2, self.y - h/2, w, h)
    end)
end

function Randomizer:isTangible(ball)
    return self.state == Randomizer.states.alive and ball.parent ~= self and not ball.isBullet
end

function Randomizer:preUpdate(_, dt)
    self.time = self.time + dt
    self.stateAge = self.stateAge + dt

    if self.time >= self.nextSpawn then
        if self.state == Randomizer.states.alive then
            self.game:defer(function(game)

                table.insert(game.balls, Ball.new(game, {
                    x = self.x,
                    y = self.y + self.h,
                    color = {math.random(128,255), math.random(128,255), math.random(128,255), 255},
                    r = math.random(3,7),
                    ay = 150,
                    vy = 300,
                    parent = self,
                    paddleScore = 1000,
                    paddleScoreInc = 0,
                    isBullet = true,
                    onStart = function()
                    end,
                    onHitPaddle = function(self, nrm, paddle)
                        self.lives = 0
                        table.insert(self.game.particles, SparkParticle.new({
                            x = paddle.x,
                            y = paddle.y,
                            color = self.color,
                            r = math.sqrt(paddle.w*paddle.w + paddle.h*paddle.h),
                            lifetime = 120/132
                        }))

                        -- choose a random status effect and apply it
                        for i=1,3 do
                            local effect = Randomizer.functions[math.random(1,#Randomizer.functions)]
                            local val = effect.val()
                            print("i shoot you! enjoy your " .. effect.key .. " being " .. val)
                            paddle[effect.key] = val
                        end
                        paddle.color = self.color
                    end
                }))
            end)
        end
        self.nextSpawn = self.nextSpawn + self.spawnInterval
    end

    self.position = self.position + dt
    self.x = self.centerX + math.sin(self.position*self.xFrequency)*self.travelX
    self.y = self.centerY + math.sin(self.position*self.yFrequency)*self.travelY

    -- TODO randomly warp self.position if alive

    if self.state == Randomizer.states.hit then
        if self.stateAge > self.hitTime then
            self.state = Randomizer.states.alive
            self.stateAge = 0
        end
    elseif self.state == Randomizer.states.dying then
        if self.stateAge > self.deadTime then
            self.state = Randomizer.states.dead
            self.stateAge = 0
        end
    end
end

function Randomizer:kill()
    if self.state < Randomizer.states.dying then
        self.state = Randomizer.states.dying
        self.stateAge = 0
        self.deadTime = 0.3
    end
end

function Randomizer:getPolygon()
    return {
        self.x - self.w/2, self.y - self.h/2,
        self.x + self.w/2, self.y - self.h/2,
        self.x + self.w/2, self.y + self.h/2,
        self.x - self.w/2, self.y + self.h/2,
    }
end

function Randomizer:getBoundingCircle()
    return {self.x, self.y, math.sqrt((self.w*self.w + self.h*self.h)/4)}
end

function Randomizer:onHitBall(nrm, ball)
    print("i been shot")

    if self.state ~= Randomizer.states.alive then
        return
    end

    self.lives = self.lives - 1
    self.stateAge = 0
    if self.lives == 0 then
        self.state = Randomizer.states.dying
        print("u kill me")
        self.game.score = self.game.score + self.score
    else
        self.state = Randomizer.states.hit
    end

    for i=1,self.particleCount do
        local vx, vy = unpack(geom.randomVector(self.particleVelocity))
        local vx = math.random(-500, 500)
        local vy = math.random(-500, 500)
        table.insert(self.game.particles, SparkParticle.new({
            x = self.x,
            y = self.y,
            r = math.random()*3,
            vx = vx,
            vy = vy,
            color = {math.random(128,255), math.random(128,255), math.random(128,255), 255},
            lifetime = self.particleLifetime
        }))
    end

    ball:onHitActor(nrm, self)
end

function Randomizer:isAlive()
    return self.state ~= Randomizer.states.dead
end

return Randomizer
