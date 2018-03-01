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
        pos = 1,
    })

    return self
end

function Menu:measure()
    local w, h = 0, 0
    local font = self.font or fonts.menu.regular

    for _,item in ipairs(self.choices) do
        local fontSize = font:getHeight()
        local lw = font:getWrap(item.label or "", 65535) + fontSize*3/4 + 8
        w = math.max(w, lw)
        h = h + fontSize
    end

    return w, h
end

function Menu:draw()
    local w, h = self:measure()
    if not self.canvas or self.canvas:getWidth() < w or self.canvas:getHeight() < h then
        self.canvas = love.graphics.newCanvas(w, h)
    end

    -- TODO scrolling

    local tooltip
    self.canvas:renderTo(function()
        love.graphics.clear(0,0,0,0)
        love.graphics.setBlendMode("alpha")

        local y = 0
        for n,item in ipairs(self.choices) do
            local font = item.font or self.font or fonts.menu.regular
            love.graphics.setFont(font)
            local fontSize = font:getHeight()

            if n == self.pos then
                love.graphics.setColor(255,255,255,255)
                if item.onSelect then
                    love.graphics.print(">", 0, y)
                end
                tooltip = item.tooltip
            elseif item.onSelect then
                love.graphics.setColor(200,200,200,255)
            else
                love.graphics.setColor(192,192,192,127)
            end
            if item.label then
                love.graphics.print(item.label, fontSize*3/4, y)
            end

            y = y + fontSize
        end
    end)

    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(0,0,0,512)
    -- TODO maybe use gaussBlur or something? I dunno
    for x=6,10 do
        for y=6,10 do
            love.graphics.draw(self.canvas, x, y)
        end
    end
    love.graphics.setColor(255,255,255,255)
    love.graphics.draw(self.canvas, 8, 8)

    if tooltip then
        love.graphics.setBlendMode("alpha")
        local font = self.tooltipFont or fonts.menu.tooltip
        local fontSize = font:getHeight()

        love.graphics.setFont(font)
        local lw = font:getWrap(tooltip, 65535) + fontSize*3/4 + 8
        local lh = fontSize + 16
        local ly = love.graphics.getHeight() - lh

        love.graphics.setColor(0,0,0,127)
        love.graphics.rectangle("fill", 0, ly, lw, lh)

        love.graphics.setColor(255,255,255,255)
        love.graphics.print(tooltip, 8 + fontSize*3/8, ly + 8)
    end

    love.graphics.setShader()
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
