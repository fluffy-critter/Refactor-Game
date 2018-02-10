--[[
Refactor: 7 - flight

(c)2018 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
]]

local util = require('util')
local geom = require('geom')
local input = require('input')
local gfx = require('gfx')
local config = require('config')
local heap = require('thirdparty.binary_heap')
local shaders = require('shaders')

local imagepool = require('imagepool')

local Coin = require('track7.Coin')
local Channel = require('track7.Channel')

local Game = {
    META = {
        tracknum = 7,
        title = "flight",
        duration = 2*60 + 20,
        description = "falling monk",
    }
}

function Game.new()
    local o = {
        ending = {
            start = 121315/960, -- last note
            duration = (123840-121315)*2/960, -- halfway point is where wind sound starts
        }
    }
    setmetatable(o, {__index=Game})

    o:init()
    return o
end

-- returns music position in terms of seconds
function Game:musicPos()
    return self.music:tell()
end

function Game:resize(w, h)
    self.screenSize = {w = w, h = h}
    self.scale = nil
end

function Game:setScale(scale)
    scale = math.min(scale, 1)

    -- Only adjust if we've changed by more than 5% ish
    if self.scale and scale < self.scale*1.05 and scale > self.scale*0.95 then
        return scale
    end

    local pixelfmt = gfx.selectCanvasFormat("rgba8", "rgba4", "rgb5a1")

    -- Set the canvas to the screen resolution directly
    self.scale = scale
    self.canvas = love.graphics.newCanvas(
        math.floor(scale*self.screenSize.w),
        math.floor(scale*self.screenSize.h),
        pixelfmt)

    return scale
end

function Game:init()
    self:resize(love.graphics.getWidth(), love.graphics.getHeight())

    self.score = 0

    self.itemSprites, self.itemQuads = gfx.loadSprites('track7/sprites.png', 'track7/sprites.lua', {mipmaps=true})
    self.monkSprites, self.monkQuads = gfx.loadSprites('track7/monk.png', 'track7/monk.lua', {mipmaps=true})

    self.camera = {
        y = 0,
        vy = 0
    }

    self.monk = {
        dampX = 1, -- damping factor for horizontal velocity
        x = 0,
        y = 0,
        vx = 0,
        vy = 0,
        tiltX = 0,
        theta = 0,
        r = 100,

        -- based on the spritesheet quad
        cx = 256/2 - 4,
        cy = 686/2 - 24,

        -- face center x/y
        fx = 1024/5/2,
        fy = 1024/5 + 160/2
    }

    -- set the arena boundaries
    self.bounds = {
        center = 0,
        width = 1100,
        minWidth = 400,
        maxWidth = 600
    }

    -- configure the mountain channel
    self.channel = Channel.new({
        spriteSheet = self.itemSprites,
        wallQuad = self.itemQuads.wall,
    })

    self.music = love.audio.newSource('track7/07-flight.mp3')
    -- self.music:setVolume(0)

    -- parse the note event list
    local eventlist = love.filesystem.load('track7/events.lua')()
    self.events = heap:new()
    for _,data in ipairs(eventlist) do
        self.events:insert(data[1]/960, {
            track = data[2],
            note = data[3],
            velocity = data[4]
        })

        -- track the minimum and maximum note values
        self.bounds.minNote = math.min(data[3], self.bounds.minNote or data[3])
        self.bounds.maxNote = math.max(data[3], self.bounds.maxNote or data[3])
    end

    local ramp = love.filesystem.load('track7/leveldata.lua')()
    for _,data in ipairs(ramp) do
        self.events:insert(data[1], function()
            self.bounds.minWidth = data[2]
            self.bounds.maxWidth = data[3]
        end)
    end

    self.actors = {}

    self.monkShader = shaders.load('track7/windDistort.fs')

    self.scoreFont = love.graphics.newImageFont('track7/scorefont.png', '0123456789')
    self.debugFont = love.graphics.newFont(12)
    self.background = imagepool.load('track7/background.jpg')

    self.faces = {}
    self.usedFaces = {}

    -- maybe we'll use this for something?
    local aminals = {
        -- page 1, row 1
        "Basset hound",
        "Cat",
        "Kudu",
        "Axolotl",
        "Armadillo",
        -- row 2
        "Echidna",
        "Opossum",
        "Wallaby",
        "Kiwi",
        "Pigeon",
        -- row 3
        "Ibex",
        "Capybara",
        "Red fox",
        "Cuttlefish",
        "Bullfrog",
        -- row 4
        "Chevrotain",
        "King snake",
        "Giraffe",
        "Chicken",
        "Meerkat",
        -- row 5
        "Dik-dik",
        "Okapi",
        "Lemur",
        "Marmoset",
        "Tragopan", -- who's a pretty bird?

        -- page 2, row 1
        "Hyrax",
        "Cheetah",
        "Kangaroo",
        "Platypus", -- of COURSE there's a platypus
        "Tanuki", -- pls dont sue me nintendo
        -- row 2
        "Dugong/manatee", -- yes I realize they are different
        "Emu",
        "Bonobo",
        "Ant",
        "Kakapo", -- You are being shagged by a rare parrot
        -- row 3
        "Pangolin",
        "Quoll",
        "Anglerfish",
        "Raccoon",
        "Dormouse",
        -- row 4
        "Bluebird",
        "Turtle",
        "Lamb",
        "Coatimundi",
        "Weasel", -- dook dook
        -- row 5
        "Snail",
    }

    for n,name in ipairs(aminals) do
        local x = (n - 1) % 5
        local y = math.floor((n - 1)/5) % 5
        local page = math.floor((n - 1)/25) + 1

        local sheet = imagepool.load('track7/faces-' .. page .. '.png', {mipmaps=true})
        self.faces[n] = {
            sheet = sheet,
            quad = love.graphics.newQuad(x*1024/5, y*1024/5, 1024/5, 1024/5, 1024, 1024),
            index = n,
            name = name
        }
    end

    -- temporary for testing
    -- self.monk.face = self.faces[#self.faces]
end

function Game:start()
end

function Game:onButtonPress(button)
    if button == 'skip' then
        self.music:seek(self:musicPos() + 10)
    end
end

function Game:update(dt)
    if not self.endingTime and self:musicPos() > self.ending.start then
        self.endingTime = 0
    elseif self.endingTime then
        self.endingTime = self.endingTime + dt
        if self.endingTime > self.ending.duration then
            self.gameOver = true
        end
    end

    if self.faceTime then
        self.faceTime = self.faceTime + dt
    end

    self.monk.tiltX = math.pow(0.1, dt)*(self.monk.tiltX + input.x*dt)

    local monkUp = geom.normalize({self.monk.tiltX, -0.5})
    self.monk.theta = math.atan(monkUp[1], -monkUp[2])

    local ax = -self.monk.vx*self.monk.dampX
    local ay = 200

    if input.y < 0 then
        ay = ay + 50*input.y
    end

    ax = ax + 2*math.abs(self.monk.vy)*monkUp[1]

    if self.monk.vy > 0 then
        -- If we're heading down, apply wind resistance to the monk
        ay = ay + self.monk.vy*monkUp[2]*0.1
    else
        -- Increase the fall rate until we are going downward
        ay = ay*2
    end

    self.monk.x = self.monk.x + (self.monk.vx + 0.5*ax*dt)*dt
    self.monk.y = self.monk.y + (self.monk.vy + 0.5*ay*dt)*dt

    if not self.started and self.monk.y > 500 then
        self.started = true
        self.music:play()
    end

    self.monk.vx = self.monk.vx + ax*dt
    self.monk.vy = self.monk.vy + ay*dt

    do
        local c = self.camera
        local lag = 0.5 -- how far the camera lags behind the player

        -- where the player will be in (lag) seconds
        local targetY = self.monk.y + (self.monk.vy + .5*ay*lag)*lag

        -- targetY = cameraY + t*cameraVY + t*t*cameraAY/2, solve for cameraAY
        local cameraAY = 2*(targetY - c.y - lag*c.vy)/lag/lag

        c.y = c.y + (c.vy + 0.5*cameraAY*dt)*dt
        c.vy = c.vy + cameraAY*dt
    end

    self.channel:update(self.camera.y + 600, function()
        local b = self.bounds

        local curLeft = b.center - b.width
        local curRight = b.center + b.width

        -- if the maxima are already outside bounds, allow it; otherwise don't let it drift further
        local maxLeft = math.min(curLeft, -900)
        local maxRight = math.max(curRight, 900)

        -- If the width already exceeds the maxima let it ratchet towards but don't let it go further away
        local minWidth = math.min(b.width, b.minWidth)
        local maxWidth = math.max(b.width, b.maxWidth)
        b.width = util.clamp(b.width + math.random(-10, 10), minWidth, maxWidth)

        -- and ratchet the channel so it doesn't intersect the monk (but don't make it so obvious)
        local step = math.random(-100, 100)
        local minCenter = self.monk.x + self.monk.r - b.width + 1
        local maxCenter = self.monk.x - self.monk.r + b.width - 1
        if b.center + step < minCenter or b.center + step > maxCenter then
            step = -step
        end

        b.center = util.clamp(b.center + step, maxLeft + b.width, maxRight - b.width)

        return {b.center - b.width, b.center + b.width}
    end)

    local nrm = self.channel:checkCollision(self.monk.x, self.monk.y, self.monk.r)
    if nrm then
        -- spawn small uncollectable coins and decrease score
        local coins = math.min(30, math.floor(self.score/4))
        self.score = self.score - coins
        for _=1,coins do
            local theta = math.random()*2*math.pi
            local mag = geom.vectorLength({self.monk.vx, self.monk.vy})
            table.insert(self.actors, Coin.new({
                x = self.monk.x,
                y = self.monk.y,
                r = 10,
                vx = self.monk.vx + mag*math.sin(theta),
                vy = self.monk.vy + mag*math.cos(theta),
                ay = ay + 540,
                channel = self.channel,
                spriteSheet = self.itemSprites,
                quads = self.itemQuads.coin,
                frameSpeed = 20 + math.random(0, 20),
                frameTime = math.random()*1000
            }))
        end

        -- offset to stop penetration
        self.monk.x = self.monk.x + nrm[1]
        self.monk.y = self.monk.y + nrm[2]

        -- reflect velocity vector
        self.monk.vx, self.monk.vy = geom.reflectVector(nrm, self.monk.vx, self.monk.vy)
        self.monk.tiltX = math.abs(self.monk.tiltX)*(nrm[1] < 0 and -1 or 1)

    end

    local now = self:musicPos()
    while not self.events:empty() and self.events:next_key() <= now do
        local _,event = self.events:pop()

        if type(event) == "function" then
            event(now)
        else
            if config.debug then
                print(event.track, event.note, event.velocity)
            end

            if self.nextFace then
                self.monk.face = self.nextFace
                self.nextFace = nil
                self.faceTime = 0
            end

            local xpos = (event.note - self.bounds.minNote)/(self.bounds.maxNote - self.bounds.minNote)
            local jump = 540*1.5*4

            local spawn = {
                y = self.camera.y + 540,
                x = self.bounds.center + self.bounds.width*(xpos*2 - 1)/2,
                vx = math.random(-event.velocity, event.velocity),
                vy = self.monk.vy - jump,
                ay = ay + jump*2,
                sprite = self.itemSprites,
                quad = self.itemQuads.coin,
                channel = self.channel,
                onCollect = function()
                    self.score = self.score + 1
                    return true -- TODO fade out instead?
                end,
                spriteSheet = self.itemSprites,
                quads = self.itemQuads.coin,
                frameSpeed = (12 + event.velocity/25) * (math.random(0,1)*2 - 1),
                frameTime = math.random()*1000
            }

            if event.track == 3 then
                spawn.quads = self.itemQuads.gem
                spawn.frameSpeed = spawn.frameSpeed*2

                spawn.onCollect = function()
                    self.score = self.score + 100

                    if #self.faces == 0 then
                        self.faces = self.usedFaces
                        self.usedFaces = {}
                    end

                    if #self.faces > 0 and not self.nextFace then
                        -- grab a random face to set on next note, remove from queue
                        local idx = math.random(1,#self.faces)
                        local face = self.faces[idx]
                        table.insert(self.usedFaces, face)

                        self.nextFace = face
                        self.faces[idx] = self.faces[#self.faces]
                        table.remove(self.faces, #self.faces)

                        -- TODO add poof effect actor
                    end

                    return true
                end

            end

            table.insert(self.actors, Coin.new(spawn))
        end
    end

    util.runQueue(self.actors, function(actor)
        if actor:update(dt, self.camera.y + 540) then
            return true
        end

        if actor.onCollect and geom.pointPointCollision(actor.x, actor.y, actor.r,
            self.monk.x, self.monk.y, self.monk.r) then
            return actor:onCollect()
        end
    end)
end

function Game:draw()
    love.graphics.setBlendMode("alpha", "alphamultiply")

    self.canvas:renderTo(function()
        love.graphics.clear(71, 143, 229, 255)

        local ww = self.canvas:getWidth()
        local hh = self.canvas:getHeight()

        -- make a 1920x1080 box fit on the screen
        local scale = math.min(ww/1920, hh/1080)

        -- center the coordinate system such that x=0 is the center of the screen and y=540 is the bottom edge
        -- 540*scale + ty = hh
        local tx = ww/2
        local ty = hh - 540*scale

        -- compute the extents of the playfield, given that x*scale + tx = ox, i.e. x = (ox - tx)/scale
        local minX = (0 - tx)/scale
        local maxX = (ww - tx)/scale
        local minY = (0 - ty)/scale
        local maxY = (hh - ty)/scale

        -- draw the scene
        love.graphics.push()
        love.graphics.translate(tx, ty)
        love.graphics.scale(scale)

        love.graphics.setColor(255,255,255,255)
        local bgScale = (maxX - minX)/self.background:getWidth()
        local bgPad = maxY - self.background:getHeight()*bgScale
        -- maximum velocity is around 1700, so maximum Y offset is about 1700*140 = 238000
        love.graphics.draw(self.background, minX,
            bgPad*(math.min(1, self.camera.y/200000) + 1)/2,
            0, bgScale)

        love.graphics.translate(0, -self.camera.y)

        -- draw the mountain
        self.channel:draw(minY + self.camera.y, maxY + self.camera.y, minX, maxX)

        -- draw the monk
        love.graphics.setColor(255,255,255)

        love.graphics.setShader(self.monkShader)
        local windSpeed = 0.015*math.min(1, self.monk.vy/3000)
        self.monkShader:send("windAmount", {
            math.sin(self.monk.theta)*windSpeed,
            math.cos(self.monk.theta)*windSpeed
        })
        self.monkShader:send("phase", self.monk.y/1000)
        love.graphics.draw(self.monkSprites, self.monkQuads.monk,
            self.monk.x, self.monk.y, self.monk.theta,
            0.8, 0.8, self.monk.cx, self.monk.cy)
        love.graphics.setShader()

        if self.monk.face then
            local alpha
            if self.faceTime then
                local t = math.min(1, self.faceTime/1.5)
                alpha = 255*(1 - util.smoothStep(t*t))
            else
                alpha = 255
            end

            if alpha > 0 then
                love.graphics.setColor(255, 255, 255, alpha)
                love.graphics.draw(self.monk.face.sheet, self.monk.face.quad,
                    self.monk.x, self.monk.y, self.monk.theta,
                    0.8, 0.8, self.monk.fx, self.monk.fy)
            else
                self.monk.face = nil
            end
        end

        if config.debug then
            love.graphics.circle("line", self.monk.x, self.monk.y, self.monk.r)
            love.graphics.line(self.monk.x, self.monk.y,
                self.monk.x + self.monk.vx/10, self.monk.y + self.monk.vy/10)
        end

        for _,actor in pairs(self.actors) do
            actor:draw()
        end

        love.graphics.pop()

        if self.endingTime then
            -- fade to white
            local alpha = math.min(255, self.endingTime*255/self.ending.duration)
            love.graphics.setColor(255, 255, 255, alpha)
            love.graphics.rectangle("fill", 0, 0, ww, hh)
        end

        -- draw the scoreboard
        love.graphics.push()
        love.graphics.translate(tx, ty)
        love.graphics.scale(scale)

        love.graphics.setColor(255,255,255)
        love.graphics.draw(self.itemSprites, self.itemQuads.paper, minX - 100, minY, 0, 0.5, 0.5)
        love.graphics.setColor(0,0,0)
        love.graphics.setFont(self.scoreFont)
        love.graphics.print(self.score, minX + 16, minY + 16)

        if config.debug then
            love.graphics.setColor(255,128,0)
            love.graphics.line(-self.bounds.minWidth, minY, -self.bounds.minWidth, maxY)
            love.graphics.line(self.bounds.minWidth, minY, self.bounds.minWidth, maxY)

            love.graphics.setColor(128,255,0)
            love.graphics.line(-self.bounds.maxWidth, minY, -self.bounds.maxWidth, maxY)
            love.graphics.line(self.bounds.maxWidth, minY, self.bounds.maxWidth, maxY)
        end


        love.graphics.pop()

    end)
    return self.canvas
end

return Game
