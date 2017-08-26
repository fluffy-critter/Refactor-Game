--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local imagepool = require('imagepool')
local quadtastic = require('thirdparty.libquadtastic')

local Sprite = require('track2.Sprite')

local scenes = {}

local function loadSprites(imageFile, quadFile)
    local spriteSheet = imagepool.load(imageFile)
    spriteSheet:setFilter('nearest')
    local quads = quadtastic.create_quads(require(quadFile), spriteSheet:getWidth(), spriteSheet:getHeight())
    return spriteSheet, quads
end

function scenes.kitchen()
    local backgroundLayer = imagepool.load('track2/kitchen.png')
    local foregroundLayer = imagepool.load('track2/kitchen-fg.png')
    local spriteSheet, quads = loadSprites('track2/sprites.png', 'track2.sprites')

    local rose = Sprite.new({
        sheet = spriteSheet,
        pos = {120, 112},
        frame = quads.rose.kitchen
    })

    local greg = Sprite.new({
        sheet = spriteSheet,
        pos = {217, -40},
        animations = {
            walk_down = {
                {quads.greg.down[1], .25},
                {quads.greg.down[2], .25},
                {quads.greg.down[1], .25},
                {quads.greg.down[3], .25},
            }
        },
        frame = quads.greg.down[1]
    })
    greg.animation = nil

    return {
        frames = quads,
        rose = rose,
        greg = greg,

        layers = {
            {sheet = backgroundLayer},
            greg,
            {sheet = foregroundLayer},
            rose
        },

        update = function(self, dt)
            for _,layer in ipairs(self.layers) do
                if layer.update then
                    layer:update(dt)
                end
            end
        end,

        draw = function(self)
            for _,thing in ipairs(self.layers) do
                if thing.frame then
                    love.graphics.draw(thing.sheet, thing.frame, unpack(thing.pos or {}))
                else
                    love.graphics.draw(thing.sheet, unpack(thing.pos or {}))
                end
            end
        end
    }
end

return scenes