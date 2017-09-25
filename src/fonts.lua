--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

-- TODO replace this with an asset pool, ugh
local fonts = {
    bodoni72 = {
        regular = love.graphics.newFont("fonts/Bodoni72Regular.fnt"),
        bold = love.graphics.newFont("fonts/Bodoni72Bold.fnt"),
        italic = love.graphics.newFont("fonts/Bodoni72Italic.fnt"),
    },
    debug = love.graphics.newFont(8),

    scoreboard = love.graphics.newFont("fonts/scoreboard.fnt"),
    centuryGothicDigits = love.graphics.newImageFont("fonts/centurygothic-digits.png", "0123456789"),
    returnOfGanon = {
        red = love.graphics.newFont("fonts/ReturnOfGanon.fnt", "fonts/ReturnOfGanon_0-red.png"),
        blue = love.graphics.newFont("fonts/ReturnOfGanon.fnt", "fonts/ReturnOfGanon_0-blue.png"),
        ttf16 = love.graphics.newFont("fonts/ReturnOfGanon.ttf", 16)
    },
    chronoTrigger = love.graphics.newFont("fonts/ChronoTrigger.ttf", 16),

    -- TODO make helvetica with black outline for URLs on menu
    --helveticaOutline = love.graphics.newFont("fonts/helveticaOutline.fnt")
}

return fonts
