--[[
Refactor: 7 - flight

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
]]

local util = require('util')
local gfx = require('gfx')

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
    self.screenSize = {w = w, h = h}
    self.scale = nil
end

function Game:setScale(scale)
    scale = math.min(scale, 1)

    -- Only adjust if we've changed by more than 5% ish
    if self.scale and scale < self.scale*1.05 and scale > self.scale*0.95 then
        return scale
    end

    local pixelfmt = gfx.selectCanvasFormat("rgba8", "rgba4", "rgb5a1")

    -- Set the canvas to the screen resolution directly
    self.scale = scale
    self.canvas = love.graphics.newCanvas(
        math.floor(scale*self.screenSize.w),
        math.floor(scale*self.screenSize.h),
        pixelfmt)

    return scale
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
    -- print(dt)
end

function Game:draw()
    self.canvas:renderTo(function()
        love.graphics.clear(0,0,0,255)

        love.graphics.push()

        local ww = self.canvas:getWidth()
        local hh = self.canvas:getHeight()

        -- make a 1920x1080 box fit on the screen
        local scale = math.min(ww/1920, hh/1080)

        -- center the coordinate system such that x=0 is the center of the screen and y=540 is the bottom edge
        -- 540*scale + ty = hh
        love.graphics.translate(ww/2, hh - 540*scale)
        love.graphics.scale(scale)

        love.graphics.setColor(255,255,255)
        love.graphics.circle("line", -100, 0, 100)
        love.graphics.circle("line", 0, 0, 100)
        love.graphics.circle("line", 100, 0, 100)

        love.graphics.rectangle("line", -1920/2, -1080/2, 1920, 1080)

        love.graphics.pop()
    end)
    return self.canvas
end

return Game
