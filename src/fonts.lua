--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local fonts = {}

function fonts.setPixelScale(scale)
    fonts.menu = {
        regular = love.graphics.newFont("fonts/LibreBodoni-Regular.otf", 24*scale),
        h1 = love.graphics.newFont("fonts/LibreBodoni-Bold.otf", 32*scale),
        h2 = love.graphics.newFont("fonts/LibreBodoni-Italic.otf", 28*scale),
    }

    fonts.debug = love.graphics.newFont(16*scale)
end

return fonts
