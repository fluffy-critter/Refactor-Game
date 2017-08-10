--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local util = require('util')
local imagepool = require('imagepool')
local fonts = require('fonts')

local TextBox = {
    states = util.enum("opening", "writing", "ready", "closing", "closed")
}

local defaultQuads = {}
for row = 0, 2 do
    for col = 0, 2 do
        table.insert(defaultQuads, love.graphics.newQuad(col*8, row*8, 8, 8, 24, 24))
    end
end

function TextBox.new(o)
    local self = o or {}
    setmetatable(self, {__index = TextBox})

    self:onInit()

    return self
end

function TextBox:onInit()
    local imgFile = self.text and "track2/textbox-blue.png" or "track2/textbox-red.png"
    local font = self.text and fonts.returnOfGanon.red or fonts.returnOfGanon.blue

    util.applyDefaults(self, {
        image = imagepool.load(imgFile),
        quads = defaultQuads,
        font = font,

        -- position is in 8x8 character cells, NOT in pixels
        left = 1,
        top = 19,
        right = 30,
        bottom = 27,

        index = 1,

        openTime = 0.25, -- time to open (in seconds)
        printSpeed = 100, -- characters/second
        closeTime = 0.1,
        selectBlinkTime = 0.1, -- how long the select blinks after a movement
    })

    self.state = TextBox.states.opening
    self.stateAge = 0
end

function TextBox:onButtonPress(key)
    if self.state >= self.states.closing then
        return false
    end

    if key == 'a' then
        if self.state < TextBox.states.ready then
            self.state = TextBox.states.ready
            self.stateAge = 0
        elseif self.state == TextBox.states.ready then
            if self.choices then
                self.selected = self.index
                self.choices[self.index].action()
            end
            self:close()
        end

        return true
    end

    if self.choices and (key == 'up' or key == 'down') then
        if key == 'up' and self.index > 1 then
            self.index = self.index - 1
        elseif key == 'down' and self.index < #self.choices then
            self.index = self.index + 1
        end
        self.stateAge = 0
        return true
    end

    return false
end

function TextBox:update(dt)
    self.stateAge = self.stateAge + dt

    if self.state == TextBox.states.opening and self.stateAge > self.openTime then
        self.state = TextBox.states.writing
        self.stateAge = 0
    elseif self.state == TextBox.states.writing and (not self.text or self.stateAge > string.len(self.text)/self.printSpeed )then
        self.state = TextBox.states.ready
        if self.onReady then
            self:onReady()
        end
    elseif self.state == TextBox.states.closing and self.stateAge > self.closeTime then
        self.state = TextBox.states.closed
        if self.onClose then
            self:onClose()
        end
    end
end

function TextBox:close()
    if self.state < TextBox.states.closing then
        self.state = TextBox.states.closing
        self.stateAge = 0
    end
end

function TextBox:isAlive()
    return self.state < TextBox.states.closed
end

function TextBox:draw()
    if self.state == TextBox.states.closed then
        return
    end

    -- number of interior rows
    local rows = self.bottom - self.top - 2

    if self.state == TextBox.states.opening then
        rows = math.floor(rows*self.stateAge/self.openTime)
    elseif self.state == TextBox.states.closing then
        rows = math.floor(rows*(1 - self.stateAge/self.closeTime))
    end

    local top = self.top*8
    local left = self.left*8
    local right = self.right*8
    local bottom = top + (rows + 1)*8

    -- draw top row
    love.graphics.draw(self.image, self.quads[1], left, top)
    for x = left + 8, right - 8, 8 do
        love.graphics.draw(self.image, self.quads[2], x, top)
    end
    love.graphics.draw(self.image, self.quads[3], right, top)

    -- draw intermediate rows
    for y = top + 8, bottom - 8, 8 do
        love.graphics.draw(self.image, self.quads[4], left, y)
        for x = left + 8, right - 8, 8 do
            love.graphics.draw(self.image, self.quads[5], x, y)
        end
        love.graphics.draw(self.image, self.quads[6], right, y)
    end

    -- draw bottom row
    love.graphics.draw(self.image, self.quads[7], left, bottom)
    for x = left + 8, right - 8, 8 do
        love.graphics.draw(self.image, self.quads[8], x, bottom)
    end
    love.graphics.draw(self.image, self.quads[9], right, bottom)

    -- draw text (TODO support coloredText?)
    love.graphics.setFont(self.font)
    love.graphics.setColor(255, 255, 255)

    if self.text and (self.state == TextBox.states.writing or self.state == TextBox.states.ready) then
        local width, wrapped = self.font:getWrap(self.text, right - left - 8)
        local text
        local length
        if self.state == TextBox.states.writing then
            length = self.stateAge*self.printSpeed
        end

        for k,line in ipairs(wrapped) do
            if length and length <= 0 then
                break
            end

            if text then
                text = text .. '\n'
            end

            local chunk = string.sub(line, 1, length)
            length = length and (length - #chunk)
            text = (text or '') .. chunk
        end

        love.graphics.print(text or '', left + 8, top + 8)
    end

    if self.choices and self.state == TextBox.states.ready then
        local y = top + 8
        local yinc = self.font:getLineHeight() * self.font:getHeight()
        for n,choice in ipairs(self.choices) do
            love.graphics.print(choice.text, left + 16, y)
            if n == self.index and self.stateAge > self.selectBlinkTime then
                love.graphics.print(">", left + 8, y)
            end
            y = y + yinc
        end
    end
end

return TextBox
