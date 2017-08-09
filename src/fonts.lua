--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local fonts = {
    scoreboard = love.graphics.newFont("fonts/scoreboard.fnt"),
    centuryGothicDigits = love.graphics.newImageFont("fonts/centurygothic-digits.png", "0123456789"),
    returnOfGanon = {
        red = love.graphics.newFont("fonts/ReturnOfGanon.fnt", "fonts/ReturnOfGanon_0-red.png"),
        blue = love.graphics.newFont("fonts/ReturnOfGanon.fnt", "fonts/ReturnOfGanon_0-blue.png"),
        ttf16 = love.graphics.newFont("fonts/ReturnOfGanon.ttf", 16)
    },
}

return fonts
