--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local util = require('util')
local imagepool = require('imagepool')
local fonts = require('track2.fonts')
local input = require('input')

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
        charTime = 1/30, -- time to print a character
        pauseTime = 1/4, -- time to wait on a pause (%)
        minDisplayTime = 0.25, -- Minimum time in seconds for text to display before dismissal
        closeTime = 0.1,
        selectBlinkTime = 0.1, -- how long the select blinks after a movement

        charsPrinted = 0, -- number of characters printed

        printSound = nil, -- Sound to play when a character prints
        doneSound = nil,  -- Sound to play when text finishes naturally
    })

    self:setState(TextBox.states.opening)
    self.nextChar = 0 -- time remaining until the next character prints
end

function TextBox:setState(state)
    self.state = state
    self.stateAge = 0
    self.selectAge = 0
end

function TextBox:onButtonPress(key)
    if self.state >= self.states.closing then
        return false
    end

    if input.isButton(key) then
        if self.state < TextBox.states.ready and not self.cantInterrupt then
            self:setState(TextBox.states.ready)
            self.interrupted = true
            if self.onInterrupt then
                self:onInterrupt()
            end
        elseif self.state == TextBox.states.ready and self.stateAge >= self.minDisplayTime then
            if self.choices then
                self.selected = self.index
                local choice = self.choices[self.index]
                if choice and choice.onSelect then
                    choice:onSelect()
                end
            end
            self:close()
        end

        return true
    end

    if self.choices and (key == 'up' or key == 'down') then
        local play
        if key == 'up' and self.index > 1 then
            self.index = self.index - 1
            play = true
        elseif key == 'down' and self.index < #self.choices then
            self.index = self.index + 1
            play = true
        end

        if play and self.selectSound then
            self.selectSound:stop()
            self.selectSound:rewind()
            self.selectSound:play()
        end

        self.selectAge = 0
        return true
    end

    return false
end

function TextBox:getWrappedText(text, padRight)
    local width, wrapped = self.font:getWrap(text, (self.right - self.left - 1)*8 - (padRight or 0))
    return width, wrapped
end

function TextBox:update(dt)
    self.stateAge = self.stateAge + dt
    self.selectAge = self.selectAge + dt

    -- TODO just do this when self.text changes
    self.wrapped = nil
    if self.text and (self.state == TextBox.states.writing or self.state == TextBox.states.ready) then
        local _, wrapped = self:getWrappedText(self.text)
        self.wrapped = table.concat(wrapped, '\n')
    end

    if self.state == TextBox.states.opening and self.stateAge > self.openTime then
        if self.text then
            self:setState(TextBox.states.writing)
        else
            self:setState(TextBox.states.ready)
        end
    elseif self.state == TextBox.states.writing then
        if not self.wrapped or self.charsPrinted >= self.wrapped:len() then
            self:setState(TextBox.states.ready)

            if self.onReady then
                self:onReady()
            end

            if self.doneSound then
                self.doneSound:stop()
                self.doneSound:rewind()
                self.doneSound:play()
            end
        else
            self.nextChar = self.nextChar - dt
            while self.nextChar <= 0 and self.charsPrinted < self.wrapped:len() do
                self.charsPrinted = self.charsPrinted + 1
                local nc = self.wrapped:sub(1, self.charsPrinted):sub(-1)
                -- print(self.state, self.charsPrinted, nc)
                if nc == '%' then
                    self.nextChar = self.pauseTime
                elseif nc == ' ' then
                    self.nextChar = 0
                else
                    self.nextChar = self.charTime
                    if self.printSound then
                        self.printSound:stop()
                        self.printSound:rewind()
                        self.printSound:play()
                    end
                end
            end
        end
    elseif self.state == TextBox.states.ready then
        self.charsPrinted = self.wrapped and self.wrapped:len()
        self.selectAge = self.selectAge + dt
    elseif self.state == TextBox.states.closing and self.stateAge > self.closeTime then
        self:setState(TextBox.states.closed)
        if self.onClose then
            self:onClose()
        end
    end
end

function TextBox:close()
    if self.state < TextBox.states.closing then
        self:setState(TextBox.states.closing)
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

    love.graphics.setColor(255, 255, 255)

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

    if self.wrapped and (self.state == TextBox.states.writing or self.state == TextBox.states.ready) then
        love.graphics.print(self.wrapped:sub(1, self.charsPrinted), left + 8, top + 8)

        if self.state == TextBox.states.ready and self.stateAge >= self.minDisplayTime then
            love.graphics.print(">", right - 8, bottom - 4)
        end
    end

    if self.choices and self.state == TextBox.states.ready then
        local y = top + 8
        local yinc = self.font:getLineHeight() * self.font:getHeight()
        for n,choice in ipairs(self.choices) do
            love.graphics.print(choice.text, left + 16, y)
            if n == self.index and self.selectAge > self.selectBlinkTime then
                love.graphics.print(">", left + 8, y)
            end
            y = y + yinc
        end
    end
end

return TextBox
