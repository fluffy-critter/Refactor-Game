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

    return {phase, measure, beat, timeOfs}
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
    self.actors = {}

    -- initialize with the starter ball
    self.balls = {
        Ball.new(self, {
            r = 3,
            color = {128, 255, 255, 255},
            lives = 3,
            hitColor = {0, 128, 128, 255},
            ay = 10,
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
                self.ay = self.ay + 10
            end
        })
    }

    self.deferred = {}

    self.spawner = Spawner.new(self)
    self.toKill = {}
end

function Game:defer(item)
    tables.insert(self.deferred, item)
end

function Game:setPhase(phase)
    print("setting phase to " .. phase)

    -- TODO this should really just be an event queue thing (which will be useful for the other games too)

    for _,brick in pairs(self.toKill) do
        brick:kill()
    end
    self.toKill = {}

    if phase == 3 or phase == 4 or phase == 5 or phase == 7 or phase == 9 then
        -- spawn a superball
        table.insert(self.balls, SuperBall.new(self))
    end

    if phase == 0 then
        self.music:play()
    elseif phase == 1 then
        table.insert(self.particles, HitParticle.new({x=0, y=0, w=320, h=240, color={255, 0, 0}, lifetime=0.1}))
        for i=1,5 do
            table.insert(self.balls, Ball.new(self))
        end
    elseif phase == 2 then
        table.insert(self.particles, HitParticle.new({x=0, y=0, w=320, h=240, color={255, 255, 0}, lifetime=0.1}))
        for i=1,5 do
            table.insert(self.balls, Ball.new(self, {
                r = 1.5,
                elasticity = 0.9,
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
        table.insert(self.particles, HitParticle.new({x=0, y=0, w=320, h=240, color={0, 0, 255}, lifetime=0.1}))

        local bricks = {}
        for i=1,5 do
            local xofs = 8 - (i%2) * 8
            -- TODO alternate directions per row?
            for j=1,18 + i%2 do
                table.insert(bricks, {
                    color = {math.random(127,200), math.random(200,220), math.random(200,220), 255},
                    x = j * 16 + xofs,
                    y = i * 8,
                    w = 16,
                    h = 8
                })
                table.insert(bricks, {
                    color = {math.random(127,200), math.random(200,220), math.random(200,220), 255},
                    x = 320 - j * 16 + xofs,
                    y = (12 - i) * 8,
                    w = 16,
                    h = 8
                })
            end
        end
        for j = 1,10 do
            local i = 6
            local xofs = 0
            table.insert(bricks, {
                color = {math.random(127,200), math.random(200,220), math.random(200,220), 255},
                x = j * 16 + xofs,
                y = i * 8,
                w = 16,
                h = 8
            })
            if j < 10 then
                table.insert(bricks, {
                    color = {math.random(127,200), math.random(200,220), math.random(200,220), 255},
                    x = 320 - j * 16 + xofs,
                    y = (12 - i) * 8,
                    w = 16,
                    h = 8
                })
            end
        end
        self.spawner:spawn({self.actors, self.toKill}, Brick, bricks, 60/BPM/16, 1, 0)
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
        love.graphics.clear(0, 0, 0)

        love.graphics.print("phase=" .. self.phase .. " score=" .. self.score, 0, 0)

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
    end)

    return self.canvas
end

return Game
