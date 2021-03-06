--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

RoamingEye - it looks at you piercingly
]]

local geom = require 'geom'
local util = require 'util'
local shaders = require 'shaders'
local gfx = require 'gfx'
local config = require 'config'

local Actor = require 'track1.Actor'
local StunBullet = require 'track1.StunBullet'

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
        ballColor = {.5,.75,.75},
        irisColor = {.5, 0, .75},
        pupilColor = {0, 0, 0},
        chargeColor = {1, 0, 0, .75},
        shootInterval = 4,
        shootChargeTime = 2,
        shootSpeed = 300,
        shootSpeedIncrement = 50,
        moveIntervalMin = 2,
        moveIntervalMax = 8,
        moveSpeedMax = 3000,
        moveTime = 180/self.game.BPM, -- how long the move should take
        scoreHit = 100,
        scoreDead = 10000,
        vx = 0,
        vy = 0,
        spawnTime = 0.25,
        hitTime = 0.25,
        hitFlashRate = 1/20,
        deathTime = 0.5,

        recoil = 500,
        recovery = 60/self.game.BPM, -- how long to take to recover from an impulse
        rebound = 400,
        friction = 0.9
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
    self.posX = self.x
    self.posY = self.y

    self.state = RoamingEye.states.spawning
    self.stateAge = 0
    self.time = 0
    self.lastMove = 0
    self.nextShot = self.shootInterval
    self.nextMove = 0

    self.lookX = 0
    self.lookY = 0

    self.canvasFormat = gfx.selectCanvasFormat("rgba4", "rgba8", "rgb5a1")

    self:setScale(self.game.scale)

    self.shader = shaders.load("track1/sphereDistort.fs")
end

function RoamingEye:setScale(scale)
    local size = math.ceil(2*scale*self.r)
    self.scale = size/self.r/2

    if self.canvas then
        self.canvas:release()
    end
    self.canvas = love.graphics.newCanvas(size, size, {format=self.canvasFormat, msaa=0})
end

function RoamingEye:isAlive()
    return self.state ~= RoamingEye.states.dead
end

function RoamingEye:preUpdate(dt, rawt)
    self.stateAge = self.stateAge + rawt

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
        self.lastMove = self.time
        self.nextMove = self.time + math.random(self.moveIntervalMin, self.moveIntervalMax)
        self.posX = self.tgtX
        self.posY = self.tgtY
        self.tgtX = math.random(self.minX, self.maxX)
        self.tgtY = math.random(self.minY, self.maxY)
    end

    local ff = math.pow(self.friction, dt)
    self.vx = self.vx*ff
    self.vy = self.vy*ff

    local mag = math.sqrt(self.vx*self.vx + self.vy*self.vy)
    if mag > self.moveSpeedMax then
        self.vx = self.vx*self.moveSpeedMax/mag
        self.vy = self.vy*self.moveSpeedMax/mag
    end

    local pp = util.smoothStep(math.min(1, (self.time - self.lastMove)/self.moveTime))
    local px = self.posX + pp*(self.tgtX - self.posX)
    local py = self.posY + pp*(self.tgtY - self.posY)

    -- p = x + vt + .5at^2, t=recovery, solve for a
    local ax = 2*(px - self.x - self.vx*self.recovery)/(self.recovery*self.recovery)
    local ay = 2*(py - self.y - self.vy*self.recovery)/(self.recovery*self.recovery)

    self.x = self.x + dt*(self.vx + ax*dt/2)
    self.y = self.y + dt*(self.vy + ay*dt/2)
    self.vx = self.vx + dt*ax
    self.vy = self.vy + dt*ay

    return self:isAlive()
end

function RoamingEye:postUpdate(dt)
    if self.state >= RoamingEye.states.hit then
        return
    end

    self.lookX = self.lookX*(1 - dt*10) + (self.game.paddle.x - self.x)*dt*10
    self.lookY = self.lookY*(1 - dt*10) + (self.game.paddle.y - self.y)*dt*10

    if self.time > self.nextShot then
        local vx, vy = unpack(geom.normalize({self.lookX, self.lookY}, 1))

        self.nextShot = self.time + self.shootInterval
        self.game:defer(function(game)
            table.insert(game.balls, StunBullet.new(game, {
                x = self.x + vx*self.r,
                y = self.y + vy*self.r,
                vx = vx*self.shootSpeed,
                vy = vy*self.shootSpeed,
                minVelocity = self.shootSpeed,
                parent = self
            }))
            self.shootSpeed = self.shootSpeed + self.shootSpeedIncrement
            self.vx = self.vx - vx*self.recoil
            self.vy = self.vy - vy*self.recoil
        end)
    end
end

function RoamingEye:getBoundingCircle()
    return {self.x, self.y, self.r}
end

function RoamingEye:getAABB()
    return {self.x - self.r, self.y - self.r, self.x + self.r, self.y + self.r}
end

function RoamingEye:checkHitBalls(balls)
    for _,ball in pairs(balls) do
        if not ball.isBullet then
            local nrm = geom.pointPointCollision(ball.x, ball.y, ball.r, self.x, self.y, self.r)
            if nrm then
                self:onHitBall(nrm, ball)
            end
        end
    end
end

function RoamingEye:kill()
    if self.state < RoamingEye.states.dying then
        self.state = RoamingEye.states.dying
        self.stateAge = 0
    end
end

function RoamingEye:onHitBall(nrm, ball)
    -- keep it immune while balls are passing through it
    if self.state == RoamingEye.states.hit then
        self.stateAge = self.stateAge % (self.hitFlashRate * 2)
    end

    if self.state ~= RoamingEye.states.alive then
        return
    end

    ball:onHitActor(nrm, self)

    local nx, ny = unpack(nrm)
    self.vx = self.vx - self.rebound*nx*ball.r*ball.r/self.r/self.r
    self.vy = self.vy - self.rebound*ny*ball.r*ball.r/self.r/self.r

    self.lives = self.lives - 1
    if self.lives < 1 then
        self.game.score = self.game.score + self.scoreDead
        self:kill()
    else
        self.game.score = self.game.score + self.scoreHit
        self.state = RoamingEye.states.hit
        self.stateAge = 0
    end
end

function RoamingEye:drawPost()
    local px, py = unpack(geom.normalize({self.lookX, self.lookY}))
    local irisR = self.r - self.irisSize
    local chargeTime = self.time - (self.nextShot - self.shootChargeTime)
    local chargeAmount, chargeColor

    if chargeTime >= 0 and chargeTime < self.shootChargeTime then
        chargeAmount = chargeTime/self.shootChargeTime
        chargeColor = {self.chargeColor[1], self.chargeColor[2], self.chargeColor[3], self.chargeColor[4]*chargeAmount}
    end

    self.canvas:renderTo(function()
        love.graphics.push()
        love.graphics.origin()
        love.graphics.scale(self.scale)

        love.graphics.clear(0,0,0,0)

        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(unpack(self.ballColor))

        gfx.circle(true, self.r, self.r, self.r)

        love.graphics.setColor(unpack(self.irisColor))
        gfx.circle(true, self.r + px*0.9*irisR, self.r + py*0.9*irisR, self.irisSize)
        love.graphics.setColor(unpack(self.pupilColor))
        gfx.circle(true, self.r + px*0.9*irisR, self.r + py*0.9*irisR, self.pupilSize)

        if chargeAmount then
            love.graphics.setColor(unpack(chargeColor))
            gfx.circle(true, self.r + px*0.9*irisR, self.r + py*0.9*irisR, self.pupilSize*math.sqrt(chargeAmount))
        end

        love.graphics.pop()
    end)

    self.game.layers.overlay:renderTo(function()
        local alpha = 1
        if self.state == RoamingEye.states.dying then
            alpha = (1 - self.stateAge/self.deathTime)
        elseif self.state == RoamingEye.states.spawning then
            alpha = self.stateAge/self.spawnTime
        elseif self.state == RoamingEye.states.hit then
            local flash = math.floor(self.stateAge/self.hitFlashRate) % 2
            alpha = .5 + .5*flash
        end

        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setColor(alpha, alpha, alpha, alpha)
        local shader = self.shader
        love.graphics.setShader(shader)
        shader:send("env", self.game.canvas)
        shader:send("center", {self.x/1280, self.y/720})
        shader:send("reflectSize", {self.r/128, self.r/72})
        love.graphics.draw(self.canvas, self.x, self.y, 0,
            1/self.scale, 1/self.scale,
            self.r*self.scale, self.r*self.scale)
        love.graphics.setShader()

        if self.state == RoamingEye.states.alive and chargeAmount then
            local chargeFlash = math.floor(chargeTime*chargeTime / 0.2)%2
            if chargeFlash == 0 then
                love.graphics.setBlendMode("add", "alphamultiply")
                love.graphics.setColor(unpack(chargeColor))
                local cx, cy = px*self.r, py*self.r
                local dx, dy = unpack(geom.normalize({-cy, cx}, self.pupilSize/2))
                love.graphics.polygon("fill",
                    self.x + cx + dx, self.y + cy + dy,
                    self.x + cx - dx, self.y + cy - dy,
                    self.x + self.lookX, self.y + self.lookY)
            end
        end

        love.graphics.setBlendMode("alpha", "alphamultiply")
        if self.state == RoamingEye.states.spawning or self.state == RoamingEye.states.dying then
            love.graphics.setColor(1, 1, 1, alpha)
            gfx.circle(true, self.x, self.y, self.r)
        end

        if false and config.debug then
            love.graphics.setColor(0,0,1,alpha)
            love.graphics.line(self.posX, self.posY, self.tgtX, self.tgtY)
            love.graphics.setColor(1,0,0,alpha)
            gfx.circle(false, self.posX, self.posY, 10)
            love.graphics.setColor(0,1,0,alpha)
            gfx.circle(false, self.tgtX, self.tgtY, 10)
        end
    end)
end


return RoamingEye

