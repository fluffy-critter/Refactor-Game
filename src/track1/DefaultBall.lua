--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local DefaultBall = {}

function DefaultBall:onPaddle(nrm)
    local p = self.game.paddle
    local nx, ny = unpack(nrm)

    -- relative velocity
    local rvx = self.vx - p.vx
    local rvy = self.vy - p.vy

    -- calculate the perpendicular projection of our reversed velocity vector onto the reflection normal
    local mag = math.sqrt(nx*nx + ny*ny)
    local dot = nx*rvx + ny*rvy
    local px = -nx*dot/mag
    local py = -ny*dot/mag

    -- move the ball to avoid recollision
    self.x = self.x + nx
    self.y = self.y + ny

    -- reflect the velocity vector, and adjust back to absolute with a bit extra
    self.vx = rvx + 2*px + 1.1*p.vx
    self.vy = rvy + 2*py + 1.1*p.vy
end

function DefaultBall:update(dt)
    local p = self.game.paddle
    local b = self.game.board

    if self.x + self.r > b.right then
        self.x = b.right - self.r
        self.vx = -self.vx
    end
    if self.x - self.r < b.left then
        self.x = b.left + self.r
        self.vx = -self.vx
    end
    if self.y - self.r < b.top then
        self.y = b.top + self.r
        self.vy = -self.vy
    end

    self.x = self.x + dt*self.vx
    self.y = self.y + dt*self.vy

    if self.y - self.r > self.game.board.bottom and self.game.phase == 0 then
        return false
    end
end

function DefaultBall:reset()
    self.r = 2
    self.x = math.random(self.game.board.left + o.r, self.game.board.right - o.r)
    self.y = math.random(self.game.board.top + o.r, (self.game.board.top + self.game.board.bottom)/2)
    self.vx = math.random(-30, 30)
    self.vy = math.random(-30, 30)
end

function DefaultBall.new(game)
    local o = {}
    setmetatable(o, {__index = DefaultBall})

    o.game = game
    o.color = { 255, 128, 128 }

    o:reset()

    return 0
end

return DefaultBall
