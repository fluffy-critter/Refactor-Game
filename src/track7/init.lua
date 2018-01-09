--[[
Refactor: 7 - flight

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.
]]

local util = require('util')
local geom = require('geom')
local input = require('input')
local gfx = require('gfx')
local heap = require('thirdparty.binary_heap')

local quadtastic = require('thirdparty.libquadtastic')
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
    local o = {}
    setmetatable(o, {__index=Game})

    o:init()
    return o
end

-- returns music position in terms of MIDI clocks
function Game:musicPos()
    return self.music:tell()*960
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

    self.sprites = imagepool.load('track7/sprites.png', {mipmaps=true})
    local atlas = love.filesystem.load('track7/sprites.lua')()
    self.quads = quadtastic.create_quads(atlas, self.sprites:getWidth(), self.sprites:getHeight())

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
        theta = 0
    }

    -- set the arena boundaries
    self.bounds = {center = 0, width = 1000}

    -- configure the mountain channel
    self.channel = Channel.new({
        spriteSheet = self.sprites,
        leftQuad = self.quads.walls.left,
        rightQuad = self.quads.walls.right
    })

    self.music = love.audio.newSource('track7/07-flight.mp3')
    -- self.music:setVolume(0)

    -- parse the note event list
    local eventlist = love.filesystem.load('track7/events.lua')()
    self.events = heap:new()
    for _,data in ipairs(eventlist) do
        self.events:insert(data[1], {
            track = data[2],
            note = data[3],
            velocity = data[4]
        })

        -- track the minimum and maximum note values
        self.bounds.minNote = math.min(data[3], self.bounds.minNote or data[3])
        self.bounds.maxNote = math.max(data[3], self.bounds.maxNote or data[3])
    end

    self.actors = {}

    self.monk.cx = atlas.monk.w/2
    self.monk.cy = atlas.monk.h/2
end

function Game:start()
    self.music:play()
end

function Game:update(dt)
    self.monk.tiltX = math.pow(0.1, dt)*(self.monk.tiltX + input.x*dt)

    local monkUp = geom.normalize({self.monk.tiltX, -0.5})
    self.monk.theta = math.atan(monkUp[1], -monkUp[2])

    local ax = -self.monk.vx*self.monk.dampX
    local ay = 200

    -- If we're heading down, apply wind force to the monk
    if self.monk.vy > 0 then
        ax = ax + 2*self.monk.vy*monkUp[1]
        ay = ay + self.monk.vy*monkUp[2]*0.1
    end

    self.monk.x = self.monk.x + (self.monk.vx + 0.5*ax*dt)*dt
    self.monk.y = self.monk.y + (self.monk.vy + 0.5*ay*dt)*dt

    self.monk.vx = self.monk.vx + ax*dt
    self.monk.vy = self.monk.vy + ay*dt

    do
        local c = self.camera
        local lag = 1 -- how far the camera lags behind the player

        -- where the player will be in (lag) seconds
        local targetY = self.monk.y + (self.monk.vy + .5*ay*lag)*lag

        -- targetY = cameraY + t*cameraVY + t*t*cameraAY/2, solve for cameraAY
        local cameraAY = 2*(targetY - c.y - lag*c.vy)/lag/lag

        c.y = c.y + (c.vy + 0.5*cameraAY*dt)*dt
        c.vy = c.vy + cameraAY*dt
    end

    self.channel:update(self.camera.y + 600, function()
        local b = self.bounds
        b.width = util.clamp(b.width + math.random(-10, 10), 100, 600)
        b.center = util.clamp(b.center + math.random(-100, 100), -900 + b.width, 900 - b.width)
        return {b.center - b.width, b.center + b.width}
    end)

    local wallL, wallR = self.channel:getExtents(self.monk.y, self.monk.y + 100)
    if wallL and self.monk.x < wallL then
        self.monk.vy = -.25*self.monk.vy
        self.monk.vx = math.abs(self.monk.vx) + wallL - self.monk.x
        self.monk.tiltX = math.abs(self.monk.tiltX)
    end
    if wallR and self.monk.x > wallR then
        self.monk.vy = -.25*self.monk.vy
        self.monk.vx = -math.abs(self.monk.vx) + wallR - self.monk.x
        self.monk.tiltX = -math.abs(self.monk.tiltX)
    end

    local now = self:musicPos()
    while not self.events:empty() and self.events:next_key() <= now do
        local _,event = self.events:pop()
        print(event.track, event.note, event.velocity)

        -- TODO differentiate different coin types
        local xpos = (event.note - self.bounds.minNote)/(self.bounds.maxNote - self.bounds.minNote)
        table.insert(self.actors, Coin.new({
            y = self.camera.y + 540,
            x = self.bounds.center + self.bounds.width*(xpos*2 - 1),
            vy = -event.velocity*2,
            ay = self.monk.vy,
            sprite = self.sprites,
            quad = self.quads.coin
        }))
    end

    util.runQueue(self.actors, function(actor)
        return actor:update(dt, self.camera.y + 540)
    end)
end

function Game:draw()
    self.canvas:renderTo(function()
        love.graphics.clear(0,0,127,255)

        love.graphics.push()

        local ww = self.canvas:getWidth()
        local hh = self.canvas:getHeight()

        -- make a 1920x1080 box fit on the screen
        local scale = math.min(ww/1920, hh/1080)

        -- center the coordinate system such that x=0 is the center of the screen and y=540 is the bottom edge
        -- 540*scale + ty = hh
        local tx = ww/2
        local ty = hh - 540*scale
        love.graphics.translate(tx, ty)
        love.graphics.scale(scale)

        -- compute the extents of the playfield, given that x*scale + tx = ox, i.e. x = (ox - tx)/scale
        local minX = (0 - tx)/scale
        local maxX = (ww - tx)/scale
        local minY = (0 - ty)/scale
        local maxY = (hh - ty)/scale

        love.graphics.translate(0, -self.camera.y)

        -- draw the mountain
        self.channel:draw(minY + self.camera.y, maxY + self.camera.y)

        -- draw the monk
        love.graphics.draw(self.sprites, self.quads.monk, self.monk.x, self.monk.y, self.monk.theta, 0.5, 0.5, self.monk.cx, self.monk.cy)
        love.graphics.line(self.monk.x, self.monk.y, self.monk.x + self.monk.vx/10, self.monk.y + self.monk.vy/10)

        for _,actor in pairs(self.actors) do
            actor:draw()
        end

        love.graphics.pop()
    end)
    return self.canvas
end

return Game
