--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local util = require('util')
local imagepool = require('imagepool')

local TextBox = {
    states = util.enum("opening", "writing", "steady", "closing", "closed")
}

local default9Slice = imagepool.load('track2/textbox-blue.png')
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
    util.applyDefaults(self, {
        image = default9Slice,
        quads = defaultQuads,

        -- position is in 8x8 character cells, NOT in pixels
        left = 1,
        top = 18,
        right = 30,
        bottom = 27,

        openTime = 0.25, -- time to open (in seconds)
        printSpeed = 100, -- characters/second
        closeTime = 0.1
    })

    self.state = TextBox.states.opening
    self.stateAge = 0
end

function TextBox:onButtonPress(key)
    if key ~= 'a' then
        return false
    end

    if self.state < TextBox.states.steady then
        self.state = TextBox.states.steady
        self.stateAge = 0
    else
        self:close()
    end

    return true
end

function TextBox:update(dt)
    self.stateAge = self.stateAge + dt

    if self.state == TextBox.states.opening and self.stateAge > self.openTime then
        self.state = TextBox.states.writing
        self.stateAge = 0
    elseif self.state == TextBox.states.writing and self.stateAge > string.len(self.text)/self.printSpeed then
        self.state = TextBox.states.steady
    elseif self.state == TextBox.states.closing and self.stateAge > self.closeTime then
        self.state = TextBox.states.closed
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

    -- draw text (TODO support coloredText)
    local text
    if self.state == TextBox.states.writing then
        text = string.sub(self.text, 1, self.stateAge*self.printSpeed)
    elseif self.state == TextBox.states.steady then
        text = self.text
    end

    if text then
        love.graphics.setFont(self.font)
        love.graphics.setColor(255, 255, 255)
        love.graphics.print(text, left + 8, top + 8)
    end

end

return TextBox
