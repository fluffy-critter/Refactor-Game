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

local dialog = require('track2.dialog')
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
local clock = util.clock(BPM, {4, 4}, 0.25)

-- returns music position as {phase, measure, beat}. beat will be fractional.
function Game:musicPos()
    return clock.timeToPos(self.music:tell())
end

-- seeks the music to a particular spot, using the same format as musicPos(), with an additional timeOfs param that adjusts it by seconds
function Game:seekMusic(pos, timeOfs)
    self.music:seek(clock.posToTime(pos) + (timeOfs or 0))
end

function Game:init()
    self.BPM = BPM

    self.music = love.audio.newSource('music/02-strangers.mp3')
    self.phase = -1
    self.score = 0
    self.music:play()

    self.canvas = love.graphics.newCanvas(256, 224)
    self.canvas:setFilter("nearest")

    self.outputScale = 3
    self.scaled = love.graphics.newCanvas(256*self.outputScale, 224*self.outputScale)

    self.border =imagepool.load('track2/border.png')
    self.background = imagepool.load('track2/kitchen.png')

    self.lyrics = require('track2.lyrics')
    self.lyricPos = 1
    self.nextLyric = self.lyrics[self.lyricPos]

    self.dialogCounts = {} -- sideband data for how many times each dialog has been seen
    self.nextDialog = {1} -- when to show the next dialog box
    self.nextTimeout = nil -- when the next dialog timeout is to occur
    self.dialogState = dialog.start_state

    -- the state of the NPC
    self.npc = {}
end

function Game:onButtonPress(button, code, isRepeat)
    if button == 'skip' then
        print("tryin' ta skip")
        self:seekMusic({self.phase + 1})
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

        if self.phase == 0 then
            -- text format testing
            -- self.textBox = TextBox.new({text="test text, please remove me"})
            -- self.textBox = TextBox.new({choices={{text="arghl"}}})
        end
    end

    -- TODO don't make new text selections after {12,3}
    if not self.textBox and self.nextDialog and not util.arrayLT(time, self.nextDialog) then
        print("advancing dialog")
        self.nextDialog = nil

        local node = self:chooseDialog()
        if node then
            self.textBox = TextBox.new({text = node.text})

            local game = self
            self.textBox.onClose = function(textBox)
                game:textFinished(textBox, node)
            end

            self.nextTimeout = self:getNextTimeout()
        else
            self.nextTimeout = nil
            if self.textBox then
                self.textBox:close()
            end
        end
    end

    if self.nextTimeout and not util.arrayLT(time, self.nextTimeout) then
        self.nextTimeout = nil
        if self.textBox then
            self.textBox:close()
        end
    end

    if self.textBox then
        self.textBox:update(dt)
        if not self.textBox:isAlive() then
            self.textBox = nil
        end
    end

    if util.arrayLT({17,1,0}, time) then
        self.gameOver = true
    end
end

-- Get the next timeout for a textbox
function Game:getNextTimeout()
    local now = self:musicPos()
    local nextTime = clock.posToTime({now[1], now[2] + 2, 0})
    return clock.timeToPos(nextTime)
end

-- Called when the NPC textbox finishes
function Game:textFinished(textBox, node)
    if textBox.interrupted then
        print("moo")
        self.npc.interrupted = (self.npc.interrupted or 0) + 1
    end

    if node.setState then
        print("new state = " .. node.setState)
        self.dialogState = node.setState
    end

    if node.responses then
        -- We have responses for this fragment...
        local choices = {}

        local silence = {}
        local onClose = function(textBox)
            if not textBox.selected then
                print("selection timed out")
                self.npc.silence_cur = (self.npc.silence_cur or 0) + 1
                self.npc.silence_total = (self.npc.silence_total or 0) + 1
                self:onChoice(silence)
            else
                self.npc.silence_cur = 0
            end
        end

        for _,response in ipairs(node.responses) do
            if response[1] then
                table.insert(choices, {
                    text = response[1],
                    onSelect = function(choice)
                        self:onChoice(response)
                    end
                })
            else
                -- no text means this is the timeout option
                silence = response
            end
        end

        print("choices: " .. #choices)

        self.textBox = TextBox.new({choices = choices, onClose = onClose})
        self.nextTimeout = self:getNextTimeout()
    else
        self.nextDialog = {} -- TODO handle animations
    end
end

-- Called when the player makes a dialog choice (including timeout)
function Game:onChoice(response)
    if response[2] then
        for k,v in pairs(response[2]) do
            self.npc[k] = (self.npc[k] or 0) + v
            print(k .. " now " .. self.npc[k])
        end
    end
    if response[3] then
        self.dialogState = response[3]
        print("state now " .. self.dialogState)
    end

    self.nextDialog = {} -- TODO handle animations
end

-- Get the next conversation node from the dialog tree
function Game:chooseDialog()
    local minDistance, minNode

    local now = self:musicPos()
    self.npc.phase = now[1] + now[2]/4 + now[3]/16

    for _,node in ipairs(dialog[self.dialogState]) do
        if not self.dialogCounts[node] or self.dialogCounts[node] < (node.max_count or 1) then
            print("Considering: " .. node.text)
            local distance = 0
            for k,v in pairs(node.pos or {}) do
                local dx = v - (self.npc[k] or 0)
                distance = distance + dx*dx
            end
            print("   distance=" .. distance)
            if not minDistance or distance < minDistance then
                minNode = node
                minDistance = distance
            end
        end
    end

    if minNode then
        print("Chose: " .. minNode.text)
        self.dialogCounts[minNode] = (self.dialogCounts[minNode] or 0) + 1
    end

    return minNode
end

function Game:draw()
    self.canvas:renderTo(function()
        love.graphics.clear(0, 0, 0, 255)

        love.graphics.setBlendMode("alpha")

        -- TODO draw scene
        if self.phase < 17 then
            love.graphics.setColor(255, 255, 255)
            love.graphics.draw(self.background, 0, 0)

            love.graphics.draw(self.border)
        end

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

        love.graphics.setFont(fonts.debug)
        love.graphics.setColor(255,255,0)
        love.graphics.print(string.format("%d:%d:%.2f", unpack(self:musicPos())))
    end)

    self.scaled:renderTo(function()
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setColor(255, 255, 255)
        love.graphics.setShader(shaders.crtScaler)
        shaders.crtScaler:send("screenSize", {256, 224})
        love.graphics.draw(self.canvas, 0, 0, 0, self.outputScale, self.outputScale)
        love.graphics.setShader()
    end)
    return self.scaled, 4/3

end

return Game
