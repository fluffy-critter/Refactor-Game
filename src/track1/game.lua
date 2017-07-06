--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local Ball = require('track1.Ball')
local SuperBall = require('track1.SuperBall')
local HitParticle = require('track1.HitParticle')
local Brick = require('track1.Brick')
local Spawner = require('track1.Spawner')
local geom = require('geom')
local util = require('util')

local Game = {}

function Game.new()
    local o = {}
    setmetatable(o, {__index=Game})

    o:init()
    return o
end

local BPM = 132

-- returns music position as {phase, measure, beat}. beat will be fractional.
function Game:musicPos()
    local beat = self.music:tell()*BPM/60

    local measure = math.floor(beat/4)
    beat = beat - measure*4

    local phase = math.floor(measure/16)
    measure = measure - phase*16

    return {phase, measure, beat}
end

-- seeks the music to a particular spot, using the same format as musicPos(), with an additional timeOfs param that adjusts it by seconds
function Game:seekMusic(phase, measure, beat, timeOfs)
    local time = (phase or 0)
    time = time*16 + (measure or 0)
    time = time*4 + (beat or 0)
    time = time*60/BPM + (timeOfs or 0)
    self.music:seek(time)
end

function Game:init()
    print("1.load")
    self.music = love.audio.newSource('track1/01-little-bouncing-ball.mp3')
    self.phase = -1
    self.score = 0

    self.canvas = love.graphics.newCanvas(1280, 720)

    self.bounds = {
        left = 32,
        right = 1280 - 32,
        top = 32,
        bottom = 720
    }

    self.paddle = {
        x = 480,
        y = 660,
        w = 60,
        h = 6,

        vx = 0,
        vy = 0,

        speed = 18000,
        friction = 0.001,
        rebound = 0.5,
        tiltFactor = 0.01,

        -- get the upward vector for the paddle
        tiltVector = function(self)
            local x = self.vx * self.tiltFactor
            local y = -100
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
    self.actors = {}

    -- initialize with the starter ball
    self.balls = {
        Ball.new(self, {
            r = 10,
            color = {128, 255, 255, 255},
            lives = 3,
            hitColor = {0, 128, 128, 255},
            ay = 30,
            preUpdate = function(self, dt)
                Ball.preUpdate(self, dt)
                self.vx = self.vx + dt*(paddle.x - self.x)
                self.vy = self.vy + dt*(paddle.y - self.y)
            end,
            onHitPaddle = function(self, nrm, paddle)
                self.preUpdate = Ball.preUpdate
                self.onHitPaddle = Ball.onHitPaddle
                self.onStart = Ball.onStart
                self:onHitPaddle(nrm, paddle)
                self.game:setPhase(0)
            end,
            onStart = function(self)
                Ball.onStart(self)
                self.vx = 0
                self.vy = 0
            end,
            onLost = function(self)
                self.ay = self.ay + 30
            end
        })
    }

    self.deferred = {}

    self.spawner = Spawner.new(self)
    self.toKill = {}

    self.eventQueue = {}
    self.nextEvent = nil
    self:setGameEvents()
end

function Game:defer(item)
    tables.insert(self.deferred, item)
end

function Game:setGameEvents()
    -- spawn regular balls
    for _,when in pairs({1, 3, 5, 8, 10}) do
        table.insert(self.eventQueue, {
            when = {when},
            what = function()
                for i=1,5 do
                    table.insert(self.balls, Ball.new(self))
                end
            end
        })
    end

    -- spawn bouncy balls
    for _,when in pairs({2, 6, 7, 10}) do
        table.insert(self.eventQueue, {
            when = {when},
            what = function()
                for i=1,5 do
                    table.insert(self.balls, Ball.new(self, {
                        r = 4,
                        elasticity = 0.9,
                        color = {255, 255, 128, 255},
                        hitColor = {255, 255, 0, 128},
                        onStart = function(self)
                            Ball.onStart(self)
                            self.ay = 600
                            self.vx = 0
                            self.vy = 0
                        end,
                        lives = 6
                    }))
                end
            end
        })
    end

    -- spawn superballs
    for _,when in pairs({3, 4, 5, 7, 9}) do
        table.insert(self.eventQueue, {
            when = {when},
            what = function()
                table.insert(self.balls, SuperBall.new(self))
            end
        })
    end

    -- spawn staggered bricks
    table.insert(self.eventQueue, {
        when = {3},
        what = function()
        local bricks = {}
            local w = 64
            local h = 32
            local top = self.bounds.top + h/2
            local left = self.bounds.left + w/2
            local right = self.bounds.right - w/2
            local bottom = top + 12 * h
            for row = 1, 6 do
                local y = top + row * h
                local y2 = bottom - (w - top)
                local last = right
                if y2 == y then
                    last = (left + right)/2
                end
                for x = left - (row % 2)*w/2, last, w do
                    table.insert(bricks, {
                        color = {math.random(127,200), math.random(200,220), math.random(200,220), 255},
                            x = x, y = y, w = w, h = h
                    })
                    table.insert(bricks, {
                        color = {math.random(127,200), math.random(200,220), math.random(200,220), 255},
                            x = right - (x - left),
                            y = bottom - (y - top),
                            w = w, h = h
                    })
                end
            end
            self.spawner:spawn({self.actors, self.toKill}, Brick, bricks, 60/BPM/16, 2, 0)
        end
    })

    self.nextEvent = {0}
end


function Game:setPhase(phase)
    print("setting phase to " .. phase)

    for _,brick in pairs(self.toKill) do
        brick:kill()
    end
    self.toKill = {}

    if phase == 0 then
        self.music:play()
    end

    self.phase = phase
end

function Game:keypressed(key, code, isrepeat)
    if key == '.' then
        self:seekMusic(self.phase + 1)
    end
end

function Game:runEvents(time)
    if not self.nextEvent or util.arrayLT(self.nextEvent, time) then
        return
    end

    local removes = {}
    self.nextEvent = nil

    for idx,event in pairs(self.eventQueue) do
        if not util.arrayLT(time, event.when) then
            event.what(unpack(event.args or {}))
            table.insert(removes, idx)
        elseif not self.nextEvent or util.arrayLT(event.when, self.nextEvent) then
            self.nextEvent = event.when
        end
    end
    for _,r in ipairs(removes) do
        self.eventQueue[r] = nil
    end
end

function Game:update(dt)
    local p = self.paddle
    local b = self.bounds

    local time = self:musicPos()
    if self.music:isPlaying() then
        local phase = time[1]
        if phase > self.phase then
            self:setPhase(phase)
        end

        self:runEvents(time)
    end

    local pax = 0
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

    -- TODO: timeline judder

    local paddlePoly = p:getPolygon()

    self.spawner:update(dt)

    for _,ball in pairs(self.balls) do

        ball:preUpdate(dt)

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
            if ball:isAlive() then
                ball:onStart()
            end
        end

        -- test against paddle
        local c = geom.pointPolyCollision(ball.x, ball.y, ball.r, paddlePoly)
        if c then
            ball:onHitPaddle(c, self.paddle)
        end
    end

    for _,actor in pairs(self.actors) do
        actor:preUpdate(dt)
    end

    for _,actor in pairs(self.actors) do
        local poly = actor:getPolygon()
        for _,ball in pairs(self.balls) do
            nrm = actor:isTangible(ball) and geom.pointPolyCollision(ball.x, ball.y, ball.r, poly)
            if nrm then
                actor:onHitBall(nrm, ball)
            end
        end
    end

    local function doPostUpdates(cur)
        local removes = {}
        for idx,thing in pairs(cur) do
            thing:postUpdate(dt)
            if not thing:isAlive() then
                table.insert(removes, idx)
            end
        end
        for _,r in pairs(removes) do
            cur[r] = nil
        end
    end

    doPostUpdates(self.balls)
    doPostUpdates(self.actors)

    local removes = {}
    for idx,particle in pairs(self.particles) do
        if not particle:update(dt) then
            table.insert(removes, idx)
        end
    end
    for _,r in pairs(removes) do
        self.particles[r] = nil
    end

    for _,item in pairs(self.deferred) do
        item(self)
    end
    self.deferred = {}
end

function Game:draw()
    self.canvas:renderTo(function()
        love.graphics.clear(10, 10, 20)

        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(0,0,0,255)
        love.graphics.rectangle("fill",
            self.bounds.left, self.bounds.top,
            self.bounds.right - self.bounds.left, self.bounds.bottom - self.bounds.top)


        -- draw the particle effects
        for _,particle in pairs(self.particles) do
            particle:draw()
        end

        -- draw the paddle
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.polygon("fill", self.paddle:getPolygon())

        -- draw the actors
        for _,actor in pairs(self.actors) do
            actor:draw()
        end

        -- draw the balls
        for _,ball in pairs(self.balls) do
            ball:draw()
        end

        love.graphics.setColor(255,255,255,255)
        love.graphics.print("phase=" .. self.phase .. " score=" .. self.score, 0, 0)
    end)

    return self.canvas
end

return Game
