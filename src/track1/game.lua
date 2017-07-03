--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local StarterBall = require('track1.StarterBall')
local geom = require('geom')

local Game = {}

function Game.new()
    local o = {}
    setmetatable(o, {__index=Game})

    o:init()
    return o
end

function Game:init()
    print("1.load")
    self.music = love.audio.newSource('Refactor/01 little bouncing ball.mp3')

    self.canvas = love.graphics.newCanvas(320, 240)
    self.canvas:setFilter("nearest", "nearest")

    self.board = {
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

    self.balls = {}
    table.insert(self.balls, StarterBall.new(self))
end

function Game:setPhase(phase)
    print("setting phase to " .. phase)
    if phase == 0 then
        self.music:play()
        self.musicPos = 0
    end

    self.phase = phase
end

function Game:update(dt)
    local p = self.paddle
    local b = self.board

    if self.music:isPlaying() then
        self.musicPos = self.musicPos + self.music:getPitch() * dt

        local phase = math.floor(self.musicPos/30)
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
        local remove

        if ball:update(dt) == false then
            remove = true
        end

        -- check for collision with the paddle
        local c = geom.pointPolyCollision(ball.x, ball.y, ball.r, paddlePoly)
        if c then
            if ball:onPaddle(c) == false then
                remove = true
            end
        end

        if not remove then
            table.insert(nextBalls, ball)
        end
    end
    self.balls = nextBalls
end

local function update(dt)
    Game:update(dt)
end

function Game:draw()
    self.canvas:renderTo(function()
        love.graphics.clear(0, 0, 0)

        -- draw the paddle
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.polygon("fill", self.paddle:getPolygon())

        -- draw the balls
        for k,ball in pairs(self.balls) do
            love.graphics.setColor(unpack(ball.color))
            love.graphics.circle("fill", ball.x, ball.y, ball.r)
        end
    end)
    return self.canvas
end

local function draw()
    Game:draw()
end

return Game
