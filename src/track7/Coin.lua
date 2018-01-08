--[[
Refactor: 7 - flight

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

a coin

]]

local Coin = {}

function Coin.new(o)
    local self = o or {}
    setmetatable(self, {__index = Coin})
    return self
end

function Coin:update()
    return false
end

function Coin:draw()
    print(self.x, self.y)
    love.graphics.draw(self.sprite, self.quad, self.x, self.y)
end

return Coin
