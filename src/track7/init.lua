--[[
Refactor: 7 - flight

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
]]

local util = require('util')
local gfx = require('gfx')
local heap = require('thirdparty.binary_heap')

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

-- returns music position in terms of MIDI clocks
function Game:musicPos()
    return self.music:tell()*960
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
    self:resize(love.graphics.getWidth(), love.graphics.getHeight())

    self.monk = {
        x = 0,
        y = 0,
        t = 0,
        vx = 0,
        vy = 0
    }

    self.music = love.audio.newSource('track7/07-flight.mp3')

    local eventlist = love.filesystem.load('track7/events.lua')()
    self.events = heap:new()
    for _,data in ipairs(eventlist) do
        self.events:insert(data[1], {
            track = data[2],
            note = data[3],
            velocity = data[4]
        })
    end

    self.actors = {}
end

function Game:start()
    self.music:play()
end

function Game:update(dt)
    local now = self:musicPos()
    while not self.events:empty() and self.events:next_key() <= now do
        local _,event = self.events:pop()
        print(event.track, event.note, event.velocity)
    end

    util.runQueue(self.actors, function(actor)
        return actor:update(dt)
    end)
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
        local tx = ww/2
        local ty = hh - 540*scale
        love.graphics.translate(tx, ty)
        love.graphics.scale(scale)

        -- compute the extents of the playfield, given that x*scale + tx = ox, i.e. x = (ox - tx)/scale
        local minX = (0 - tx)/scale
        local maxX = (ww - tx)/scale
        local minY = (0 - ty)/scale
        local maxY = (hh - ty)/scale
        love.graphics.print("0,0", 0, 0)
        love.graphics.print("0," .. minY, 0, minY)

        love.graphics.setColor(255,255,255)
        love.graphics.circle("line", -100, 0, 100)
        love.graphics.circle("line", 0, 0, 100)
        love.graphics.circle("line", 100, 0, 100)

        love.graphics.rectangle("line", -1920/2, -1080/2, 1920, 1080)

        for _,actor in pairs(self.actors) do
            actor:draw()
        end

        love.graphics.pop()
    end)
    return self.canvas
end

return Game
