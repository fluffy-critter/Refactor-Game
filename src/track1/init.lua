--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local Ball = require 'track1.Ball'
local SuperBall = require 'track1.SuperBall'

local SparkParticle = require 'track1.SparkParticle'

local Randomizer = require 'track1.Randomizer'
local Brick = require 'track1.Brick'
local RoamingEye = require 'track1.RoamingEye'
local FlappyBat = require 'track1.FlappyBat'

local Spawner = require 'track1.Spawner'

local EventQueue = require 'EventQueue'
local QuadTree = require 'QuadTree'
local geom = require 'geom'
local util = require 'util'
local gfx = require 'gfx'
local shaders = require 'shaders'
local input = require 'input'
local config = require 'config'

local Game = {
    META = {
        tracknum = 1,
        title = "little bouncing ball",
        duration = 5*60 + 26,
        description = "bouncing balls",
        genre = "dubstep",
        style = "ball breaker"
    }
}

function Game.new()
    local o = {}
    setmetatable(o, {__index=Game})

    o:init()
    return o
end

local BPM = 132

local clock = util.clock(BPM, {16, 4})

-- returns music position as {phase, measure, beat}. beat will be fractional.
function Game:musicPos()
    return clock.timeToPos(self.music:tell())
end

--[[ seeks the music to a particular spot, using the same format as musicPos(), with an additional
timeOfs param that adjusts it by seconds ]]
function Game:seekMusic(pos, timeOfs)
    self.music:seek(clock.posToTime(pos) + (timeOfs or 0))
end

function Game:resize(w, h)
    -- set the maximum scale factor for the display
    self.maxScale = math.min(w/1280, h/720)
    if not self.scale or self.scale > self.maxScale then
        self:setScale(1)
    end
end

function Game:setScale(scale)
    scale = math.min(scale, self.maxScale)
    local w = math.floor(scale*1280 + 0.5)
    local h = math.floor(w*720/1280)

    -- don't change if we're not adjusting by at least one cadence
    if self.scale then
        local cadence = math.pow(4/3, 0.25)
        if scale/self.scale < cadence and self.scale/scale < cadence then
            return scale
        end
    end

    self.scale = scale

    print("Now rendering at " .. self.scale .. " -> " .. w .. "x" .. h)

    local prevCanvas = self.canvas
    self.canvas = love.graphics.newCanvas(w, h)
    if prevCanvas then
        -- rescale the old canvas so we can preserve the realtime-ish reflections
        self.canvas:renderTo(function()
            love.graphics.setBlendMode("replace")
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(prevCanvas, 0, 0, 0, w/prevCanvas:getWidth(), h/prevCanvas:getHeight())
        end)
        prevCanvas:release()
    end

    local limits = love.graphics.getSystemLimits()
    local pixelfmt = gfx.selectCanvasFormat("rgba8", "rgba4", "rgb5a1")

    for _,layer in pairs(self.layers) do
        layer:release()
    end

    local msaa = math.min(config.msaa or limits.canvasmsaa, limits.canvasmsaa)
    self.layers.arena = love.graphics.newCanvas(w, h, { format = pixelfmt, msaa = msaa })
    self.layers.overlay = love.graphics.newCanvas(w, h, { format = pixelfmt })

    local tonemapFmt = gfx.selectCanvasFormat("rgba8")
    if tonemapFmt then
        self.layers.toneMap = love.graphics.newCanvas(w, h, { format = tonemapFmt })
        self.shaders.gaussToneMap = shaders.load("shaders/gaussToneMap.fs")
        self.shaders.gaussBlur = shaders.load("shaders/gaussBlur.fs")
    end

    for _,actor in ipairs(self.actors) do
        if actor.setScale then
            actor:setScale(self.scale)
        end
    end

    return self.scale
end

function Game:init()
    self.BPM = BPM
    self.syncBeats = true -- try to synchronize ball paddle bounces to beats

    self.music = love.audio.newSource('track1/01-little-bouncing-ball.mp3', 'static')
    self.phase = -1
    self.score = 0


    self.layers = {}
    self.water = {}
    self.shaders = {}

    -- water always renders at 720p
    local waterFormat = gfx.selectCanvasFormat("rgba16f", "rg32f", "rgba32f")
    if waterFormat then
        self.water = {
            front = love.graphics.newCanvas(1280, 720, { format = waterFormat }),
            back = love.graphics.newCanvas(1280, 720, { format = waterFormat }),
            params = {
                fluidity = 1.5,
                damp = 0.913,
                timeStep = 15,
                rsize = 32,
                fresnel = 0.1,
                sampleRadius = 5.5,
            }
        }
        self.shaders.waterRipple = shaders.load("track1/waterRipple.fs")
        self.shaders.waterReflect = shaders.load("track1/waterReflect.fs")
    end

    self.quadtree = QuadTree.new({left = 1280/2 - 1024, right = 1280/2 + 1024, top = 512 - 1024, bottom = 512 + 1024})
    self.buckets = {}

    self.bounds = {
        left = 32,
        right = 1280 - 32,
        top = 32,
        bottom = 720
    }

    self.paddleDefaults = {
        color = {1, 1, 1, 1},

        w = 60,
        h = 6,

        speed = 12000,
        friction = 0.0015,
        rebound = 0.5,
        tiltFactor = 0.01,
        recoil = 1,
        recovery = 1,
        restY = 660,

    }

    -- TODO - make it an actor? or at least factor out into a class
    self.paddle = {
        x = 1280 / 2,
        y = 660,
        vx = 0,
        vy = 0,
        stunned = 0,
        stunFlashInterval = 1/30,
    }

    function self.paddle:tiltVector()
        local x = self.vx * self.tiltFactor
        local y = -60
        local d = math.sqrt(x * x + y * y)
        return { x / d, y / d }
    end

    function self.paddle:getPolygon()
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
    end

    function self.paddle:stun(time)
        if self.stunned > 0 then
            -- If we're already stunnned, only increase it to up to half of the new stun's length
            self.stunned = math.max(self.stunned, time/2)
        else
            self.stunned = time
        end
    end

    util.applyDefaults(self.paddle, self.paddleDefaults)

    self.particles = {}
    self.actors = {}

    -- initialize with the starter ball
    self.starterBall = Ball.new(self, {
        r = 10,
        color = {.5, 1, 1, 1},
        lives = 3,
        hitColor = {0, .5, 1, 1},
        ay = 30,
        minVelocity = 0,
        preUpdate = function(ball, dt)
            Ball.preUpdate(ball, dt)
            ball.vx = ball.vx + dt*(self.paddle.x - ball.x)
            ball.vy = ball.vy + dt*(self.paddle.y - ball.y)
        end,
        onHitPaddle = function(ball, nrm, paddle)
            ball.minVelocity = 50
            ball.preUpdate = Ball.preUpdate
            ball.onHitPaddle = Ball.onHitPaddle
            ball.onStart = Ball.onStart
            ball:onHitPaddle(nrm, paddle)
            self:setPhase(0)
        end,
        onStart = function(ball)
            Ball.onStart(ball)
            ball.vx = 0
            ball.vy = 0
        end,
        onLost = function(ball)
            ball.ay = math.min(ball.ay + 30, 150)
        end
    })

    self.balls = {self.starterBall}

    self.deferred = {}

    self.spawner = Spawner.new(self)
    self.toKill = {}

    self.eventQueue = EventQueue.new()
    self.scoreFont = love.graphics.newImageFont("fonts/centurygothic-digits.png", "0123456789")
    self.debugFont = love.graphics.newFont(12)
end

function Game:start()
    self:setGameEvents()
end

function Game:defer(item)
    table.insert(self.deferred, item)
end

function Game:addEvent(event)
    self.eventQueue:insert(event)
end

function Game:setGameEvents()
    local function brickLivesColor(lives)
        local brt = math.random()*0.1 + 0.9
        return {
            util.lerp(.5, 1, lives/5)*brt,
            util.lerp(.9, .5, lives/5)*brt,
            util.lerp(1, .75, lives/5)*brt,
            1
        }
    end

    local spawnFuncs = {
        balls = {
            regular = function(count, lives)
                for _=1,count or 5 do
                    table.insert(self.balls, Ball.new(self, {lives=lives or 3}))
                end
            end,
            bouncy = function(count,lives)
                for _=1,count or 5 do
                    table.insert(self.balls, Ball.new(self, {
                        r = 4,
                        elasticity = 0.9,
                        color = {1, 1, .5, 1},
                        hitColor = {1, 1, 0, .5},
                        beatSync = 0.5,
                        onStart = function(ball)
                            Ball.onStart(ball)
                            ball.ay = 600
                            ball.vx = 0
                            ball.vy = 0
                        end,
                        lives = lives or 6
                    }))
                end
            end,
            super = function()
                table.insert(self.balls, SuperBall.new(self, {}))
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

                local xstart = left
                local xend = right
                local xstep = w
                if flip then
                    xstart, xend = xend, xstart
                    xstep = -w
                end

                local y = top
                local nexty

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
                        for by = y + h, nexty - 1, h do
                            table.insert(bricks, {
                                color = brickLivesColor(lives),
                                x = xstart, y = by, w = w, h = h, lives = lives
                            })
                        end
                    end
                    y = nexty
                end

                self.spawner:spawn({self.actors, self.toKill}, Brick, bricks, 60/BPM/16, 2)
            end,
            zagzig = function(rows, spacing, killList)
                local bricks = {}
                local w = 32
                local h = 32
                local top = self.bounds.top + h
                local left = self.bounds.left + w
                local right = self.bounds.right - w
                local bottom = top + rows*h

                local startY, endY = bottom, top
                local stepY = -1

                for col = left, right, spacing*w do
                    table.insert(bricks, {
                        color = brickLivesColor(4),
                        x = col,
                        y = startY,
                        w = w*2,
                        h = h*2,
                        lives = 4
                    })

                    for y = startY + stepY*3*h/2, endY - stepY*3*h/2, stepY*h do
                        table.insert(bricks, {
                            color = brickLivesColor(1),
                            x = col,
                            y = y,
                            w = w,
                            h = h,
                            lives = 1
                        })
                    end

                    table.insert(bricks, {
                        color = brickLivesColor(4),
                        x = col,
                        y = endY,
                        w = w*2,
                        h = h*2,
                        lives = 4
                    })

                    startY, endY, stepY = endY, startY, -stepY

                    for x = col + w*3/2, math.min(right, col + w*spacing - w*3/2), w do
                        table.insert(bricks, {
                            color = brickLivesColor(1),
                            x = x,
                            y = startY,
                            w = w,
                            h = h,
                            lives = 1
                        })
                    end
                end

                self.spawner:spawn({self.actors, self.toKill, killList}, Brick, bricks, 30/BPM/16, 1)
            end
        }, mobs = {
            randomizer = {
                boss = function()
                    local randomizer = Randomizer.new(self, {
                        spawnInterval = 60/BPM,
                        lives = 20,
                        w = 96,
                        h = 96,
                        sizefuck = 32,
                        scoreDead = 65536,
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
                            scoreDead = 1024,
                            w = 64,
                            h = 64,
                            sizefuck = 16
                        })
                    end
                    self.spawner:spawn({self.actors, self.toKill}, Randomizer, spawns, 120/BPM, 1)
                end
            },
            eyes = {
                minions = function(count, kill)
                    local spawns = {}
                    for _ = 1,count do
                        table.insert(spawns, {
                            r = 32,
                            lives = 5,
                            shootInterval = 5,
                            scoreDead = 1000
                        })
                    end
                    self.spawner:spawn({self.actors, kill and self.toKill}, RoamingEye, spawns, 30/BPM, 1)
                end,
                boss = function()
                    local eye = RoamingEye.new(self, {
                        r = 64,
                        lives = 20,
                        shootInterval = 120/BPM,
                        moveIntervalMin = 120/BPM,
                        moveIntervalMax = 240/BPM,
                        hitTime = 60/BPM,
                        scoreDead= 5000
                    })
                    table.insert(self.actors, eye)
                    table.insert(self.toKill, eye)
                    -- TODO shieldballs
                end,
            },
            flappyBat = function(count, kill)
                local spawns = {}
                for _ = 1,count do
                    table.insert(spawns, {})
                end
                self.spawner:spawn({self.actors, kill and self.toKill}, FlappyBat, spawns, 30/BPM, 1)
            end,
        }
    }

    local timeFuncs = {
        judder = function(time)
            local _, _, beat = unpack(time)

            -- each group of stabs is on the two-beat boundary
            local offset = beat % 2

            -- and the start of each stab is on 3/4 beats
            local stabOfs = offset % .75

            return 1.5*(.75 - stabOfs) + .5
        end,
        ramp = function(time)
            local _, _, beat = unpack(time)
            return 1.5*(1 - beat % 1)
        end
    }

    self.eventQueue:insert(
        {
            when = {0},
            what = function()
                -- Test new things here!
            end
        },
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
            when = {2,8},
            what = function()
                spawnFuncs.mobs.flappyBat(4)
            end
        },
        {
            when = {3},
            what = function()
                spawnFuncs.bricks.staggered()

                spawnFuncs.balls.regular(2, 2)
                spawnFuncs.balls.super()

                spawnFuncs.mobs.eyes.minions(3)
            end
        },
        {
            when = {3,8},
            what = function()
                spawnFuncs.balls.bouncy()
                -- spawnFuncs.mobs.flappyBat(3)
            end
        },
        {
            when = {4},
            what = function()
                spawnFuncs.bricks.classic()

                spawnFuncs.balls.regular(1,3)
                spawnFuncs.balls.super()

                spawnFuncs.mobs.eyes.minions(3)
            end
        },
        {
            when = {5},
            what = function()
                self.starterBall.ay = math.min(self.starterBall.ay, 60)

                spawnFuncs.bricks.zigzag(4)

                spawnFuncs.balls.regular(1,3)
                spawnFuncs.balls.super()
            end
        },
        {
            when = {5,8},
            what = function()
                spawnFuncs.mobs.randomizer.boss()
                spawnFuncs.balls.bouncy()
            end
        },
        {
            when = {6},
            what = function()
                spawnFuncs.balls.bouncy(3,5)
                spawnFuncs.mobs.eyes.minions(6, true)
                self.timeMapper = timeFuncs.judder
            end
        },
        {
            when = {6,8},
            what = function()
                spawnFuncs.mobs.flappyBat(4, true)
                spawnFuncs.balls.bouncy(3,2)
                spawnFuncs.balls.regular(3,2)
            end
        },
        {
            when = {7},
            what = function()
                spawnFuncs.balls.bouncy(1,3)
                spawnFuncs.mobs.randomizer.minions()
                self.timeMapper = timeFuncs.ramp

                local killList = {}
                spawnFuncs.bricks.zagzig(10, 5, killList)
                self:addEvent({
                    when = {7,8},
                    what = function()
                        for _,brick in ipairs(killList) do
                            brick:kill()
                        end
                    end
                })
            end
        },
        {
            when = {7,8},
            what = function()
                spawnFuncs.bricks.zigzag(4)

                spawnFuncs.balls.regular(3,1)

                spawnFuncs.mobs.eyes.minions(5, true)
                spawnFuncs.mobs.eyes.boss()
            end
        },
        {
            when = {8},
            what = function()
                spawnFuncs.balls.regular(3, 1)
                spawnFuncs.balls.super()

                spawnFuncs.bricks.zagzig(12, 4)

                spawnFuncs.mobs.eyes.minions(3, true)
            end
        },
        {
            when = {8,8},
            what = function()
                spawnFuncs.mobs.flappyBat(4, true)
            end
        },
        {
            when = {9},
            what = function()
                self.starterBall.ay = math.min(self.starterBall.ay, 50)

                spawnFuncs.balls.regular(3, 1)
                spawnFuncs.bricks.zigzag(4)
                self.timeMapper = timeFuncs.judder
            end
        },
        {
            when = {9,8},
            what = function()
                spawnFuncs.balls.regular(3, 1)
                spawnFuncs.bricks.zagzig(11, 5)
                spawnFuncs.mobs.flappyBat(4)
            end
        },
        {
            when = {10},
            what = function()
                self.starterBall.ay = math.min(self.starterBall.ay, 50)

                spawnFuncs.bricks.classic()

                -- spawnFuncs.balls.regular()
                spawnFuncs.balls.bouncy(5,1)

                spawnFuncs.mobs.randomizer.boss()
                spawnFuncs.mobs.randomizer.minions()

                spawnFuncs.mobs.eyes.minions(3)

                -- spawn superballs on particular beats
                for _,when in pairs({{10,8}, {10,10}, {10,12}, {10,15}, {10,15,2}}) do
                    self:addEvent({
                        when = when,
                        what = spawnFuncs.balls.super
                    })
                end
            end
        },
        {
            when = {10,8},
            what = function()
                spawnFuncs.mobs.eyes.minions(3)
                spawnFuncs.mobs.eyes.boss()
            end
        }
    )
end

function Game:setPhase(phase)
    print("setting phase to " .. phase)

    for _,actor in pairs(self.toKill) do
        actor:kill()
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
    geom.collision_stats = {}

    self.timeMapper = nil
end

function Game:onButtonPress(button)
    if button == 'skip' then
        print("tryin' ta skip")
        self.spawner.queue = {}
        self:seekMusic({self.phase + 1})
    end
end

function Game:update(raw_dt)
    local p = self.paddle
    local b = self.bounds

    local time = self:musicPos()
    if self.music:isPlaying() then
        local phase = time[1]
        if phase > self.phase then
            self:setPhase(phase)
        end

        self.eventQueue:run(time)
    end

    if self.phase >= 11 then
        --[[
            The game is over, but because EventQueue events don't necessarily execute in order, we can't
            just do a final cull when phase 11 starts. Thus, as soon as we hit phase 11, we just keep on
            repeatedly culling everything until the game's over.
        ]]

        -- replace all the balls with identical particles
        for _,ball in pairs(self.balls) do
            local pobj = {lifetime = 0.5}
            util.applyDefaults(pobj, ball)
            table.insert(self.particles, SparkParticle.new(pobj))
        end
        self.balls = {}

        -- kill the mobs
        self.spawner:kill()
        self.deferred = {}
        for _,actor in pairs(self.actors) do
            actor:kill()
        end

        if time[2] >= 2 or not self.music:isPlaying() then
            self.gameOver = true
        end
    end

    self.spawner:update(raw_dt)

    local function physicsUpdate(dt)
        local frictionX = p.friction
        if util.sign(p.vx) == -util.sign(input.x) then
            frictionX = math.pow(p.friction, 10)
        end

        p.vx = p.vx * math.pow(frictionX, dt)
        p.vy = p.vy * math.pow(p.friction, dt)

        if p.stunned > 0 then
            p.stunned = p.stunned - dt
        else
            p.vx = p.vx + p.speed*dt*input.x
        end

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

        local rawt = dt
        if self.timeMapper then
            dt = self.timeMapper(time)*dt
        end

        local paddlePoly = p:getPolygon()
        local paddleR = math.sqrt(p.w*p.w + p.h*p.h)
        local paddleAABB = geom.getAABB(paddlePoly)

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

            -- test against paddle
            if geom.pointAABBCollision(ball.x, ball.y, ball.r, paddleAABB)
            and geom.pointPointCollision(ball.x, ball.y, ball.r, p.x, p.y, paddleR)
            then
                local c = geom.pointPolyCollision(ball.x, ball.y, ball.r, paddlePoly)
                if c then
                    ball:onHitPaddle(c, self.paddle)
                end
            end
        end

        for _,actor in pairs(self.actors) do
            local updated = actor:preUpdate(dt, rawt)
            local prev = self.buckets[actor]

            if updated or not prev then
                local quad = actor:getAABB()
                local node = self.quadtree:find(quad)
                if node ~= prev then
                    if prev then prev:remove(actor) end
                    if node then node:insert(actor) end
                    self.buckets[actor] = node
                end
            end
        end

        local actorThreats = {}
        for _,ball in ipairs(self.balls) do
            local ballBound = ball:getAABB()
            self.quadtree:visit(ballBound, function(item)
                actorThreats[item] = (actorThreats[item] or {})
                table.insert(actorThreats[item], ball)
            end)
        end
        for actor,balls in pairs(actorThreats) do
            actor:checkHitBalls(balls)
        end

        local function doPostUpdates(cur)
            util.runQueue(cur, function(thing)
                thing:postUpdate(dt, rawt)
                if not thing:isAlive() then
                    -- remove from the quadtree
                    if self.buckets[thing] then
                        self.buckets[thing]:remove(thing)
                    end
                    return true
                else
                    return false
                end
            end)
        end

        doPostUpdates(self.balls)
        doPostUpdates(self.actors)

        util.runQueue(self.particles, function(particle)
            return not particle:update(dt)
        end)
    end

    for _ = 1, 8 do
        -- TODO maybe slide this based on framerate and/or precision issues
        physicsUpdate(raw_dt/8)
    end

    -- experiment: synchronize the balls so that their velocities bring them to the paddle on a beat
    local physicsBeat = math.floor(time[3]*4)
    if self.syncBeats and self.music:isPlaying() and (physicsBeat ~= self.lastPhysicsBeat) and not self.timeMapper then
        self.lastPhysicsBeat = physicsBeat

        local BPS = BPM/60
        local SPB = 60/BPM

        for _,ball in pairs(self.balls) do
            -- if a ball is above the paddle and moving downward...
            local targetY = p.y - p.h/2 - ball.r
            if ball.y < targetY and ball.vy > 0 then
                -- p = y + vt + .5at^2, solve for t
                local nextHitDelta, nb = util.solveQuadratic(.5*ball.ay, ball.vy, ball.y - targetY)
                if not nextHitDelta or nextHitDelta < 0 or (nb and nb > 0 and nb < nextHitDelta) then
                    nextHitDelta = nb
                end

                local deltaBeats
                if nextHitDelta then
                    local beatOfs = time[3]/ball.beatSync % 1
                    deltaBeats = nextHitDelta*BPS/ball.beatSync

                    -- round this to the nearest beat, after taking off the beatOfs
                    deltaBeats = math.floor(deltaBeats + beatOfs + 0.25) - beatOfs
                end

                if deltaBeats and deltaBeats > .5 then
                    -- new time before next hit
                    local deltaTime = deltaBeats*SPB*ball.beatSync

                    -- print("dt = " .. nextHitDelta .. " -> " .. deltaTime)

                    -- p = y + vt + .5at^2, solve for v
                    local vy = ball.vy*.75 + .25*((targetY - ball.y)/deltaTime - .5*ball.ay*deltaTime)
                    if vy/ball.vy < 1.5 then
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

    if self.water.params then
        self.water.front, self.water.back = util.mapShader(self.water.front, self.water.back,
            self.shaders.waterRipple, {
                psize = {self.water.params.sampleRadius/1280, self.water.params.sampleRadius/720},
                damp = self.water.params.damp,
                fluidity = self.water.params.fluidity,
                dt = self.water.params.timeStep*math.min(raw_dt, 1/30)
            })
    end
end

function Game:draw()
    self.layers.overlay:renderTo(function()
        love.graphics.clear(0,0,0,0)
    end)

    love.graphics.scale(self.scale)

    self.layers.arena:renderTo(function()
        love.graphics.clear(0, 0, 0, 0)

        love.graphics.setBlendMode("alpha")
        -- love.graphics.setColor(10,10,40,80)

        love.graphics.setColor(.75, 1, 1, .08)
        love.graphics.rectangle("fill", 0, 0, 1280, self.bounds.top)
        love.graphics.rectangle("fill", 0, self.bounds.top, self.bounds.left, self.bounds.bottom - self.bounds.top)
        love.graphics.rectangle("fill", self.bounds.right, self.bounds.top,
            1280 - self.bounds.right, self.bounds.bottom - self.bounds.top)

        -- draw the paddle
        local p = self.paddle
        love.graphics.setBlendMode("alpha")
        if p.stunned > 0 and math.floor(p.stunned/p.stunFlashInterval) % 2 == 0 then
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], .5)
        else
            love.graphics.setColor(unpack(p.color))
        end
        love.graphics.polygon("fill", p:getPolygon())

        -- love.graphics.line(0, self.paddle.y, 1280, self.paddle.y)

        if false and config.debug then
            local function drawQuadTree(tree)
                love.graphics.rectangle("line", tree.left, tree.top, tree.right - tree.left, tree.bottom - tree.top)
                for _,child in pairs(tree.children) do
                    drawQuadTree(child)
                end
            end
            drawQuadTree(self.quadtree)
        end

        -- draw the actors
        for _,actor in pairs(self.actors) do
            actor:draw()
            if config.debug then
                local node = self.buckets[actor]
                if node then
                    love.graphics.rectangle("line", node.left, node.top, node.right - node.left, node.bottom - node.top)
                    love.graphics.line(actor.x, actor.y, node.cx, node.cy)
                else
                    local circle = actor:getBoundingCircle()
                    if circle then
                        love.graphics.setColor(1,0,0)
                        love.graphics.circle("line", unpack(circle))
                    end
                end
            end
        end

        -- draw the balls
        for _,ball in pairs(self.balls) do
            ball:draw()
        end

        -- draw the particle effects
        for _,particle in pairs(self.particles) do
            particle:draw()
        end

        -- draw post-effects
        for _,actor in pairs(self.actors) do
            actor:drawPost()
        end
    end)

    love.graphics.origin()

    self.canvas:renderTo(function()
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.clear(0,0,0,1)
        love.graphics.setColor(1,1,1,1)

        if self.water.params then
            local shader = self.shaders.waterReflect
            love.graphics.setShader(shader)
            shader:send("psize", {1.0/1280, 1.0/720})
            shader:send("rsize", self.water.params.rsize)
            shader:send("fresnel", self.water.params.fresnel);
            shader:send("source", self.layers.arena)
            shader:send("bgColor", {-0.1, 0, 0, 0})
            shader:send("waveColor", {0.1, 0.3, 0.75, 1})
            love.graphics.draw(self.water.front, 0, 0, 0, self.scale, self.scale)
            love.graphics.setShader()
        end

        love.graphics.draw(self.layers.arena)
        love.graphics.draw(self.layers.overlay)

        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(1,1,1,1)
        love.graphics.setFont(self.scoreFont)
        love.graphics.scale(self.scale)
        love.graphics.print(self.score, 0, 0)

        if config.debug then
            love.graphics.setFont(self.debugFont)
            love.graphics.print(self.canvas:getWidth() .. ' ' .. self.canvas:getHeight(), 512, 0)
            love.graphics.print(table.concat(self:musicPos(),':'), 0, 720 - 16)
        end

        love.graphics.origin()
    end)

    if self.layers.toneMap then
        util.mapShader(self.canvas, self.layers.toneMap,
            self.shaders.gaussToneMap, {
                sampleRadius = {1/1280, 0},
                lowCut = {0.7,0.7,0.7,0.7},
                gamma = 4
            })
        self.canvas:renderTo(function()
            love.graphics.setBlendMode("add", "premultiplied")
            love.graphics.setColor(.75, .75, .75, .75)
            love.graphics.setShader(self.shaders.gaussBlur)
            self.shaders.gaussBlur:send("sampleRadius", {0, 1/720})
            love.graphics.draw(self.layers.toneMap)
            love.graphics.setShader()
        end)
    end

    return self.canvas
    -- return self.water.front;
    -- return self.layers.toneMap
end

function Game:renderWater(val, f)
    if self.water.front then
        self.water.front:renderTo(function()
            love.graphics.setColorMask(true, false, false, false)
            love.graphics.setColor(val,1,1)
            f()
            love.graphics.setColorMask(true, true, true, true)
        end)
    end
end

return Game
