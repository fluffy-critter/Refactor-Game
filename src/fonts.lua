--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local fonts = {
    hidpi = false,

    menu = {
        hidpi = {
            regular = love.graphics.newFont("fonts/LibreBodoni-Regular.otf", 48),
            h1 = love.graphics.newFont("fonts/LibreBodoni-Bold.otf", 64),
            h2 = love.graphics.newFont("fonts/LibreBodoni-Italic.otf", 56),
        },
        plain = {
            regular = love.graphics.newFont("fonts/LibreBodoni-Regular.otf", 24),
            h1 = love.graphics.newFont("fonts/LibreBodoni-Bold.otf", 32),
            h2 = love.graphics.newFont("fonts/LibreBodoni-Italic.otf", 28),
        },
    },
    debug = love.graphics.newFont(16),

    -- TODO make helvetica with black outline for URLs on menu
    --helveticaOutline = love.graphics.newFont("fonts/helveticaOutline.fnt")
}

local multires = {
    __index = function(o,k)
        if fonts.hidpi and o.hidpi[k] then
            return o.hidpi[k]
        end

        if o.plain[k] then
            return o.plain[k]
        end

        return rawget(o, k)
    end
}

setmetatable(fonts.menu, multires)

return fonts
