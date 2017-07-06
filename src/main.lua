--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local shaders = require('shaders')

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
local currentGame

local state = "playing"
local speed = 1.0
local resumeMusic = false

local function onPause()
    if state == "playing" or state == "resuming" then
        state = "pausing"
        resumeMusic = currentGame.music:isPlaying()
    elseif state == "pausing" or state == "paused" then
        state = "resuming"
        if resumeMusic then
            currentGame.music:resume()
        end
    end
end

function love.keypressed(key, code, isrepeat)
    if key == 'p' then
        onPause()
    elseif currentGame.keypressed then
        currentGame:keypressed(key, code, isrepeat)
    end
end

function love.load()
    tracks[1] = require('track1.game')

    currentGame = tracks[1].new()
end

function love.update(dt)
    if state == "pausing" then
        speed = speed - dt*3
        if speed <= 0 then
            speed = 0
            currentGame.music:pause()
            state = "paused"
        else
            currentGame.music:setPitch(speed)
        end
    elseif state == "resuming" then
        speed = speed + dt*3
        if speed >= 1 then
            speed = 1
            state = "playing"
        end
        currentGame.music:setPitch(speed)
    end

    local mul = 1
    if love.keyboard.isDown('s') then
        mul = 0.1
    end

    if state ~= "paused" then
        currentGame:update(dt*mul)
    end
end

function love.draw()
    local canvas = currentGame:draw()

    love.graphics.setColor(255, 255, 255)

    if state ~= "playing" then
        love.graphics.setShader(shaders.hueshift)
        local saturation = speed*.75 + .25
        local shift = (1 - speed)*math.pi
        if state == "resuming" then
            shift = -shift
        end
        shaders.hueshift:send("basis", {
            saturation * math.cos(shift),
            saturation * math.sin(shift)
        })
    end
    blitCanvas(canvas)
    love.graphics.setShader()
end
