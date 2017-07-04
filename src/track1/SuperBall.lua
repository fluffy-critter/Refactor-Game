--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local DefaultBall = require('track1.DefaultBall')

local SuperBall = {
    onPaddle = DefaultBall.onPaddle,
    update = DefaultBall.update
}

function SuperBall:onHitActor(nrm, actor)
    -- just barrel on through
    self.vx = self.vx*1.1
    self.vy = self.vy*1.1
end
