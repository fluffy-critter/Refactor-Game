--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local geom = require('geom')
local util = require('util')
local shaders = require('shaders')
local input = require('input')
local imagepool = require('imagepool')
local fonts = require('fonts')

local TextBox = require('track2.TextBox')

local Game = {
    META = {
        title = "strangers",
        duration = 3*60 + 11
    }
}

function Game.new()
    local o = {}
    setmetatable(o, {__index=Game})

    o:init()
    return o
end

local BPM = 90

-- returns music position as {phase, measure, beat}. beat will be fractional.
function Game:musicPos()
    local beat = self.music:tell()*BPM/60

    local measure = math.floor(beat/4)
    beat = beat - measure*4

    local phase = math.floor(measure/4)
    measure = measure - phase*4

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
    self.BPM = BPM

    self.music = love.audio.newSource('music/02-strangers.mp3')
    self.phase = -1
    self.score = 0
    self.music:play()

    self.canvas = love.graphics.newCanvas(256, 224)
    self.canvas:setFilter("nearest")

    self.background = imagepool.load("track2/kitchen.png")
end

function Game:update(dt)
    local time = self:musicPos()

    if time[1] > self.phase then
        print("phase = " .. self.phase)
        self.phase = time[1]
        self.textBox = TextBox.new({
            font = fonts.returnOfGanon.red,
        })
    end
    if self.textBox then
        self.textBox.text = "Music just got to phase:\n" .. self.phase .. "\n" .. string.format("%d:%d:%.2f", unpack(time))
    end

    if self.textBox and time[2] >= 3 and time[3] >= 3 then
        self.textBox:close()
    end

    if self.textBox then
        self.textBox:update(dt)
    end
end

function Game:draw()
    self.canvas:renderTo(function()
        love.graphics.setBlendMode("alpha")

        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(self.background, 0, 0)

        if self.textBox then
            self.textBox:draw()
        end
    end)

    return self.canvas, 1
end

return Game
