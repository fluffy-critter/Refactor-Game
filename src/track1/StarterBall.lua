--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local DefaultBall = require('track1.DefaultBall')

local StarterBall = {}

function StarterBall:start_update(dt)
    local p = self.game.paddle

    self.vx = self.vx + dt*(p.x - self.x)
    self.vy = self.vy + dt*(p.y - self.y)

    -- make the ball always seek directly to the paddle
    if false then
        local vel = math.sqrt(self.vx * self.vx + self.vy * self.vy)
        local nvx = p.x - self.x
        local nvy = p.y - self.y
        local v2 = math.sqrt(nvx * nvx + nvy * nvy)
        if v2 > 0 then
            self.vx = nvx * vel / v2
            self.vy = nvy * vel / v2
        end
    end

    self.x = self.x + dt*self.vx
    self.y = self.y + dt*self.vy

    if self.y - self.r > self.game.board.bottom then
        self:reset()
    end
end

function StarterBall:reset()
    self.r = 3
    self.x = math.random(self.game.board.left + self.r, self.game.board.right - self.r)
    self.y = math.random(self.game.board.top + self.r, (self.game.board.top + self.game.board.bottom)/2)
    self.vx = 0
    self.vy = 0
end

function StarterBall:start_onPaddle(nrm)
    self.update = DefaultBall.update

    self.onPaddle = DefaultBall.onPaddle
    self:onPaddle(nrm)

    self.game:setPhase(0)
end

function StarterBall.new(game)
    local o = {}
    setmetatable(o, {__index = StarterBall})

    o.game = game
    o.color = { 128, 255, 255 }
    o.update = StarterBall.start_update
    o.onPaddle = StarterBall.start_onPaddle

    o:reset()

    return o
end

return StarterBall
