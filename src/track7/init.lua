--[[
Refactor: 7 - flight

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
]]

local util = require('util')

local Game = {
    META = {
        tracknum = 7,
        title = "flight",
        duration = 2*60 + 20,
        description = "falling monk",
    }
}

function Game.new()
    local o = {}
    setmetatable(o, {__index=Game})

    o:init()
    return o
end

local BPM = 120
local clock = util.clock(BPM, {4})

-- returns music position as {measure, beat}. beat will be fractional.
function Game:musicPos()
    return clock.timeToPos(self.music:tell())
end

function Game:seekMusic(pos, timeOfs)
    self.music:seek(clock.posToTime(pos) + (timeOfs or 0))
end

function Game:resize(w, h)
    self.screen = {w = w, h = h}

    if not self.canvas or self.canvas:getWidth() ~= w or self.canvas:getHeight() ~= h then
        self.canvas = love.graphics.newCanvas(w, h)
    end
end

function Game:init()
    self.BPM = BPM

    self:resize(love.graphics.getWidth(), love.graphics.getHeight())

    self.monk = {
        x = 0,
        y = 0,
        t = 0,
        vx = 0,
        vy = 0
    }

    self.music = love.audio.newSource('track7/07-flight.mp3')
end

function Game:start()
    self.music:play()
end

function Game:update(dt)
    print(dt)
end

function Game:draw()
    self.canvas:renderTo(function()
        love.graphics.clear(0,0,0,255)

        love.graphics.push()

        local scale = math.min(self.screen.w/1280, self.screen.h/720)
        love.graphics.translate((self.screen.w - 1280*scale)/2, (self.screen.h - 720*scale)/2)
        love.graphics.scale(scale, scale)

        love.graphics.setColor(255,255,255)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)

        love.graphics.pop()
    end)
    return self.canvas
end

return Game
