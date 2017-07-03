--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local Game = {}

local StarterBall = require 'track1.StarterBall'

local function load()
    print("1.load")
    Game = {}
    Game.music = love.audio.newSource('Refactor/01 little bouncing ball.mp3')

    Game.canvas = love.graphics.newCanvas(320, 240)
    Game.canvas:setFilter("nearest", "nearest")

    Game.board = {
        left = 8,
        right = 320 - 8,
        top = 8,
        bottom = 240
    }

    Game.paddle = {
        x = 160,
        y = 220,
        w = 20,
        h = 2,

        vx = 0,
        vy = 0,

        speed = 100,
        friction = 0.8,
        rebound = 0.5,
        tilt_factor = 0.05,

        -- get the upward vector for the paddle
        get_tilt_vector = function(self)
            local x = self.vx * self.tilt_factor
            local y = -60
            local d = math.sqrt(x * x + y * y)
            return { x = x / d, y = y / d }
        end,

        get_polygon = function(self)
            local up = self:get_tilt_vector()
            local rt = { x = -up.y, y = up.x }

            return {
                self.x + up.x*self.h + rt.x*self.w, self.y + up.y*self.h + rt.y*self.w,
                self.x + up.x*self.h - rt.x*self.w, self.y + up.y*self.h - rt.y*self.w,
                self.x - up.x*self.h - rt.x*self.w, self.y - up.y*self.h - rt.y*self.w,
                self.x - up.x*self.h + rt.x*self.w, self.y - up.y*self.h + rt.y*self.w
            }
        end
    }

    Game.phase = 0

    Game.balls = {}
    table.insert(Game.balls, StarterBall.new(Game))
end

local function update(dt)
    local p = Game.paddle
    local b = Game.board

    if love.keyboard.isDown("right") then
        p.vx = p.vx + p.speed
    end
    if love.keyboard.isDown("left") then
        p.vx = p.vx - p.speed
    end
    p.vx = p.vx * p.friction

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

    for k,ball in pairs(Game.balls) do
        ball:update(dt)
    end

end

local function draw()
    Game.canvas:renderTo(function()
        love.graphics.clear(0,0,0)

        -- draw the paddle
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.polygon("fill", Game.paddle:get_polygon())

        -- draw the balls
        for k,ball in pairs(Game.balls) do
            love.graphics.setColor(unpack(ball.color))
            love.graphics.circle("fill", ball.x, ball.y, ball.r)
        end
    end)
    return Game.canvas
end

return {
    load=load,
    update=update,
    draw=draw
}
