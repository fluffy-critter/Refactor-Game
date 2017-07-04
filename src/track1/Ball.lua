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

    dx, dy: position impulse (reset every frame)
    dvx, dvy: velocity impulse (reset every frame)

    color: render color, for default draw method
    hitColor: hit particle color

    lives: number of times it can be lost

    scoreCooldown: how long to wait from the last paddle hit before it becomes eligible for scoring again

Methods:

    onInit() - called when the ball is first initialized
    onStart() - called when the ball's life starts

    preUpdate(dt) - called at the beginning of the update cycle; resets impulses
    onUpdate(dt) - any AI-type behavior goes here; sets impulses etc.
    postUpdate(dt) - called at the end of the update cycle; should apply impulses

    onHitPaddle(nrm, paddle) - called when the ball hits a paddle
    onHitWall(nrm, x, y) - called when the ball hits a wall
    onHitActor(nrm, actor) - called when the ball hits an actor
    onLost() - called when the ball is lost from the arena

    isAlive() - returns whether the ball is still alive

    applyReflection(nrm, vx, vy) - apply a surface normal reflection to our velocity, with optional velocity offset

    draw() - render the ball

]]

local Ball = {}

local HitParticle = require('track1.HitParticle')

function Ball.new(game, o)
    local self = o or {}
    setmetatable(self, {__index = Ball})

    self.game = game
    self:onInit()
    self:onStart()

    return self
end

function Ball:onInit()
    local defaults = {
        r = 2,
        color = {255, 192, 192, 255},
        hitColor = {255, 64, 64, 192},
        ax = 0,
        ay = 0,
        spawnVelocity = 100,
        lives = 1,
        elasticity = 1,
        paddleScore = 1,
        paddleScoreInc = 1,
        scoreCooldown = 0.5
    }

    for k,v in pairs(defaults) do
        if self[k] == nil then
            self[k] = v
        end
    end
end

function Ball:onStart()
    self.x = math.random(self.game.bounds.left + self.r, self.game.bounds.right - self.r)
    self.y = math.random(self.game.bounds.top + self.r, (self.game.bounds.top + self.game.bounds.bottom)/2)
    self.vx = math.random(-300, 300)
    self.vy = math.random(-300, 300)

    local mag = math.sqrt(self.vx*self.vx + self.vy*self.vy)
    if mag and self.spawnVelocity then
        self.vx = self.spawnVelocity*self.vx/mag
        self.vy = self.spawnVelocity*self.vy/mag
    end

    self.paddleScoreVal = self.paddleScore
    self.timeSinceLastHit = 0
end

function Ball:preUpdate(dt)
    self.dx = 0
    self.dy = 0
    self.dvx = 0
    self.dvy = 0

    self.timeSinceLastHit = self.timeSinceLastHit + dt
end


function Ball:onUpdate(dt)
    -- do nothing by default
end

function Ball:postUpdate(dt)
    self.x = self.x + self.dx
    self.y = self.y + self.dy
    self.vx = self.vx + self.dvx
    self.vy = self.vy + self.dvy

    -- apply acceleration first so that position includes the integration of acceleration
    self.vx = self.vx + self.ax*dt
    self.vy = self.vy + self.ay*dt
    self.x = self.x + self.vx*dt
    self.y = self.y + self.vy*dt
end

function Ball:onHitPaddle(nrm, paddle)
    local nx, ny = unpack(nrm)

    print("got normal", nx, ny)
    self:applyReflection(nrm, paddle.vx, paddle.vy)

    if self.timeSinceLastHit > self.scoreCooldown then
        self.game.score = self.game.score + self.paddleScoreVal
        self.paddleScoreVal = self.paddleScoreVal + self.paddleScoreInc
    end
    self.timeSinceLastHit = 0
end

--[[
    nrm: surface normal of the wall
    x, y: location of the impact
]]
function Ball:onHitWall(nrm, x, y)
    self:applyReflection(nrm)

    local nx, ny = unpack(nrm)

    local particles = self.game.particles
    table.insert(particles, HitParticle.new(x, y, math.abs(ny)*self.r*4 + 1, math.abs(nx)*self.r*4 + 1, self.hitColor, 0.3))
end

function Ball:onHitActor(nrm, actor)
    if self.hasHit[actor] then
        return
    end
    self.hasHit[actor] = true

    self:applyReflection(nrm)
end

function Ball:onLost()
    self.lives = self.lives - 1
end

function Ball:isAlive()
    return self.lives > 0
end

function Ball:applyReflection(nrm, vx, vy)
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

    -- move the ball to avoid recollision
    self.dx = self.dx + nx
    self.dy = self.dy + ny

    -- reflect the velocity vector
    self.dvx = self.dvx + (1 + self.elasticity)*px
    self.dvy = self.dvy + (1 + self.elasticity)*py

    print("velocity:", self.vx, self.vy)
    print("position impuse:", self.dx, self.dy)
    print("velocity impulse:", self.dvx, self.dvy)
end

function Ball:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle("fill", self.x, self.y, self.r)
end

return Ball
