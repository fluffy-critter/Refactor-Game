--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local util = require 'util'
local Actor = require 'track1.Actor'
local HitParticle = require 'track1.HitParticle'

local Brick = {}
setmetatable(Brick, {__index = Actor})

Brick.states = util.enum("spawning", "alive", "hit", "dying", "dead")

function Brick.new(game, o)
    local self = o or {}
    setmetatable(self, {__index = Brick})

    self.game = game
    self:onInit()

    return self
end

function Brick:onInit()
    util.applyDefaults(self, {
        color = {.5, .5, 0, 1},
        spawnTime = 0.1,
        deathTime = 0.2,
        hitTime = 0.1,
        deathColor = {1, 1, 1, 1},
        hitColor = {1, 1, 1, 1},
        lives = 1,
        scoreValue = 100,
        elasticity = 1,
        blendMode = "alpha"
    })

    self.state = Brick.states.spawning
    self.stateAge = 0

    self.game:renderWater(1, function()
        love.graphics.polygon("fill", self:getPolygon())
    end)
end

function Brick:kill()
    if self.state < Brick.states.dying then
        self.stateAge = 0
        self.state = Brick.states.dying
        self.game:renderWater(0, function()
            love.graphics.polygon("fill", self:getPolygon())
        end)
    end
end

function Brick:getAABB()
    if not self.cachedAABB then
        self.cachedAABB = {
            self.x - self.w/2, self.y - self.h/2,
            self.x + self.w/2, self.y + self.h/2
        }
    end
    return self.cachedAABB
end

function Brick:getPolygon()
    if not self.cachedPolygon then
        self.cachedPolygon =  {
            self.x - self.w/2, self.y - self.h/2,
            self.x + self.w/2, self.y - self.h/2,
            self.x + self.w/2, self.y + self.h/2,
            self.x - self.w/2, self.y + self.h/2,
        }
    end
    return self.cachedPolygon
end

function Brick:getBoundingCircle()
    if not self.cachedBoundingCircle then
        self.cachedBoundingCircle = {
            self.x, self.y, math.sqrt((self.w*self.w + self.h*self.h)/4)
        }
    end
    return self.cachedBoundingCircle
end

function Brick:preUpdate(dt)
    self.stateAge = self.stateAge + dt

    if self.state == Brick.states.spawning and self.stateAge >= self.spawnTime then
        self.state = Brick.states.alive
    elseif self.state == Brick.states.hit and self.stateAge >= self.hitTime then
        self.state = Brick.states.alive
    elseif self.state == Brick.states.dying and self.stateAge >= self.deathTime then
        self.state = Brick.states.dead
    end
end

function Brick:isTangible(ball)
    return (self.state == Brick.states.alive or self.state == Brick.states.hit) and not ball.isBullet
end

function Brick:isAlive()
    return self.state ~= Brick.states.dead
end

function Brick:checkHitBalls(balls)
    if self.state ~= Brick.states.alive then
        return
    end

    Actor.checkHitBalls(self, balls)
end

function Brick:onHitBall(nrm, ball)
    if self.state ~= Brick.states.alive then
        return
    end

    self.game.score = self.game.score + self.scoreValue

    self.lives = self.lives - 1
    self.stateAge = 0
    if self.lives == 0 then
        self:kill()
    else
        self.state = Brick.states.hit
        table.insert(self.game.particles, HitParticle.new({
            x = self.x - self.w/2,
            y = self.y - self.h/2,
            w = self.w,
            h = self.h,
            lifetime = self.deathTime,
            color = self.hitColor
        }))
    end

    ball:onHitActor(nrm, self)
end

function Brick:draw()
    love.graphics.setBlendMode(self.blendMode)

    if self.state == Brick.states.spawning then
        love.graphics.setColor(self.color[1], self.color[2], self.color[3],
            (self.color[4] or 1) * self.stateAge / self.spawnTime)
    elseif self.state == Brick.states.alive or self.state == Brick.states.hit then
        love.graphics.setColor(unpack(self.color))
    elseif self.state == Brick.states.dying then
        love.graphics.setColor(self.deathColor[1], self.deathColor[2], self.deathColor[3],
            (self.color[4] or 1) * (1 - self.stateAge / self.spawnTime))
    end

    love.graphics.polygon("fill", self:getPolygon())

    -- TODO draw into ripple layer on spawning
end

return Brick
