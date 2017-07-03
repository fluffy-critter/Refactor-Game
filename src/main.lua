--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local function blitCanvas(canvas)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local canvasWidth = canvas:getWidth()
    local canvasHeight = canvas:getHeight()

    local blitSize = { screenWidth, screenWidth*canvasHeight/canvasWidth }
    if screenHeight < blitSize[2] then
        blitSize = { screenHeight*canvasWidth/canvasHeight, screenHeight }
    end

    local blitX = (love.graphics.getWidth() - blitSize[1])/2
    local blitY = (love.graphics.getHeight() - blitSize[2])/2
    love.graphics.draw(canvas, blitX, blitY, 0,
        blitSize[1]/canvasWidth, blitSize[2]/canvasHeight)
end

local tracks = {}

function love.load()
    tracks[1] = require('track1.game')

    tracks[1].load()
end

function love.update(dt)
    tracks[1].update(dt)
end

function love.draw()
    local canvas = tracks[1].draw()
    blitCanvas(canvas)
end
