--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.


Game class objects are expected to have:

    META - a table containing:
        title - the title of the game
        duration - the duration in seconds

    new() - a method that spawns a new instance

Game instances are expected to have:

    music - an object that presents at least the following subset of the audio source API:
        pause()
        resume()
        stop()
        setPitch(multiplier)
        setVolume(multiplier)
        tell()
        isPlaying()

    gameOver - becomes true/truthy when the game is finished (must be nil or false otherwise); the game
    update/render loop will keep on going, though (the controller will fade the game out once this is true)

    score - the game score (numeric)

]]

setmetatable(_G, {
    __newindex = function(_, name, _)
        error("attempted to write to global variable " .. name, 2)
    end
})

local PROFILE = false
local DEBUG = false

local Pie
if PROFILE then
    local piefiller = require('thirdparty.piefiller')
    Pie = piefiller:new()
    Pie:setKey("save_to_file","w")
end

local cute = require('thirdparty.cute')

local shaders = require('shaders')
local util = require('util')
local input = require('input')
local fonts = require('fonts')
local imagepool = require('imagepool')

local baseTitle = "Sockpuppet - Refactor"

local function blitCanvas(canvas, aspect)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local canvasHeight = canvas:getHeight()
    local canvasWidth = aspect and (canvasHeight * aspect) or canvas:getWidth()
    local sx = canvasWidth/canvas:getWidth()

    local blitSize = { screenWidth, screenWidth*canvasHeight/canvasWidth }
    if screenHeight < blitSize[2] then
        blitSize = { screenHeight*canvasWidth/canvasHeight, screenHeight }
    end

    local blitX = (love.graphics.getWidth() - blitSize[1])/2
    local blitY = (love.graphics.getHeight() - blitSize[2])/2
    love.graphics.draw(canvas, blitX, blitY, 0,
        blitSize[1]*sx/canvasWidth, blitSize[2]/canvasHeight)
end

local tracks = {
    require('track1.game'),
    require('track2.game')
}
local currentGame

local PlayState = util.enum("starting", "playing", "pausing", "paused", "resuming", "ending", "menu")
local playing = {
    state = PlayState.menu,
    unpauseState = nil,
    speed = 1.0,
    resumeMusic = false,
    fade = 0
}

local menuVolume = 0

local bgLoops = {
    love.audio.newSource('mainmenu/loop1.mp3'),
    love.audio.newSource('mainmenu/loop2.mp3'),
    love.audio.newSource('mainmenu/loop3.mp3')
}

local ScreenState = util.enum("ready", "configwait")
local screen = {
    state = ScreenState.waiting,
    resumeMusic = false
}

local function startGame(game)
    currentGame = game.new()
    love.window.setTitle(baseTitle .. ": " .. currentGame.META.title)
    playing.state = PlayState.starting
    playing.speed = 1.0
    playing.fade = 0

    currentGame:start()
end

local menu
local menuPos = 1

local mainmenu = {}

local function onPause()
    if playing.state == PlayState.pausing or playing.state == PlayState.paused then
        playing.state = PlayState.resuming
        if playing.resumeMusic then
            currentGame.music:resume()
        end
    else
        if playing.state ~= PlayState.resuming then
            playing.unpauseState = playing.state
        end
        playing.state = PlayState.pausing
        playing.resumeMusic = currentGame.music:isPlaying()
    end
end

function input.onPress(button)
    if screen.state == ScreenState.configwait then
        return
    end

    if button == 'start' and currentGame then
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
    elseif currentGame and button == 'back' then
        playing.state = PlayState.ending
    elseif currentGame and currentGame.onButtonPress then
        currentGame:onButtonPress(button)
    elseif not currentGame then
        if button == 'up' and menuPos > 1 then
            menuPos = menuPos - 1
            -- TODO play sound
        elseif button == 'down' and menuPos < #menu then
            menuPos = menuPos + 1
            -- TODO play sound
        elseif button == 'a' or button == 'start' then
            menu[menuPos].onSelect()
        elseif button == 'back' or button == 'b' then
            -- TODO parent menu
            menu = mainmenu
        end
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
    cute.keypressed(...)

    if chainKeypressed then
        chainKeypressed(...)
    end
end

function love.mousepressed(...)
    -- local x, y, button, istouch = ...

    if Pie then Pie:mousepressed(...) end
end

function love.load(args)
    math.randomseed(os.time())

    cute.go(args)

    love.mouse.setVisible(false)
    love.keyboard.setKeyRepeat(true)

    for n,track in ipairs(tracks) do
        mainmenu[n] = {
            label = string.format("%d. %s (%d:%d)",
                track.META.tracknum,
                track.META.title,
                track.META.duration / 60,
                track.META.duration % 60),
            onSelect = function()
                startGame(track)
            end
        }
    end
    menu = mainmenu

    local track
    for _,arg in ipairs(args) do
        if arg:sub(1, 5) == "track" then
            track = require(arg .. ".game")
            startGame(track)
        end
    end

    for _,loop in ipairs(bgLoops) do
        loop:setLooping(true)
        loop:setVolume(0)
        loop:play()
        loop:seek(math.random()*loop:getDuration())
    end
end

local frameCount = 0
local frameTime = 0
local fps

function love.update(dt)
    if Pie then Pie:attach() end

    if screen.state == ScreenState.configwait then
        return
    end

    if playing.state == PlayState.menu then
        if menuVolume == 0 then
            for _,loop in ipairs(bgLoops) do
                loop:resume()
            end
        end
        menuVolume = math.min(1, menuVolume + dt)
        for _,loop in ipairs(bgLoops) do
            loop:setVolume(menuVolume)
        end
    end

    if playing.state == PlayState.starting then
        playing.fade = playing.fade + dt
        if playing.fade >= 1 then
            playing.fade = 1
            playing.state = playing.playing

            for _,loop in ipairs(bgLoops) do
                loop:pause()
            end
        end

        menuVolume = 1 - playing.fade
        for _,loop in ipairs(bgLoops) do
            loop:setVolume(menuVolume)
        end
    end

    if currentGame and currentGame.gameOver then
        playing.state = PlayState.ending
    end

    if playing.state == PlayState.ending then
        playing.fade = playing.fade - dt/2
        currentGame.music:setVolume(playing.fade)
        if playing.fade <= 0 then
            currentGame.music:stop()
            currentGame = nil
            love.window.setTitle(baseTitle)
            playing.state = PlayState.menu
        end
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
            playing.state = playing.unpauseState
        end
        currentGame.music:setPitch(playing.speed)
    end

    local mul = playing.speed

    if currentGame and playing.state ~= PlayState.paused then
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
    cute.draw()

    if Pie then Pie:attach() end

    if screen.state == ScreenState.configwait then
        screen.state = ScreenState.ready
        if screen.resumeMusic then
            currentGame.music:resume()
        end
    end

    if currentGame then
        love.graphics.clear(32, 32, 32)

        local canvas, aspect = currentGame:draw()

        love.graphics.setBlendMode("alpha", "premultiplied")
        local brt = 255*util.smoothStep(playing.fade)
        love.graphics.setColor(brt, brt, brt)

        if playing.state ~= PlayState.playing then
            local shader = shaders.load("shaders/hueshift.fs")
            love.graphics.setShader(shader)
            local saturation = playing.speed*.85 + .15
            local shift = (1 - playing.speed)*math.pi
            if playing.state == PlayState.resuming then
                shift = -shift
            end
            shader:send("basis", {
                saturation * math.cos(shift),
                saturation * math.sin(shift)
            })
        end
        blitCanvas(canvas, aspect)
        love.graphics.setShader()
    else
        love.graphics.clear(0,0,0)
        love.graphics.setBlendMode("alpha")

        -- draw menu
        local w = love.graphics:getWidth()
        local h = love.graphics:getHeight()

        love.graphics.setColor(44,48,0)
        love.graphics.rectangle("fill", 0, 0, w, 300)
        love.graphics.setColor(255,255,255,255)

        local ground = imagepool.load('mainmenu/ground.png')
        for x = 0, love.graphics:getWidth(), 702 do
            love.graphics.draw(ground, x, 0)
        end

        local bg = imagepool.load('mainmenu/forest-stuff.png')
        local scale = math.min(w/bg:getWidth(), h*1.2/bg:getHeight())
        love.graphics.draw(bg, (w - bg:getWidth()*scale)/2, 0, 0, scale, scale)

        local logo = imagepool.load('mainmenu/refactor-released.png')
        love.graphics.draw(logo, w - logo:getWidth(), h - logo:getHeight())

        local font = fonts.bodoni72.regular
        love.graphics.setBlendMode("alpha")
        love.graphics.setFont(font)
        love.graphics.setColor(255,255,255,255)
        local y = 0
        for n,item in ipairs(menu) do
            if n == menuPos then
                love.graphics.setColor(255,255,255,255)
                love.graphics.print(">", 8, y + 8)
            else
                love.graphics.setColor(200,200,200,255)
            end
            love.graphics.print(item.label, 24, y + 8)

            y = y + font:getHeight()
        end
    end

    -- love.graphics.setColor(255,255,255,255)
    -- love.graphics.circle("fill", input.x*100 + 100, input.y*100 + 100, 5)

    if Pie then Pie:detach() end

    if Pie then Pie:draw() end

    if DEBUG and fps then
        love.graphics.setBlendMode("alpha")
        love.graphics.setFont(fonts.debug)
        love.graphics.printf(math.floor(fps*100 + 0.5)/100, 0, 0, love.graphics.getWidth(), "right")
    end
end

