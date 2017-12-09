--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Useful graphics functions

]]

local gfx = {}

local imagepool = require('imagepool')

local filledCircle = imagepool.load('images/circlefill.png', {mipmaps=true})
local hollowCircle = imagepool.load('images/circlehollow.png', {mipmaps=true})

function gfx.circle(fill, x, y, r)
    love.graphics.push()
    love.graphics.setBlendMode("alpha", "alphamultiply")
    local cc = fill and filledCircle or hollowCircle
    love.graphics.draw(cc, x, y, 0, r/256, r/256, 256, 256)
    love.graphics.pop()
end

return gfx
