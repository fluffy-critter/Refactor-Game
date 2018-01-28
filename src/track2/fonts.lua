--[[
Refactor: 2 - Strangers

fonts

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local fonts = {
    returnOfGanon = {
        red = love.graphics.newFont("fonts/ReturnOfGanon.fnt", "fonts/ReturnOfGanon_0-red.png"),
        blue = love.graphics.newFont("fonts/ReturnOfGanon.fnt", "fonts/ReturnOfGanon_0-blue.png"),
        ttf16 = love.graphics.newFont("fonts/ReturnOfGanon.ttf", 16)
    },
    chronoTrigger = love.graphics.newFont("fonts/ChronoTriggerProportional.ttf", 16),

    debug = love.graphics.newFont(8),
}

return fonts
