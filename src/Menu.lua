--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Menu.lua - a simple menu system

Properties:
    choices - a sequence of {label="text string", onSelect=function}
    onBack - what to do if the back button is pressed

]]

local util = require('util')
local fonts = require('fonts')

local Menu = {}

function Menu.new(o)
    local self = o or {}
    setmetatable(self, {__index=Menu})

    util.applyDefaults(self, {
        pos = 1
    })

    return self
end

function Menu:draw()
    local font = fonts.bodoni72.regular
    love.graphics.setBlendMode("alpha")
    love.graphics.setFont(font)
    love.graphics.setColor(255,255,255,255)
    local y = 0
    for n,item in ipairs(self.choices) do
        if n == self.pos then
            love.graphics.setColor(255,255,255,255)
            if item.onSelect then
                love.graphics.print(">", 8, y + 8)
            end
        else
            love.graphics.setColor(200,200,200,255)
        end
        love.graphics.print(item.label, 24, y + 8)

        y = y + font:getHeight()
    end
end

function Menu:onButtonPress(button)
    if button == 'up' and self.pos > 1 then
        -- TODO play sound
        self.pos = self.pos - 1
        while self.pos > 1 and not self.choices[self.pos].onSelect do
            self.pos = self.pos - 1
        end
    elseif button == 'down' and self.pos < #self.choices then
        -- TODO play sound
        self.pos = self.pos + 1
        while self.pos < #self.choices and not self.choices[self.pos].onSelect do
            self.pos = self.pos + 1
        end
    elseif button == 'a' or button == 'start' then
        self.choices[self.pos].onSelect()
    elseif button == 'back' or button == 'b' then
        if self.onBack then
            self:onBack()
        end
    end
end

return Menu
