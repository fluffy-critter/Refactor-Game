--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Useful graphics functions

]]

local gfx = {}

local imagepool = require('imagepool')
local quadtastic = require('thirdparty.libquadtastic')

local filledCircle = imagepool.load('images/circlefill.png', {mipmaps=true})
local hollowCircle = imagepool.load('images/circlehollow.png', {mipmaps=true})

-- Select the most-preferred canvas format from a list of formats
local graphicsFormats = love.graphics.getCanvasFormats()
print("Available graphics formats:")
for k in pairs(graphicsFormats) do print('\t' .. k) end

function gfx.selectCanvasFormat(...)
    for _,k in ipairs({...}) do
        if graphicsFormats[k] then
            return k
        end
    end
    return nil
end

function gfx.circle(fill, x, y, r)
    love.graphics.push()
    love.graphics.setBlendMode("alpha", "alphamultiply")
    local cc = fill and filledCircle or hollowCircle
    love.graphics.draw(cc, x, y, 0, r/256, r/256, 256, 256)
    love.graphics.pop()
end

function gfx.loadSprites(imageFile, quadFile, cfg)
    local spriteSheet = imagepool.load(imageFile, cfg)
    local quads = quadtastic.create_quads(love.filesystem.load(quadFile)(),
        spriteSheet:getWidth(), spriteSheet:getHeight())
    return spriteSheet, quads
end

return gfx
