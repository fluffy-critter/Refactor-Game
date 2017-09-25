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
    local y = 8
    for n,item in ipairs(self.choices) do
        if item.font then
            font = item.font
            love.graphics.setFont(font)
        end

        if n == self.pos then
            love.graphics.setColor(255,255,255,255)
            if item.onSelect then
                love.graphics.print(">", 8, y)
            end
        else
            love.graphics.setColor(200,200,200,255)
        end
        if item.label then
            love.graphics.print(item.label, 24, y)
        end

        y = y + font:getHeight()
    end
end

function Menu:onButtonPress(button)
    local scanDir

    if button == 'up' and self.pos > 1 then
        scanDir = -1
    elseif button == 'down' and self.pos < #self.choices then
        scanDir = 1
    elseif button == 'a' or button == 'start' then
        self.choices[self.pos].onSelect()
    elseif button == 'back' or button == 'b' then
        if self.onBack then
            self:onBack()
        end
    elseif self.choices[self.pos] and self.choices[self.pos].onButtonPress then
        self.choices[self.pos]:onButtonPress(button)
    end

    local function active(choice)
        return choice and (choice.onSelect or choice.onButtonpress)
    end

    if scanDir then
        local lastPos = self.pos

        self.pos = self.pos + scanDir
        while self.pos > 1 and self.pos < #self.choices and not active(self.choices[self.pos]) do
            self.pos = self.pos + scanDir
        end

        if not active(self.choices[self.pos]) then
            self.pos = lastPos
        end
    end
end

return Menu
