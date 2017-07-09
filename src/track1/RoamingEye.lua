--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

RoamingEye - it looks at you piercingly
]]

local geom = require('geom')
local util = require('util')
local shaders = require('shaders')

local Actor = require('track1.Actor')
local StunBullet = require('track1.StunBullet')

local RoamingEye = {}
setmetatable(RoamingEye, {__index = Actor})

RoamingEye.states = util.enum("spawning", "alive", "hit", "dying", "dead")

function RoamingEye.new(game, o)
    local self = o or {}
    setmetatable(self, {__index = RoamingEye})

    self.game = game

    self:onInit()
    return self
end

function RoamingEye:onInit()
    local b = self.game.bounds

    util.applyDefaults(self, {
        lives = 3,
        r = 32,
        ballColor = {128, 255, 255},
        irisColor = {128, 0, 255},
        pupilColor = {0, 0, 0},
        pupilShootColor = {255, 0, 0},
        shootInterval = 4,
        shootChargeTime = 1,
        shootSpeed = 300,
        moveIntervalMin = 2,
        moveIntervalMax = 8,
        moveSpeedMax = 100,
        score = 10000,
        vx = 0,
        vy = 0,
        spawnTime = 0.25,
        hitTime = 0.25,
        hitFlashRate = 1/20,
        deathTime = 0.5,

        friction = 0.05,
        recoil = 5,
        rebound = 50
    })

    util.applyDefaults(self, {
        irisSize = self.r/2.5,
        pupilSize = self.r/3.5,
        minX = b.left + self.r,
        maxX = b.right - self.r,
        minY = b.top + self.r,
        maxY = (b.bottom - b.top)*.75 - self.r
    })

    util.applyDefaults(self, {
        x = math.random(self.minX, self.maxX),
        y = math.random(self.minY, self.maxY)
    })

    self.tgtX = self.x
    self.tgtY = self.y

    self.state = RoamingEye.states.spawning
    self.stateAge = 0
    self.time = 0
    self.nextShot = self.shootInterval
    self.nextMove = 0

    self.lookX = 0
    self.lookY = 0

    self.canvas = love.graphics.newCanvas(self.r*2, self.r*2)
end

function RoamingEye:isAlive()
    return self.state ~= RoamingEye.states.dead
end

function RoamingEye:preUpdate(dt)
    self.stateAge = self.stateAge + dt

    if self.state == RoamingEye.states.spawning and self.stateAge > self.spawnTime then
        self.stateAge = 0
        self.state = RoamingEye.states.alive
    elseif self.state == RoamingEye.states.hit and self.stateAge > self.hitTime then
        self.stateAge = 0
        self.state = RoamingEye.states.alive
        return
    elseif self.state == RoamingEye.states.dying and self.stateAge > self.deathTime then
        self.stateAge = 0
        self.state = RoamingEye.states.dead
    end

    if self.state >= RoamingEye.states.hit then
        return
    end


    self.time = self.time + dt

    if self.time > self.nextMove then
        self.nextMove = self.time + math.random(self.moveIntervalMin, self.moveIntervalMax)
        self.tgtX = math.random(self.minX, self.maxX)
        self.tgtY = math.random(self.minY, self.maxY)
    end

    local mx = (self.tgtX - self.x)*self.friction
    local my = (self.tgtY - self.y)*self.friction
    local mag = math.sqrt(mx*mx + my*my)
    if mag > self.moveSpeedMax then
        mx = mx*self.moveSpeedMax/mag
        my = my*self.moveSpeedMax/mag
    end

    self.vx = self.vx + mx*dt
    self.vy = self.vy + my*dt
end

function RoamingEye:postUpdate(dt)
    self.lookX = self.game.paddle.x - self.x
    self.lookY = self.game.paddle.y - self.y
    self.x = self.x + self.vx
    self.y = self.y + self.vy

    if self.time > self.nextShot then
        local vx, vy = unpack(geom.normalize({self.lookX, self.lookY}, 1))

        self.nextShot = self.time + self.shootInterval
        self.game:defer(function(game)
            table.insert(game.balls, StunBullet.new(game, {
                x = self.x + vx*self.r,
                y = self.y + vy*self.r,
                vx = vx*self.shootSpeed,
                vy = vy*self.shootSpeed,
                parent = self
            }))
        end)

        self.vx = self.vx - vx*self.recoil
        self.vy = self.vy - vy*self.recoil
    end

    local ffactor = math.pow(self.friction, dt)
    self.vx = self.vx*ffactor
    self.vy = self.vy*ffactor
end

function RoamingEye:checkHitBalls(balls)
    if self.state ~= RoamingEye.states.alive then
        return
    end

    for _,ball in pairs(balls) do
        if not ball.isBullet then
            nrm = geom.pointPointCollision(ball.x, ball.y, ball.r, self.x, self.y, self.r)
            if nrm then
                self:onHitBall(nrm, ball)
            end
        end
    end
end

function RoamingEye:onHitBall(nrm, ball)
    if self.state ~= RoamingEye.states.alive then
        return
    end

    ball:onHitActor(nrm, self)
    local nx, ny = unpack(nrm)
    self.vx = self.vx - self.rebound*nx*ball.r*ball.r/self.r/self.r
    self.vy = self.vy - self.rebound*nx*ball.r*ball.r/self.r/self.r

    self.lives = self.lives - 1
    if self.lives < 1 then
        self.state = RoamingEye.states.dying
        self.stateAge = 0
    else
        self.state = RoamingEye.states.hit
        self.stateAge = 0
    end
end

function RoamingEye:draw()
    local px, py = unpack(geom.normalize({self.lookX, self.lookY}, (self.r - self.irisSize)))

    self.canvas:renderTo(function()
        love.graphics.clear(0,0,0,0)

        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(unpack(self.ballColor))
        love.graphics.circle("fill", self.r, self.r, self.r)

        love.graphics.setColor(unpack(self.irisColor))
        love.graphics.circle("fill", self.r + px*0.9, self.r + py*0.9, self.irisSize)
        love.graphics.setColor(unpack(self.pupilColor))
        love.graphics.circle("fill", self.r + px, self.r + py, self.pupilSize)
    end)

    self.game.layers.overlay:renderTo(function()
        local alpha = 255
        if self.state == RoamingEye.states.dying then
            alpha = 255*(1 - self.stateAge/self.deathTime)
        elseif self.state == RoamingEye.states.spawning then
            alpha = 255*self.stateAge/self.spawnTime
        elseif self.state == RoamingEye.states.hit then
            local flash = math.floor(self.stateAge/self.hitFlashRate) % 2
            alpha = 127 + 128*flash
        end

        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setColor(alpha, alpha, alpha, alpha)
        -- love.graphics.setShader(shaders.sphereDistort)
        -- shaders.sphereDistort:send("gamma", 0.9)
        love.graphics.draw(self.canvas, self.x - self.r, self.y - self.r)
        love.graphics.setShader()

        -- TODO charging animation

        love.graphics.setBlendMode("alpha", "alphamultiply")
        if self.state == RoamingEye.states.spawning then
            love.graphics.setColor(255, 255, 255, alpha)
            love.graphics.circle("fill", self.x, self.y, self.r)
        end
    end)
end


return RoamingEye

