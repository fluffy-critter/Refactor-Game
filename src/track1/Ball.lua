--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Ball - a ball-type actor

Properties:

    r: radius
    x, y: position
    vx, vy: velocity
    ax, ay: acceleration

    paddleScore: score for touching the paddle
    paddleScoreInc: increment for each time the paddle gets touched

    spawnVelocity: velocity at spawn time
    elasticity: how much rebound force the ball gets
    recoil: how much rebound force the paddle gets
    minVelocity: the minimum velocity for the ball (if we drop below this we get kicked to spawnVelocity)

    dx, dy: position impulse (reset every frame)
    dvx, dvy: velocity impulse (reset every frame)

    color: render color, for default draw method
    hitColor: hit particle color

    lives: number of times it can be lost

    scoreCooldown: how long to wait from the last paddle hit before it becomes eligible for scoring again

    isBullet: it is a bullet, and thus actors shouldn't respond to it (unless they want to)
    parent: reference to the actor that spawned it, if applicable

    beatSync: what increment of beats to synchronize to

Methods:

    onInit() - called when the ball is first initialized
    onStart() - called when the ball's life starts

    preUpdate(dt) - called at the beginning of the update cycle.
        Clears impulses; extenders should call Ball.preUpdate(self,dt)
    postUpdate(dt) - called at the end of the update cycle.
        Applies impulses; extenders should call Ball.postUpdate(self,dt)

    onHitPaddle(nrm, paddle) - called when the ball hits a paddle
    onHitWall(nrm, x, y) - called when the ball hits a wall
    onHitActor(nrm, actor) - called BY THE ACTOR when the ball hits it
    onLost() - called when the ball is lost from the arena

    isAlive() - returns whether the ball is still alive

    applyReflection(nrm, vx, vy) - apply a surface normal reflection to our velocity, with optional velocity offset

    draw() - render the ball

    applyImpulse(dx, dy, dvx, dvy) - apply an impulse to the ball, in terms of displacement and delta-V

]]

local HitParticle = require('track1.HitParticle')
local util = require('util')
local geom = require('geom')
local imagepool = require('imagepool')

local Ball = {}

function Ball.new(game, o)
    local self = o or {}
    setmetatable(self, {__index = Ball})

    self.game = game
    self:onInit()
    self:onStart()

    return self
end

function Ball:onInit()
    util.applyDefaults(self, {
        r = 6,
        color = {255, 192, 192, 255},
        hitColor = {255, 64, 64, 192},
        vx = 0,
        vy = 0,
        ax = 0,
        ay = 0,
        spawnVelocity = 240,
        lives = 1,
        elasticity = 1,
        paddleScore = 1,
        paddleScoreInc = 1,
        scoreCooldown = 0.5,
        recoil = 0,
        minVelocity = 1280*self.game.BPM/360, -- cover the screen width in 6 beats
        blendMode = "alpha",
        beatSync = 1
    })

    self.paddleScoreVal = self.paddleScore
    self.timeSinceLastHit = 0

    self.fillImage = imagepool.load('images/circlefill.png', {mipmaps = true})
    self.ringImage = imagepool.load('images/circlehollow.png', {mipmaps = true})
end

function Ball:onStart()
    self.x = math.random(self.game.bounds.left + self.r, self.game.bounds.right - self.r)
    self.y = math.random(self.game.bounds.top + self.r, (self.game.bounds.top + self.game.bounds.bottom)/2)
    self.vx, self.vy = unpack(geom.randomVector(self.spawnVelocity))

    self.paddleScoreVal = self.paddleScore
    self.timeSinceLastHit = 0
end

function Ball:preUpdate(dt)
    self.dx = 0
    self.dy = 0
    self.dvx = 0
    self.dvy = 0
    self.dcount = 0
    self.hasImpulsed = false

    self.timeSinceLastHit = self.timeSinceLastHit + dt
end

function Ball:postUpdate(dt)
    if self.dcount > 0 then
        self.x = self.x + self.dx/self.dcount
        self.y = self.y + self.dy/self.dcount
        self.vx = self.vx + self.dvx/self.dcount
        self.vy = self.vy + self.dvy/self.dcount
    end

    if self.minVelocity and self.ax == 0 and self.ay == 0 then
        local vv = geom.vectorLength({self.vx, self.vy})
        if vv < self.minVelocity then
            -- print("kicking ball from " .. vv .. " to " .. self.minVelocity)
            local tvx, tvy
            if vv == 0 then
                tvx, tvy = unpack(geom.randomVector(self.spawnVelocity))
            else
                local factor = self.minVelocity/vv
                tvx = self.vx*factor
                tvy = self.vy*factor
            end

            self.vx = self.vx*(1 - dt) + tvx*dt
            self.vy = self.vy*(1 - dt) + tvy*dt
        end
    end

    self.x = self.x + self.vx*dt + self.ax*dt*dt/2
    self.y = self.y + self.vy*dt + self.ay*dt*dt/2
    self.vx = self.vx + self.ax*dt
    self.vy = self.vy + self.ay*dt
end

function Ball:onHitPaddle(nrm, paddle)
    local nx, ny = unpack(nrm)

    self:applyReflection(nrm, paddle.vx, paddle.vy, true)

    if self.timeSinceLastHit > self.scoreCooldown then
        self.game.score = self.game.score + self.paddleScoreVal
        self.paddleScoreVal = self.paddleScoreVal + self.paddleScoreInc

        paddle.vx = paddle.vx - self.recoil * nx * paddle.recoil
        paddle.vy = paddle.vy - self.recoil * ny * paddle.recoil

    end
    self.timeSinceLastHit = 0
end

--[[
    nrm: surface normal of the wall
    x, y: location of the impact
]]
function Ball:onHitWall(nrm, x, y)
    self:applyReflection(nrm, 0, 0, true)

    local nx, ny = unpack(nrm)

    local particles = self.game.particles
    local w = math.abs(ny)*self.r*4 + 2
    local h = math.abs(nx)*self.r*4 + 2
    table.insert(particles, HitParticle.new({
        x = x - w/2,
        y = y - h/2,
        w = w,
        h = h,
        color = self.hitColor,
        lifetime = 0.3
    }))
end

function Ball:onHitActor(nrm, _)
    self:applyReflection(nrm)
end

function Ball:onLost()
    self.lives = self.lives - 1
end

function Ball:isAlive()
    return self.lives > 0
end

function Ball:applyReflection(nrm, vx, vy, immediate)
    vx = vx or 0
    vy = vy or 0

    -- relative velocity
    local rvx = self.vx - vx
    local rvy = self.vy - vy

    local nx, ny = unpack(nrm)

    -- calculate the perpendicular projection of our reversed velocity vector onto the reflection normal
    local mag2 = nx*nx + ny*ny
    local dot = nx*rvx + ny*rvy
    local px = -nx*dot/mag2
    local py = -ny*dot/mag2

    self:applyImpulse(nx, ny, (1 + self.elasticity)*px, (1 + self.elasticity)*py, immediate)
end

function Ball:applyImpulse(dx, dy, dvx, dvy, immediate)
    self.hasImpulsed = true

    if immediate then
        self.x = self.x + dx
        self.y = self.y + dy
        self.vx = self.vx + dvx
        self.vy = self.vy + dvy
    else
        self.dx = self.dx + dx
        self.dy = self.dy + dy
        self.dvx = self.dvx + dvx
        self.dvy = self.dvy + dvy
        self.dcount = self.dcount + 1
    end
end

function Ball:draw()
    love.graphics.setBlendMode(self.blendMode)
    love.graphics.setColor(unpack(self.color))
    love.graphics.draw(self.fillImage, self.x, self.y, 0, self.r/64, self.r/64, 64, 64)

    if self.isBullet then
        love.graphics.draw(self.ringImage, self.x, self.y, 0, (self.r + 3)/64, (self.r + 3)/64, 64, 64)
    end
end

return Ball
