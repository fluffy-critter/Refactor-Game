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
local shaders = require('shaders')

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
    local beat = (self.music:tell() - 0.25)*BPM/60

    local measure = math.floor(beat/4)
    beat = beat - measure*4

    local phase = math.floor(measure/4)
    measure = measure - phase*4

    return {phase, measure, beat}
end

-- seeks the music to a particular spot, using the same format as musicPos(), with an additional timeOfs param that adjusts it by seconds
function Game:seekMusic(phase, measure, beat, timeOfs)
    local time = (phase or 0)
    time = time*4 + (measure or 0)
    time = time*4 + (beat or 0)
    time = time*60/BPM + (timeOfs or 0)
    self.music:seek(time + 0.25)
end

function Game:init()
    self.BPM = BPM

    self.music = love.audio.newSource('music/02-strangers.mp3')
    self.phase = -1
    self.score = 0
    self.music:play()

    self.canvas = love.graphics.newCanvas(256, 224)
    self.canvas:setFilter("nearest")

    self.scaled = love.graphics.newCanvas(256*3, 224*3)

    self.background = imagepool.load('track2/kitchen.png')

    self.lyrics = require('track2.lyrics')
    self.lyricPos = 1
    self.nextLyric = self.lyrics[self.lyricPos]
end

function Game:onButtonPress(button, code, isRepeat)
    if button == 'skip' then
        print("tryin' ta skip")
        self:seekMusic(self.phase + 1)
        return true
    end

    if self.textBox then
        return self.textBox:onButtonPress(button, code, isRepeat)
    end
end

function Game:update(dt)
    local time = self:musicPos()

    if self.nextLyric and util.arrayLT(self.nextLyric[1], time) then
        self.lyricText = self.nextLyric[2]
        self.lyricPos = self.lyricPos + 1
        self.nextLyric = self.lyrics[self.lyricPos]
    end

    if time[1] > self.phase then
        print("phase = " .. self.phase)
        self.phase = time[1]
        if self.phase % 2 == 1 then
            self.textBox = TextBox.new({text="foo"})
        else
            self.textBox = TextBox.new({
                choices={
                    {
                        text="hello",
                        action=function()
                            print("mew")
                        end
                    },
                    {
                        text="goodbye",
                        action=function()
                            print("woof")
                        end
                    },
                    {
                        text="wtf",
                        action=function()
                            print("moo")
                        end
                    },
                },
                onClose = function(self)
                    if not self.selected then
                        print("dialog choice timed out")
                    end
                end
            })
        end
    end
    if self.textBox and self.textBox.text then
        self.textBox.text = "Music just got to phase:\n" .. self.phase .. "\n" .. string.format("%d:%d:%.2f", unpack(time))
    end

    if self.textBox and time[2] >= 3 and time[3] >= 3 then
        self.textBox:close()
    end

    if self.textBox then
        self.textBox:update(dt)
        if not self.textBox:isAlive() then
            self.textBox = nil
        end
    end

    if util.arrayLT({17,2,0}, time) then
        self.gameOver = true
    end
end

function Game:draw()
    self.canvas:renderTo(function()
        love.graphics.clear(0, 0, 0, 255)

        love.graphics.setBlendMode("alpha")

        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(self.background, 0, 0)

        if self.textBox then
            self.textBox:draw()
        end

        if self.lyricText then
            local font = fonts.chronoTrigger
            local width, wrapped = font:getWrap(self.lyricText, 256)

            love.graphics.setColor(0, 0, 0, 127)
            love.graphics.rectangle("fill", 256 - width - 4, 0, width + 4, 14)

            love.graphics.setFont(font)
            love.graphics.setColor(255, 255, 255)
            love.graphics.print(self.lyricText, 256 - width - 1, 0)
        end
    end)

    self.scaled:renderTo(function()
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setColor(255, 255, 255)
        -- love.graphics.setShader(shaders.crtScaler)
        shaders.crtScaler:send("screenSize", {256, 224})
        love.graphics.draw(self.canvas, 0, 0, 0, 3, 3)
        love.graphics.setShader()
    end)
    return self.scaled, 4/3

end

return Game
