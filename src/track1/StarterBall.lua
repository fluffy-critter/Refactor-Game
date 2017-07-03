--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]


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

function StarterBall:game_update(dt)
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

function StarterBall:reset()
    self.r = 3
    self.x = math.random(self.game.board.left + o.r, self.game.board.right - o.r)
    self.y = math.random(self.game.board.top + o.r, (self.game.board.top + self.game.board.bottom)/2)
    self.vx = 0
    self.vy = 0
end

function StarterBall:start_onPaddle(nrm)
    self.update = self.game_update

    self.onPaddle = self.game_onPaddle
    self:onPaddle(nrm)

    self.game:setPhase(0)
end

function StarterBall:game_onPaddle(nrm)
    print("got collision of", unpack(nrm))
end

function StarterBall.new(game)
    o = {}
    setmetatable(o, {__index = StarterBall})

    o.game = game
    o.color = { 192, 255, 255 }
    o.update = StarterBall.start_update
    o.onPaddle = StarterBall.start_onPaddle

    o:reset()

    return o
end

return StarterBall
