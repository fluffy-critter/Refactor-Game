--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local Game = {}

local function load()
    print("1.load")
    Game = {}
    Game.music = love.audio.newSource('Refactor/01 little bouncing ball.mp3')
    Game.canvas = love.graphics.newCanvas(640, 480)

    Game.music:play()
end

local function update(dt)
end

local function draw()
    Game.canvas:renderTo(function()
        love.graphics.clear(127,0,0)

    end)
    return Game.canvas
end

return {
    load=load,
    update=update,
    draw=draw
}
