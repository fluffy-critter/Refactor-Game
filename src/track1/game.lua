--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local Game = {}

local function load()
    print("1.load")
    Game = {}
    Game.music = love.audio.newSource('Refactor/01 little bouncing ball.mp3')

    Game.canvas = love.graphics.newCanvas(320, 240)

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
    }
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
end

-- Given a paddle object, return the up-vector for its tilt
local function get_tilt_vector(paddle)
    local x = paddle.vx * paddle.tilt_factor
    local y = -60
    local d = math.sqrt(x * x + y * y)
    return { x = x / d, y = y / d }
end

local function draw()
    Game.canvas:renderTo(function()
        love.graphics.clear(0,0,0)

        -- draw the paddle
        love.graphics.setColor(255, 255, 255)

        -- up vector = vx*tilt,1 normalized
        local up = get_tilt_vector(Game.paddle)
        local rt = { x = -up.y, y = up.x }

        local pos = { x = Game.paddle.x, y = Game.paddle.y }
        local sz = { w = Game.paddle.w, h = Game.paddle.h }

        love.graphics.polygon("fill",
            pos.x + up.x*sz.h + rt.x*sz.w, pos.y + up.y*sz.h + rt.y*sz.w,
            pos.x + up.x*sz.h - rt.x*sz.w, pos.y + up.y*sz.h - rt.y*sz.w,
            pos.x - up.x*sz.h - rt.x*sz.w, pos.y - up.y*sz.h - rt.y*sz.w,
            pos.x - up.x*sz.h + rt.x*sz.w, pos.y - up.y*sz.h + rt.y*sz.w
            )
    end)
    return Game.canvas
end

return {
    load=load,
    update=update,
    draw=draw
}
