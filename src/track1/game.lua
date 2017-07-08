--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local Ball = require('track1.Ball')
local SuperBall = require('track1.SuperBall')
local HitParticle = require('track1.HitParticle')
local SparkParticle = require('track1.SparkParticle')
local Randomizer = require('track1.Randomizer')
local Brick = require('track1.Brick')
local Spawner = require('track1.Spawner')
local geom = require('geom')
local util = require('util')
local shaders = require('shaders')

local Game = {}

function Game.new()
    local o = {}
    setmetatable(o, {__index=Game})

    o:init()
    return o
end

local BPM = 132

-- returns music position as {phase, measure, beat}. beat will be fractional.
function Game:musicPos()
    local beat = self.music:tell()*BPM/60

    local measure = math.floor(beat/4)
    beat = beat - measure*4

    local phase = math.floor(measure/16)
    measure = measure - phase*16

    return {phase, measure, beat}
end

-- seeks the music to a particular spot, using the same format as musicPos(), with an additional timeOfs param that adjusts it by seconds
function Game:seekMusic(phase, measure, beat, timeOfs)
    local time = (phase or 0)
    time = time*16 + (measure or 0)
    time = time*4 + (beat or 0)
    time = time*60/BPM + (timeOfs or 0)
    self.music:seek(time)
end

function Game:init()
    print("1.load")
    self.music = love.audio.newSource('music/01-little-bouncing-ball.mp3')
    self.phase = -1
    self.score = 0

    local limits = love.graphics.getSystemLimits()

    self.canvas = love.graphics.newCanvas(1280, 720)

    self.layers = {}
    self.layers.arena = love.graphics.newCanvas(1280, 720, "rgba8", limits.canvasmsaa)
    self.layers.overlay = love.graphics.newCanvas(1280, 720)

    self.layers.water = love.graphics.newCanvas(1280, 720, "rg32f")
    self.layers.waterBack = love.graphics.newCanvas(1280, 720, "rg32f")
    self.waterParams = {
        fluidity = 1.5,
        damp = 0.913,
        timeMul = 15,
        rsize = 32,
        fresnel = 0.1,
        sampleRadius = 5.5,
    }

    self.bounds = {
        left = 32,
        right = 1280 - 32,
        top = 32,
        bottom = 720
    }

    -- TODO - make it an actor?
    self.paddleDefaults = {
        color = {255, 255, 255, 255},

        w = 60,
        h = 6,

        speed = 18000,
        friction = 0.0015,
        rebound = 0.5,
        tiltFactor = 0.01,
        recoil = 1,
        recovery = 1,
        restY = 660,

    }

    self.paddle = {
        x = 1280 / 2,
        y = 660,
        vx = 0,
        vy = 0,

        -- get the upward vector for the paddle
        tiltVector = function(self)
            local x = self.vx * self.tiltFactor
            local y = -60
            local d = math.sqrt(x * x + y * y)
            return { x / d, y / d }
        end,

        getPolygon = function(self)
            if not self.cachedPoly then
                local ux, uy = unpack(self:tiltVector())
                local rx, ry = -uy, ux

                self.cachedPoly = {
                    self.x + ux*self.h - rx*self.w, self.y + uy*self.h - ry*self.w,
                    self.x + ux*self.h + rx*self.w, self.y + uy*self.h + ry*self.w,
                    self.x - ux*self.h + rx*self.w, self.y - uy*self.h + ry*self.w,
                    self.x - ux*self.h - rx*self.w, self.y - uy*self.h - ry*self.w
                }
            end
            return self.cachedPoly
        end,
    }
    util.applyDefaults(self.paddle, self.paddleDefaults)
    local paddle = self.paddle

    self.particles = {}
    self.actors = {}

    -- initialize with the starter ball
    self.balls = {
        Ball.new(self, {
            r = 10,
            color = {128, 255, 255, 255},
            lives = 3,
            hitColor = {0, 128, 128, 255},
            ay = 30,
            preUpdate = function(self, dt)
                Ball.preUpdate(self, dt)
                self.vx = self.vx + dt*(paddle.x - self.x)
                self.vy = self.vy + dt*(paddle.y - self.y)
            end,
            onHitPaddle = function(self, nrm, paddle)
                self.preUpdate = Ball.preUpdate
                self.onHitPaddle = Ball.onHitPaddle
                self.onStart = Ball.onStart
                self:onHitPaddle(nrm, paddle)
                self.game:setPhase(0)
            end,
            onStart = function(self)
                Ball.onStart(self)
                self.vx = 0
                self.vy = 0
            end,
            onLost = function(self)
                self.ay = self.ay + 30
            end
        })
    }

    self.deferred = {}

    self.spawner = Spawner.new(self)
    self.toKill = {}

    self.eventQueue = {}
    self.nextEvent = nil
    self:setGameEvents()
end

function Game:defer(item)
    table.insert(self.deferred, item)
end


function Game:setGameEvents()
    local function brickLivesColor(lives)
        local brt = math.random()*0.1 + 0.9
        return {util.lerp(128, 255, lives/5)*brt, util.lerp(240, 128, lives/5)*brt, util.lerp(255, 192, lives/5)*brt, 255}
    end

    local spawnFuncs = {
        balls = {
            regular = function(count, lives)
                for i=1,count or 5 do
                    table.insert(self.balls, Ball.new(self, {lives=lives or 3}))
                end
            end,
            bouncy = function(count,lives)
                for i =1,count or 5 do
                    table.insert(self.balls, Ball.new(self, {
                        r = 4,
                        elasticity = 0.9,
                        color = {255, 255, 128, 255},
                        hitColor = {255, 255, 0, 128},
                        onStart = function(self)
                            Ball.onStart(self)
                            self.ay = 600
                            self.vx = 0
                            self.vy = 0
                        end,
                        lives = lives or 6
                    }))
                end
            end,
            super = function()
                table.insert(self.balls, SuperBall.new(self))
            end
        }, bricks = {
            classic = function()
                local bricks = {}
                local w = 64
                local h = 32
                local top = self.bounds.top + h/2 + h
                local left = self.bounds.left + w/2
                local right = self.bounds.right - w/2
                for row = 0, 7 do
                    local lives = 4 - math.floor(row/2)
                    local y = top + row * h
                    for x = left, right, w do
                        table.insert(bricks, {
                            color = brickLivesColor(lives),
                            x = x, y = y, w = w, h = h, lives = lives
                        })
                    end
                end

                self.spawner:spawn({self.actors, self.toKill}, Brick, bricks, 60/BPM/2, (right - left)/w + 1)
            end,
            staggered = function(rate)
                local bricks = {}
                local w = 64
                local h = 32
                local top = self.bounds.top + h/2 + h
                local left = self.bounds.left + w/2
                local right = self.bounds.right - w/2
                local bottom = top + 10 * h
                for row = 0, 5 do
                    local y = top + row * h
                    local y2 = bottom - (w - top)
                    local last = right
                    if row == 5 then
                        last = (left + right)/2
                    end
                    for x = left - (row  % 2)*w/2, last, w do
                        table.insert(bricks, {
                            color = brickLivesColor(3),
                            x = x, y = y, w = w, h = h, lives = 3
                        })
                        table.insert(bricks, {
                            color = brickLivesColor(1),
                            x = right - (x - left),
                            y = bottom - (y - top),
                            w = w, h = h
                        })
                    end
                end
                self.spawner:spawn({self.actors, self.toKill}, Brick, bricks, 60/BPM/(rate or 8), 2, 0)
            end,
            zigzag = function(zigs, flip)
                local bricks = {}
                local w = 64
                local h = 32
                local top = self.bounds.top + h/2
                local left = self.bounds.left + w/2
                local right = self.bounds.right - w/2

                xstart = left
                xend = right
                xstep = w
                if flip then
                    xstart, xend = xend, xstart
                    xstep = -w
                end

                y = top
                local lives = zigs
                while lives > 0 do
                    for x = xstart, xend, xstep do
                        table.insert(bricks, {
                            color = brickLivesColor(lives),
                            x = x, y = y, w = w, h = h, lives = lives
                        })
                    end

                    xstart, xend = xend, xstart
                    xstep = -xstep
                    lives = lives - 1

                    if lives > 0 then
                        for x = xstart - w*3.5, xend, xstep*5 do
                            table.insert(bricks, {
                                color = brickLivesColor(5),
                                x = x, y = y + 2*h, w = h*2, h = h*2, lives = 5
                            })
                        end

                        nexty = y + 4*h
                        for y = y + h, nexty - 1, h do
                            table.insert(bricks, {
                                color = brickLivesColor(lives),
                                x = xstart, y = y, w = w, h = h, lives = lives
                            })
                        end
                    end
                    y = nexty
                end

                self.spawner:spawn({self.actors, self.toKill}, Brick, bricks, 60/BPM/16, 2)
            end
        }, mobs = {
            randomizer = {
                boss = function()
                    local randomizer = Randomizer.new(self, {
                        spawnInterval = 60/BPM,
                        lives = 20,
                        w = 96,
                        h = 96,
                        sizefuck = 32
                    })
                    table.insert(self.actors, randomizer)
                    table.insert(self.toKill, randomizer)
                end,
                minions = function()
                    local spawns = {}
                    for i=1,3 do
                        table.insert(spawns, {
                            spawnInterval = 180/BPM,
                            lives = 10,
                            xFrequency = 0.7,
                            yFrequency = 6.7,
                            centerX = (i*2 - 1)*1280/6,
                            travelX = 1280/6,
                            score = 65536,
                            w = 64,
                            h = 64,
                            sizefuck = 16
                        })
                    end
                    self.spawner:spawn({self.actors, self.toKill}, Randomizer, spawns, 120/BPM, 1)
                end
            }
        }
    }

    local timeFuncs = {
        judder = function(time)
            local phase, measure, beat = unpack(time)

            -- each group of stabs is on the two-beat boundary
            local offset = beat % 2

            -- and the start of each stab is on 3/4 beats
            local stabOfs = offset % .75

            return 2*(.75 - stabOfs)
        end,
        ramp = function(time)
            local phase, measure, beat = unpack(time)
            return 1.5*(1 - beat % 1)
        end
    }

    self.eventQueue = {
        {
            when = {1},
            what = function()
                spawnFuncs.balls.regular(3, 3)
            end
        },
        {
            when = {2},
            what = function()
                spawnFuncs.balls.bouncy()
            end
        },
        {
            when = {3},
            what = function()
                spawnFuncs.bricks.staggered()

                spawnFuncs.balls.regular()
                spawnFuncs.balls.super()
            end
        },
        {
            when = {4},
            what = function()
                spawnFuncs.bricks.classic()

                spawnFuncs.balls.regular()
                spawnFuncs.balls.super()
            end
            -- spawnFuncs.mobs.aliens()
        },
        {
            when = {5},
            what = function()
                spawnFuncs.bricks.zigzag(3)

                spawnFuncs.balls.regular()
                spawnFuncs.balls.super()
            end
        },
        {
            when = {5,8},
            what = spawnFuncs.mobs.randomizer.boss
        },
        {
            when = {6},
            what = function()
                spawnFuncs.balls.bouncy()
                -- spawnFuncs.mobs.aliens()
                self.timeMapper = timeFuncs.judder
            end
        },
        {
            when = {7},
            what = function()
                spawnFuncs.balls.bouncy()
                spawnFuncs.mobs.randomizer.minions()
                self.timeMapper = timeFuncs.ramp

                --spawnFuncs.bricks.??? - and add its kill list to {7,8}
            end
        },
        {
            when = {7,8},
            what = function()
                spawnFuncs.bricks.zigzag(4)

                --spawnFuncs.mobs.randomizer.aliens()
            end
        },
        {
            when = {8},
            what = function()
                spawnFuncs.balls.regular()
                -- spawnFuncs.bricks.???
                -- spawnFuncs.mobs.aliens()
            end
        },
        {
            when = {9},
            what = function()
                -- spawnFuncs.bricks.???
                self.timeMapper = timeFuncs.judder
            end
        },
        {
            when = {9,8},
            what = function()
            end
            -- spawnFuncs.mobs.aliens()
        },
        {
            when = {10},
            what = function()
                spawnFuncs.bricks.classic()

                spawnFuncs.balls.regular()
                spawnFuncs.balls.bouncy()

                spawnFuncs.mobs.randomizer.boss()
                spawnFuncs.mobs.randomizer.minions()

                -- spawnFuncs.mobs.aliens()

                -- spawn superballs on particular beats
                for _,when in pairs({{10,8}, {10,10}, {10,12}, {10,15}, {10,15,2}}) do
                    table.insert(self.eventQueue, {
                        when = when,
                        what = spawnFuncs.balls.super
                    })
                end
            end
        },
        {
            when = {10,8},
            what = function()
                -- spawnFuncs.mobs.aliens()
            end
        },
        {
            when = {11},
            what = function()
                -- replace all the balls with identical particles
                for _,ball in pairs(self.balls) do
                    local pobj = {lifetime = 0.5}
                    util.applyDefaults(pobj, ball)
                    table.insert(self.particles, SparkParticle.new(pobj))
                end
                self.balls = {}

                -- kill the mobs
                for _,actor in pairs(self.actors) do
                    actor:kill()
                end
            end
        },
    }

    self.nextEvent = {0}
end

function Game:setPhase(phase)
    print("setting phase to " .. phase)

    for _,brick in pairs(self.toKill) do
        brick:kill()
    end
    self.toKill = {}

    if phase == 0 then
        self.music:play()
    end

    self.phase = phase

    for k,v in pairs(self.paddleDefaults) do
        self.paddle[k] = v
    end

    for k,v in pairs(geom.collision_stats) do
        print(k,v)
    end

    self.timeMapper = nil
end

function Game:keypressed(key, code, isrepeat)
    if key == '.' then
        self.spawner.queue = {}
        self:seekMusic(self.phase + 1)
    end
end

function Game:runEvents(time)
    if not self.nextEvent or util.arrayLT(time, self.nextEvent) then
        return
    end

    local removes = {}
    self.nextEvent = nil

    for idx,event in pairs(self.eventQueue) do
        if not util.arrayLT(time, event.when) then
            event.what(unpack(event.args or {}))
            table.insert(removes, idx)
        elseif not self.nextEvent or util.arrayLT(event.when, self.nextEvent) then
            self.nextEvent = event.when
        end
    end
    for _,r in ipairs(removes) do
        self.eventQueue[r] = nil
    end
end

function Game:update(dt)
    local p = self.paddle
    local b = self.bounds

    local time = self:musicPos()
    if self.music:isPlaying() then
        local phase = time[1]
        if phase > self.phase then
            self:setPhase(phase)
        end

        self:runEvents(time)
    end

    local pax = 0
    if love.keyboard.isDown("right") then
        p.vx = p.vx + p.speed*dt
    end
    if love.keyboard.isDown("left") then
        p.vx = p.vx - p.speed*dt
    end
    p.vx = p.vx * math.pow(p.friction, dt)
    p.vy = p.vy * math.pow(p.friction, dt)

    p.x = p.x + dt * p.vx
    p.y = p.y + dt * p.vy

    p.vy = p.vy + dt*(p.restY - p.y)*p.recovery

    if p.x + p.w > b.right then
        p.x = b.right - p.w
        p.vx = -math.abs(p.vx) * p.rebound
    end
    if p.x - p.w < b.left then
        p.x = b.left + p.w
        p.vx = math.abs(p.vx) * p.rebound
    end
    if p.y + p.h > b.bottom then
        p.y = b.bottom - p.h
        p.vy = -math.abs(p.vy) * p.rebound
    end
    if p.y - p.h < b.top then
        p.y = b.top + p.h
        p.vy = math.abs(p.vy) * p.rebound
    end

    p.cachedPoly = nil

    -- TODO: timeline judder

    self.spawner:update(dt)

    local function physicsUpdate(dt)
        local rawt = dt
        if self.timeMapper then
            dt = self.timeMapper(time)*dt
        end

        for _,ball in pairs(self.balls) do

            ball:preUpdate(dt, rawt)

            -- test against walls
            if ball.x - ball.r < self.bounds.left then
                ball:onHitWall({1, 0}, self.bounds.left, ball.y)
            end
            if ball.x + ball.r > self.bounds.right then
                ball:onHitWall({-1, 0}, self.bounds.right, ball.y)
            end
            if ball.y - ball.r < self.bounds.top then
                ball:onHitWall({0, 1}, ball.x, self.bounds.top)
            end
            if ball.y - ball.r > self.bounds.bottom then
                ball:onLost()
                if ball:isAlive() then
                    ball:onStart()
                end
            end

            -- test against paddle (if we're within range)
            if math.abs(ball.x - p.x) < p.w and math.abs(ball.y - p.y) < p.w then
                local c = geom.pointPolyCollision(ball.x, ball.y, ball.r, p:getPolygon())
                if c then
                    ball:onHitPaddle(c, self.paddle)
                end
            end
        end

        for _,actor in pairs(self.actors) do
            actor:preUpdate(dt, rawt)
        end

        for _,actor in pairs(self.actors) do
            local poly
            local bcircle = actor:getBoundingCircle()
            local bx, by, br = unpack(bcircle or {})

            for _,ball in pairs(self.balls) do
                if actor:isTangible(ball) then
                    local boundcheck

                    -- quick check, if bounding radius is available
                    if bcircle then
                        local dx = ball.x - bx
                        local dy = ball.y - by
                        boundcheck = math.sqrt(dx*dx + dy*dy) < ball.r + br

                        -- TODO: fail the bound check if we're moving away as well
                    else
                        boundcheck = true
                    end

                    if boundcheck then
                        if not poly then
                            poly = actor:getPolygon()
                        end
                        nrm = geom.pointPolyCollision(ball.x, ball.y, ball.r, poly)
                        if nrm then
                            actor:onHitBall(nrm, ball)
                        end
                    end
                end
            end
        end

        local function doPostUpdates(cur)
            local removes = {}
            for idx,thing in pairs(cur) do
                thing:postUpdate(dt, rawt)
                if not thing:isAlive() then
                    table.insert(removes, idx)
                end
            end
            for _,r in pairs(removes) do
                cur[r] = nil
            end
        end

        doPostUpdates(self.balls)
        doPostUpdates(self.actors)

        local removes = {}
        for idx,particle in pairs(self.particles) do
            if not particle:update(dt) then
                table.insert(removes, idx)
            end
        end
        for _,r in pairs(removes) do
            self.particles[r] = nil
        end
    end

    for i = 1, 4 do
        -- TODO maybe slide this based on framerate and/or precision issues
        physicsUpdate(dt/4)
    end

    -- experiment: synchronize the balls so that their velocities bring them to the paddle on a beat
    local physicsBeat = math.floor(time[3])
    if self.music:isPlaying() and (physicsBeat ~= self.lastPhysicsBeat) then
        self.lastPhysicsBeat = physicsBeat
        local beatOfs = time[3] - physicsBeat

        local BPS = BPM/60
        local SPB = 60/BPM

        for _,ball in pairs(self.balls) do
            -- if a ball is above the paddle and moving downward...
            if ball.y < p.y and ball.vy > 0 then
                -- p = y + vt + .5at^2, solve for t
                local nextHitDelta, nb = util.solveQuadratic(.5*ball.ay, ball.vy, ball.y - p.y)
                if nextHitDelta < 0 or (nb and nb > 0 and nb < nextHitDelta) then
                    nextHitDelta = nb
                end

                -- how many beats away the next hit will be
                local nextHitCurBeats = nextHitDelta*BPS + beatOfs

                if nextHitCurBeats > 1 then

                    -- how many beats away the next beat should be
                    local nextHitDesiredBeats = math.floor(nextHitCurBeats + 0.5) - beatOfs

                    -- and phrased in time
                    local nt = nextHitDesiredBeats*SPB

                    -- if the new hit is at least one beat away and doesn't change time by more than 25%...
                    if nt >= SPB and math.abs(nt/nextHitDelta - 1) < .95 then
                        print("dt = " .. nextHitDelta .. " -> " .. nt)

                        --[[ y' = y + vt + .5at^2, solve for v:

                            y' - y - .5at^2 = vt
                            v = (y' - y - .5at^2)/t
                        ]]

                        local vy = (p.y - ball.y - .5*ball.ay*nt*nt)/nt
                        -- ball.vx = ball.vx*vy/ball.vy
                        ball.vy = vy
                    end
                end
            end
        end
    end

    for _,item in pairs(self.deferred) do
        item(self)
    end
    self.deferred = {}

    self.layers.water, self.layers.waterBack = util.mapShader(self.layers.water, self.layers.waterBack,
        shaders.waterRipple, {
            psize = {self.waterParams.sampleRadius/1280, self.waterParams.sampleRadius/720},
            damp = self.waterParams.damp,
            fluidity = self.waterParams.fluidity,
            dt = dt*self.waterParams.timeMul
        })
end

function Game:draw()
    self.layers.overlay:renderTo(function()
        love.graphics.clear(0,0,0,0)
    end)

    self.layers.arena:renderTo(function()
        love.graphics.clear(0, 0, 0, 0)

        love.graphics.setBlendMode("alpha")
        -- love.graphics.setColor(10,10,40,80)
        love.graphics.setColor(192, 255, 255, 20)
        love.graphics.rectangle("fill", 0, 0, 1280, self.bounds.top)
        love.graphics.rectangle("fill", 0, self.bounds.top, self.bounds.left, self.bounds.bottom - self.bounds.top)
        love.graphics.rectangle("fill", self.bounds.right, self.bounds.top, 1280 - self.bounds.right, self.bounds.bottom - self.bounds.top)

        -- draw the paddle
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(unpack(self.paddle.color))
        love.graphics.polygon("fill", self.paddle:getPolygon())

        -- draw the actors
        for _,actor in pairs(self.actors) do
            actor:draw()
        end

        -- draw the balls
        for _,ball in pairs(self.balls) do
            ball:draw()
        end

        -- draw the particle effects
        for _,particle in pairs(self.particles) do
            particle:draw()
        end

        love.graphics.setColor(255,255,255,255)
        love.graphics.print("phase=" .. self.phase .. " score=" .. self.score, 0, 0)
    end)

    self.canvas:renderTo(function()
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.clear(0,0,0,0)
        love.graphics.setColor(255, 255, 255, 255)

        love.graphics.setShader(shaders.waterReflect)
        shaders.waterReflect:send("psize", {1.0/1280, 1.0/720})
        shaders.waterReflect:send("rsize", self.waterParams.rsize)
        shaders.waterReflect:send("fresnel", self.waterParams.fresnel);
        shaders.waterReflect:send("source", self.layers.arena)
        shaders.waterReflect:send("bgColor", {0, 0, 0, 0})
        shaders.waterReflect:send("waveColor", {0.1, 0, 0.5, 1})
        love.graphics.draw(self.layers.water)
        love.graphics.setShader()

        love.graphics.draw(self.layers.arena)
        love.graphics.draw(self.layers.overlay)
    end)

    return self.canvas;
    -- return self.layers.water;
end

return Game
