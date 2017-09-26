--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

-- TODO replace this with an asset pool, ugh
local fonts = {
    menu = {
        regular = love.graphics.newFont("fonts/LibreBodoni-Regular.otf", 24),
        h1 = love.graphics.newFont("fonts/LibreBodoni-Bold.otf", 32),
        h2 = love.graphics.newFont("fonts/LibreBodoni-Italic.otf", 32),
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
