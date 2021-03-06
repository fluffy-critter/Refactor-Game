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
        play()
        pause()
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

local config = require 'config'

local DEBUG = config.debug or false

local profiler = config.profiler and require 'profiler'
local cute = require 'thirdparty.cute'

local shaders = require 'shaders'
local util = require 'util'
local input = require 'input'
local fonts = require 'fonts'
local imagepool = require 'imagepool'
local playlist = require 'playlist'

local Menu = require 'Menu'

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

local tracks = {}
local trackListing = {
    "little bouncing ball",
    "strangers",
    "sliced by a mandolin",
    "deer drinking from the catacomb stream",
    "road to nowhere",
    "silica",
    "flight",
    "and counting",
    "roundsabout",
    "soliloquy",
    "circle",
    "feed",
    "adding up to nothing"
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
local vsync

local frameCount = 0
local frameTime = 0
local frameTimeSqr = 0
local frameTarget
local renderScale
local fps

local updateTime = 0

local bgLoops = {
    love.audio.newSource('mainmenu/loop1.mp3', 'stream'),
    love.audio.newSource('mainmenu/loop2.mp3', 'stream'),
    love.audio.newSource('mainmenu/loop3.mp3', 'stream')
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

    frameTime = 0
    frameCount = 0
    renderScale = config.scaleFactor

    if currentGame.resize then
        currentGame:resize(love.graphics.getWidth(), love.graphics.getHeight())
    end
    if currentGame.setScale then
        renderScale = currentGame:setScale(renderScale)
    end

    playlist.lastDesc = currentGame.META.description

    currentGame:start()
end

local menuStack = {}

local function onPause()
    if playing.state == PlayState.pausing or playing.state == PlayState.paused then
        playing.state = PlayState.resuming
        if playing.resumeMusic then
            currentGame.music:play()
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

        config.fullscreen = not love.window.getFullscreen()
        love.window.setFullscreen(config.fullscreen)

        config.save()
    elseif currentGame and button == 'back' then
        playing.state = PlayState.ending
        playlist.tracks = {}
    elseif currentGame and currentGame.onButtonPress then
        currentGame:onButtonPress(button)
    elseif not currentGame then
        menuStack[#menuStack]:onButtonPress(button)
    end
end

function input.onRelease(button)
    if currentGame and currentGame.onButtonRelease then
        currentGame:onButtonRelease(button)
    end
end

local chainKeypressed = love.keypressed
function love.keypressed(...)
    cute.keypressed(...)

    if chainKeypressed then
        chainKeypressed(...)
    end
end

local function credits()
    -- TODO come up with a better space breaking priority mechanism (one better than font:getWrap)
    local creditsLines = {
        {font=fonts.menu.h1, text="Refactor"},
        "\n",
        'All music, code, and art ©2015-2017 j.\194\160“fluffy”\194\160shagam unless otherwise specified',
        {
            font=fonts.menu.url,
            text="http://sockpuppet.us/ • http://beesbuzz.biz/ • http://fluffy.itch.io/"
        },
        "\n",
        {font=fonts.menu.h1, text="Acknowledgments"},
        "\n",
        {font=fonts.menu.h2, text="Patreon supporters"},
        "Tambi • Jukka • Austin • Sally\194\160Bird • Kyreeth • M.Wissig",
        "\n",
        {font=fonts.menu.h2, text="Moral support"},
        "Emmy • Nate • Zeno • Jakub • Lito • Rachel • Patrick • Milo • Packbat"
        .. " • Seattle\194\160Indies • Double\194\160Jump",
        "\n",
        "Built with LÖVE",
        {font=fonts.menu.url, text="http://love2d.org"},
        "\n",
        "See the LICENSE file for additional credits"
    }

    local canvas

    return {
        scrollY = 0,
        height = 0,
        draw = function(self)
            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(1,1,1,1)

            -- TODO better sizing
            local width = math.ceil(love.graphics.getWidth()/3)
            local height = love.graphics.getHeight()

            -- TODO proper measurement (really I should just do a friggin' text canvas object, huh?)
            if not canvas or canvas:getWidth() < width or canvas:getHeight() < height then
                canvas = love.graphics.newCanvas(width, height)
            end

            canvas:renderTo(function()
                love.graphics.setBlendMode("alpha")
                love.graphics.setColor(1,1,1,1)
                love.graphics.clear(0,0,0,0)

                love.graphics.push()
                love.graphics.translate(0, -self.scrollY)

                local y = 8
                for _,line in ipairs(creditsLines) do
                    local text
                    if type(line) == "string" then
                        text = line
                    else
                        text = line.text
                    end

                    local font = line.font or fonts.menu.regular

                    love.graphics.setFont(font)
                    local _, wrappedtext = util.fairWrap(font, text, width)
                    for _,s in ipairs(wrappedtext) do
                        -- trim out any separators that got orphaned
                        s = s:gsub("^ *• ", ""):gsub(" *• *$", "")

                        love.graphics.printf(s, 0, y, width, "center")
                        y = y + font:getHeight()
                    end
                end

                self.height = y

                love.graphics.pop()
            end)

            love.graphics.setBlendMode("alpha","premultiplied")
            love.graphics.setColor(0,0,0,2)
            for x=-2,2 do
                for y=-2,2 do
                    love.graphics.draw(canvas, x+8, y)
                end
            end
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(canvas,8,0)

            if height < self.height then
                local yh = height*height/self.height
                local y0 = self.scrollY*height/self.height
                love.graphics.rectangle("fill", 0, y0, 4, yh)
            end
        end,
        update = function(self, dt)
            local maxScroll = math.max(0, self.height - love.graphics.getHeight())
            self.scrollY = util.clamp(self.scrollY + input.y*dt*500, 0, maxScroll)
        end,
        onButtonPress = function(_, button)
            if button == "back" or button == "a" or button == "b" then
                menuStack[#menuStack] = nil
            end
        end
    }
end

local function mainmenu()
    local choices = {}

    if #tracks > 1 then
        table.insert(choices, {
            label = "Play all",
            onSelect = function()
                for _,item in ipairs(tracks) do
                    if item.track then
                        table.insert(playlist.tracks, item.track)
                    end
                end
                print("playlist length = " .. #playlist.tracks)
            end
        })
        table.insert(choices, {})
    end

    for _,track in ipairs(tracks) do
        table.insert(choices, track)
    end
    if #tracks == 1 then
        table.insert(choices, {
            label = "Get full game",
            onSelect = function()
                love.system.openURL('http://fluffy.itch.io/refactor')
            end
        })
    end

    table.insert(choices, {})
    table.insert(choices, {
        label="Credits",
        onSelect = function()
            table.insert(menuStack, credits())
        end
    })

    if not config.kiosk then
        table.insert(choices, {})
        -- TODO
        -- table.insert(choices, {label="Settings"})
        table.insert(choices, {
            label="Exit",
            onSelect = function()
                os.exit(0)
            end
        })
    end

    return Menu.new({choices = choices})
end

local function applyGraphicsConfig()
    -- apply the configuration stuff (can't do this in conf.lua because of chicken-and-egg with application directory)
    love.window.setMode(config.width, config.height, {
        resizable = true,
        fullscreen = config.fullscreen,
        vsync = config.vsync,
        highdpi = config.highdpi,
        minwidth = 480,
        minheight = 480,
    })

    local _, _, flags = love.window.getMode()
    vsync = flags.vsync

    local refresh = config.targetFPS or flags.refreshrate
    if not refresh or refresh == 0 then
        refresh = 60 -- default that makes most sense
    end
    frameTarget = 1/refresh

    renderScale = config.scaleFactor

    fonts.setPixelScale(1)
end

function love.load(args)
    cute.go(args)

    -- scan for all of the existing tracks and add them to the track list
    -- TODO maybe we could only actually load the game when we need it?
    local count = 0
    for i=1,13 do
        local chunk = love.filesystem.load("track" .. i .. "/init.lua")
        if chunk then
            local track = chunk()
            table.insert(tracks, {
                track = track,
                label = string.format("%d. %s (%d:%d)",
                    track.META.tracknum,
                    track.META.title,
                    track.META.duration / 60,
                    track.META.duration % 60),
                tooltip = string.format("%s / %s", track.META.genre, track.META.style),
                onSelect = track.new and function()
                    startGame(track)
                end
            })
            count = count + 1
        else
            table.insert(tracks, {
                label = string.format("%d. %s", i, trackListing[i])
            })
        end
    end
    if count == 1 then
        -- we only loaded one actual track, so this is a singles pack
        util.runQueue(tracks, function(track)
            return not track.onSelect
        end)
    end

    applyGraphicsConfig()

    math.randomseed(os.time())

    love.mouse.setVisible(false)
    love.keyboard.setKeyRepeat(true)

    menuStack = {mainmenu()}

    local track
    for _,arg in ipairs(args) do
        if arg:sub(1, 5) == "track" then
            track = require(arg)
            startGame(track)
        end
    end

    for _,loop in ipairs(bgLoops) do
        loop:setLooping(true)
        loop:setVolume(0)
    end
end

function love.resize(w, h)
    print("resize " .. w .. ' ' .. h)
    if not config.fullscreen then
        config.width, config.height = love.window.getMode()
        config.save()
    end

    if currentGame and currentGame.resize then
        currentGame:resize(w, h)
    end

    renderScale = config.scaleFactor
    if currentGame and currentGame.setScale then
        currentGame:setScale(renderScale)
    end
end

function love.update(dt)
    if profiler then profiler.attach("update", dt) end

    if screen.state == ScreenState.configwait then
        return
    end

    local updateStart = love.timer.getTime()

    if playing.state == PlayState.menu then
        menuVolume = math.min(1, menuVolume + dt)
        for _,loop in ipairs(bgLoops) do
            loop:setVolume(menuVolume)
            if not loop:isPlaying() then
                loop:seek(math.random()*loop:getDuration())
                loop:play()
            end
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

    if currentGame then
        if playing.state ~= PlayState.paused then
            currentGame:update(dt*mul)
        end
    elseif #playlist.tracks > 0 then
        startGame(playlist.tracks[1])
        table.remove(playlist.tracks, 1)
    elseif menuStack[#menuStack] and menuStack[#menuStack].update then
        menuStack[#menuStack]:update(dt*mul)
    end

    frameTime = frameTime + dt
    frameTimeSqr = frameTimeSqr + dt*dt
    frameCount = frameCount + 1
    if frameTime > 0.5 then
        fps = frameCount/frameTime
        if currentGame and currentGame.onFps then
            currentGame:onFps(fps)
        end

        if config.adaptive and currentGame and currentGame.setScale then
            -- TODO account for the difference between render and total time, but ignore vsync time
            local avgTime = frameTime/frameCount
            local varTime = frameTimeSqr/frameCount - avgTime*avgTime

            if vsync and varTime < avgTime/20 then
                -- frame time variance is < 5% so let's assume we're halfway between vsync increments
                avgTime = avgTime*3/4
            end

            -- if the update is longer than the frame time there's no way a graphics sacrifice will help,
            -- so let's target the next interval down
            local targetTime = math.ceil(updateTime/frameTarget)*frameTarget

            -- scale up based on worst-case time per standard deviation
            renderScale = math.max((renderScale*3 + renderScale*targetTime/(avgTime + varTime))/4, 0.005)
            renderScale = currentGame:setScale(renderScale)
        end

        frameTime = 0
        frameTimeSqr = 0
        frameCount = 0
    end

    local delta = love.timer.getTime() - updateStart
    updateTime = delta*.5 + updateTime*.5

    if profiler then profiler.detach() end
end

function love.draw()
    cute.draw()

    if screen.state == ScreenState.configwait then
        screen.state = ScreenState.ready
        love.resize(love.graphics.getWidth(), love.graphics.getHeight())
        if screen.resumeMusic then
            currentGame.music:play()
        end
    end

    if profiler then profiler.attach("draw") end

    if currentGame then
        love.graphics.clear(1/8, 1/8, 1/8)

        love.graphics.push()
        love.graphics.origin()

        local canvas, aspect = currentGame:draw()

        love.graphics.setBlendMode("alpha", "premultiplied")
        local brt = util.smoothStep(playing.fade)
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

        love.graphics.pop()

        blitCanvas(canvas, aspect)
        love.graphics.setShader()
    else
        love.graphics.push()
        local res = love.window.getDPIScale()
        love.graphics.scale(res)

        love.graphics.clear(0,0,0)
        love.graphics.setBlendMode("alpha")

        -- draw menu
        local w = love.graphics:getWidth()/res
        local h = love.graphics:getHeight()/res

        love.graphics.setColor(44/255,48/255,0)
        love.graphics.rectangle("fill", 0, 0, w, 300)
        love.graphics.setColor(1,1,1,1)

        local dpi = love.window.getDPIScale()

        local ground = imagepool.load('mainmenu/ground.png')
        for x = 0, w, ground:getWidth()/dpi do
            love.graphics.draw(ground, x, 0, 0, 1/dpi)
        end

        local bg = imagepool.load('mainmenu/forest-stuff.png')
        local scale = math.min(w/bg:getWidth(), h*1.2/bg:getHeight())
        love.graphics.draw(bg, (w - bg:getWidth()*scale)/2, 0, 0, scale, scale)

        local logo = imagepool.load('mainmenu/refactor-released.png')
        love.graphics.draw(logo, w - logo:getWidth()/dpi, h - logo:getHeight()/dpi, 0, 1/dpi)

        love.graphics.pop()
        menuStack[#menuStack]:draw()

        love.graphics.setBlendMode("alpha")
        love.graphics.setFont(fonts.menu.versionText)
        love.graphics.printf("version " .. config.version, 0, 8, love.graphics.getWidth() - 8, "right")

        if config.debug then
            local pos = ""
            for n,loop in ipairs(bgLoops) do
                pos = pos .. string.format("[%d]%s:%.2f ", n, loop:isPlaying() and "p" or "s", loop:tell())
            end
            love.graphics.print(pos, 0, love.graphics.getHeight() - 16)
        end
    end

    -- love.graphics.setColor(1,1,1,1)
    -- love.graphics.circle("fill", input.x*100 + 100, input.y*100 + 100, 5)

    if profiler then
        profiler.detach()
        profiler.draw()
    end

    if DEBUG and fps then
        love.graphics.setBlendMode("alpha")
        love.graphics.setFont(fonts.debug)
        love.graphics.printf(renderScale .. "  " .. math.floor(fps*100 + 0.5)/100,
            0, 0, love.graphics.getWidth(), "right")
    end

    if profiler then profiler.attach("after") end
end

