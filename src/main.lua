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

-- TODO switch to util.enum
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

function input.onPress(button)
    if button == 'start' then
        onPause()
    elseif button == 'fullscreen' then
        --[[ TODO pause the music and game updates while this is happening (or else physics goes wonky on Mac)

        useful refactor: put game state, screen state, etc. into separate dicts, e.g. music.state="playing", music.speed=1.0, music.resumeOnPlay=false, screen.state="switching", etc.
        ]]
        love.window.setFullscreen(not love.window.getFullscreen())
    elseif currentGame.onButtonPress then
        currentGame:onButtonPress(button)
    end
end

function input.onRelease(button)
    if currentGame.onButtonRelease then
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

    input.update(dt)

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

    local canvas = currentGame:draw()

    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(255, 255, 255)

    if state ~= "playing" then
        love.graphics.setShader(shaders.hueshift)
        local saturation = speed*.85 + .15
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

    -- love.graphics.setColor(255,255,255,255)
    -- love.graphics.circle("fill", input.x*100 + 100, input.y*100 + 100, 5)

    if Pie then Pie:detach() end

    if Pie then Pie:draw() end

    if DEBUG and fps then
        love.graphics.setBlendMode("alpha")
        love.graphics.printf(math.floor(fps*100 + 0.5)/100, 0, 0, love.graphics.getWidth(), "right")
    end
end

