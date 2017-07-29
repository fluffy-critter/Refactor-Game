--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local shaders = require('shaders')
local util = require('util')
local input = require('input')

local PROFILE = false
local DEBUG = false

local Pie
if PROFILE then
    local piefiller = require('thirdparty.Piefiller.piefiller')
    Pie = piefiller:new()
    Pie:setKey("save_to_file","w")
end

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

local PlayState = util.enum("playing", "pausing", "paused", "resuming")
local playing = {
    state = PlayState.playing,
    speed = 1.0,
    resumeMusic = false
}

local ScreenState = util.enum("ready", "configwait")
local screen = {
    state = ScreenState.waiting,
    resumeMusic = false
}

local function onPause()
    if playing.state == PlayState.playing or playing.state == PlayState.resuming then
        playing.state = PlayState.pausing
        playing.resumeMusic = currentGame.music:isPlaying()
    elseif playing.state == PlayState.pausing or playing.state == PlayState.paused then
        playing.state = PlayState.resuming
        if playing.resumeMusic then
            currentGame.music:resume()
        end
    end
end

function input.onPress(button)
    if screen.state == ScreenState.configwait then
        return
    end

    if button == 'start' then
        onPause()
    elseif button == 'fullscreen' then
        screen.state = ScreenState.configwait
        if currentGame and currentGame.music:isPlaying() then
            screen.resumeMusic = true
            currentGame.music:pause()
        else
            screen.resumeMusic = false
        end
        love.window.setFullscreen(not love.window.getFullscreen())
    elseif currentGame and currentGame.onButtonPress then
        currentGame:onButtonPress(button)
    end
end

function input.onRelease(button)
    if currentGame and currentGame.onButtonRelease then
        currentGame:onButtonRelease(button)
    end
end

local chainKeypressed = love.keypressed
function love.keypressed(...)
    if Pie then Pie:keypressed(...) end
    if chainKeypressed then
        chainKeypressed(...)
    end
end

function love.mousepressed(...)
    local x, y, button, istouch = ...

    if Pie then Pie:mousepressed(...) end
end

function love.load()
    love.mouse.setVisible(false)
    love.keyboard.setKeyRepeat(true)

    tracks[1] = require('track1.game')

    currentGame = tracks[1].new()
    love.window.setTitle(currentGame.META.title)

    -- currentGame = require('tests.waterTester')
    -- currentGame:init()
end

local frameCount = 0
local frameTime = 0
local fps

function love.update(dt)
    if Pie then Pie:attach() end

    if screen.state == ScreenState.configwait then
        return
    end

    input.update(dt)

    if playing.state == PlayState.pausing then
        playing.speed = playing.speed - dt*3
        if playing.speed <= 0 then
            playing.speed = 0
            currentGame.music:pause()
            playing.state = PlayState.paused
        else
            currentGame.music:setPitch(playing.speed)
        end
    elseif playing.state == PlayState.resuming then
        playing.speed = playing.speed + dt*3
        if playing.speed >= 1 then
            playing.speed = 1
            playing.state = PlayState.playing
        end
        currentGame.music:setPitch(playing.speed)
    end

    local mul = 1
    if love.keyboard.isDown('s') then
        mul = 0.1
    end

    if playing.state ~= PlayState.paused then
        currentGame:update(dt*mul)
    end

    if Pie then Pie:detach() end

    frameTime = frameTime + dt
    frameCount = frameCount + 1
    if frameTime >= 0.25 then
        fps = frameCount/frameTime
        frameTime = 0
        frameCount = 0
    end
end

function love.draw()
    if Pie then Pie:attach() end

    if screen.state == ScreenState.configwait then
        screen.state = ScreenState.ready
        if screen.resumeMusic then
            currentGame.music:resume()
        end
    end

    local canvas = currentGame:draw()

    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(255, 255, 255)

    if playing.state ~= PlayState.playing then
        love.graphics.setShader(shaders.hueshift)
        local saturation = playing.speed*.85 + .15
        local shift = (1 - playing.speed)*math.pi
        if playing.state == PlayState.resuming then
            shift = -shift
        end
        shaders.hueshift:send("basis", {
            saturation * math.cos(shift),
            saturation * math.sin(shift)
        })
    end
    blitCanvas(canvas)
    love.graphics.setShader()

    -- love.graphics.setColor(255,255,255,255)
    -- love.graphics.circle("fill", input.x*100 + 100, input.y*100 + 100, 5)

    if Pie then Pie:detach() end

    if Pie then Pie:draw() end

    if DEBUG and fps then
        love.graphics.setBlendMode("alpha")
        love.graphics.printf(math.floor(fps*100 + 0.5)/100, 0, 0, love.graphics.getWidth(), "right")
    end
end

