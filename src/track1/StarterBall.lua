--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]


local StarterBall = {}

function StarterBall:start_update(dt)
    local p = self.game.paddle

    self.vx = self.vx + dt*(p.x - self.x)
    self.vy = self.vy + dt*(p.y - self.y)

    self.x = self.x + dt*self.vx
    self.y = self.y + dt*self.vy

    if self.y - self.r > self.game.board.bottom then
        self:reset()
    end
end

function StarterBall:reset()
    self.r = 3
    self.x = math.random(self.game.board.left + o.r, self.game.board.right - o.r)
    self.y = math.random(self.game.board.top + o.r, (self.game.board.top + self.game.board.bottom)/2)
    self.vx = 0
    self.vy = 0
end

function StarterBall.new(game)
    o = {}
    setmetatable(o, {__index = StarterBall})

    o.game = game
    o.color = { 192, 255, 255 }
    o.update = StarterBall.start_update

    o:reset()

    return o
end

return StarterBall
