--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local Ball = require('track1.Ball')
local HitParticle = require('track1.HitParticle')
local geom = require('geom')

local Game = {}

function Game.new()
    local o = {}
    setmetatable(o, {__index=Game})

    o:init()
    return o
end

local BPM = 132

-- returns music position as {phase, measure, beat, timeOfs}
function Game:musicPos()
    local timeOfs = self.music:tell()

    local beat = math.floor(timeOfs*BPM/60)
    timeOfs = timeOfs - beat*60/BPM

    local measure = math.floor(beat/4)
    beat = beat - measure*4

    local phase = math.floor(measure/16)
    measure = measure - phase*16

    return {phase, measure, beat, timeOfs}
end

-- seeks the music to a particular spot, using the same format as musicPos()
function Game:seekMusic(phase, measure, beat, timeOfs)
    local time = (phase or 0)
    time = time*16 + (measure or 0)
    time = time*4 + (beat or 0)
    time = time*60/BPM + (timeOfs or 0)
    self.music:seek(time)
end

function Game:init()
    print("1.load")
    self.music = love.audio.newSource('Refactor/01-little-bouncing-ball.mp3')
    self.phase = -1

    self.canvas = love.graphics.newCanvas(320, 240)
    self.canvas:setFilter("nearest", "nearest")

    self.bounds = {
        left = 8,
        right = 320 - 8,
        top = 8,
        bottom = 240
    }

    self.paddle = {
        x = 160,
        y = 220,
        w = 20,
        h = 2,

        vx = 0,
        vy = 0,

        speed = 6000,
        friction = 0.001,
        rebound = 0.5,
        tiltFactor = 0.01,

        -- get the upward vector for the paddle
        tiltVector = function(self)
            local x = self.vx * self.tiltFactor
            local y = -60
            local d = math.sqrt(x * x + y * y)
            return { x = x / d, y = y / d }
        end,

        getPolygon = function(self)
            local up = self:tiltVector()
            local rt = { x = -up.y, y = up.x }

            return {
                self.x + up.x*self.h - rt.x*self.w, self.y + up.y*self.h - rt.y*self.w,
                self.x + up.x*self.h + rt.x*self.w, self.y + up.y*self.h + rt.y*self.w,
                self.x - up.x*self.h + rt.x*self.w, self.y - up.y*self.h + rt.y*self.w,
                self.x - up.x*self.h - rt.x*self.w, self.y - up.y*self.h - rt.y*self.w
            }
        end,
    }
    local paddle = self.paddle

    self.particles = {}

    -- initialize with the starter ball
    self.balls = {
        Ball.new(self, {
            r = 3,
            color = {128, 255, 255, 255},
            lives = 3,
            hitColor = {0, 128, 128, 255},
            onUpdate = function(self, dt)
                self.vx = self.vx + dt*(paddle.x - self.x)
                self.vy = self.vy + dt*(paddle.y - self.y)
            end,
            onHitPaddle = function(self, nrm, paddle)
                self.onUpdate = Ball.onUpdate
                self.onHitPaddle = Ball.onHitPaddle
                self.onStart = Ball.onStart
                self.onLost = Ball.onLost
                self:onHitPaddle(nrm, paddle)
                self.game:setPhase(0)
            end,
            onStart = function(self)
                Ball.onStart(self)
                self.vx = 0
                self.vy = 0
            end,
            onLost = function(self)
                self:onStart()
            end
        })
    }

    print("ball count:" .. #self.balls)
end

function Game:setPhase(phase)
    print("setting phase to " .. phase)
    if phase == 0 then
        self.music:play()
    elseif phase == 1 then
        table.insert(self.particles, HitParticle.new(160, 120, 320, 240, {255, 0, 0}, 0.1))
        for i=1,5 do
            table.insert(self.balls, Ball.new(self))
        end
    elseif phase == 2 then
        table.insert(self.particles, HitParticle.new(160, 120, 320, 240, {255, 255, 0}, 0.1))
        for i=1,5 do
            table.insert(self.balls, Ball.new(self, {
                r = 1.5,
                color = {255, 255, 128, 255},
                hitColor = {255, 255, 0, 128},
                onStart = function(self)
                    Ball.onStart(self)
                    self.ay = 200
                    self.vx = 0
                    self.vy = 0
                end,
                lives = 6
            }))
        end
    elseif phase == 3 then
        -- table.insert(self.balls, SuperBall.new(self))
        -- TODO spawn bricks
    elseif phase == 4 then
        -- spawn aliens
    end

    self.phase = phase
end

function Game:keypressed(key, code, isrepeat)
    if key == '.' then
        self:seekMusic(self.phase + 1)
    end
end

function Game:update(dt)
    local p = self.paddle
    local b = self.bounds

    if self.music:isPlaying() then
        local phase = self:musicPos()[1]
        if phase > self.phase then
            self:setPhase(phase)
        end
    end

    if love.keyboard.isDown("right") then
        p.vx = p.vx + p.speed*dt
    end
    if love.keyboard.isDown("left") then
        p.vx = p.vx - p.speed*dt
    end
    p.vx = p.vx * math.pow(p.friction, dt)

    p.x = p.x + dt * p.vx
    p.y = p.y + dt * p.vy

    if p.x + p.w > b.right then
        p.x = b.right - p.w
        p.vx = -p.vx * p.rebound
    end
    if p.x - p.w < b.left then
        p.x = b.left + p.w
        p.vx = -p.vx * p.rebound
    end

    local paddlePoly = p:getPolygon()

    local nextBalls = {}
    for _,ball in pairs(self.balls) do

        ball:preUpdate(dt)
        ball:onUpdate(dt)

        -- test against walls
        if ball.x - ball.r < self.bounds.left then
            ball:onHitWall({1, 0}, self.bounds.left, ball.y)
        end
        if ball.x + ball.r > self.bounds.right then
            ball:onHitWall({-1, 0}, self.bounds.right, ball.y)
        end
        if ball.y - ball.r < self.bounds.top then
            ball:onHitWall({0, 1}, ball.x, self.bounds.top)
        end
        if ball.y - ball.r > self.bounds.bottom then
            ball:onLost()
        end

        -- test against paddle
        local c = geom.pointPolyCollision(ball.x, ball.y, ball.r, paddlePoly)
        if c then
            ball:onHitPaddle(c, self.paddle)
        end

        -- TODO test against actors

        ball:postUpdate(dt)

        if ball:isAlive() then
            table.insert(nextBalls, ball)
        end
    end
    self.balls = nextBalls

    local nextParticles = {}
    for _,particle in pairs(self.particles) do
        if particle:update(dt) then
            table.insert(nextParticles, particle)
        end
    end
    self.particles = nextParticles
end

function Game:draw()
    self.canvas:renderTo(function()
        love.graphics.clear(0, 0, 0)
        love.graphics.setBlendMode("alpha")

        love.graphics.print("phase=" .. self.phase .. " time=" .. table.concat(self:musicPos(), ':'), 0, 0)

        -- draw the particle effects
        for _,particle in pairs(self.particles) do
            particle:draw()
        end

        -- draw the paddle
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.polygon("fill", self.paddle:getPolygon())

        -- draw the balls
        for k,ball in pairs(self.balls) do
            ball:draw()
        end
    end)

    return self.canvas
end

return Game
