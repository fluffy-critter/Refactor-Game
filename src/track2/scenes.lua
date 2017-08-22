--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local imagepool = require('imagepool')
local quadtastic = require('thirdparty.libquadtastic')

local scenes = {}

local function loadSprites()
    local spriteSheet = imagepool.load('track2/sprites.png')
    spriteSheet:setFilter('nearest')
    local quads = quadtastic.create_quads(require('track2.sprites'), spriteSheet:getWidth(), spriteSheet:getHeight())
    return spriteSheet, quads
end

function scenes.kitchen()
    local backgroundLayer = imagepool.load('track2/kitchen.png')
    local foregroundLayer = imagepool.load('track2/kitchen-fg.png')
    local spriteSheet, quads = loadSprites()

    local frameNum = 1
    local frameTime = 0

    local rose = {
        sheet = spriteSheet,
        pos = {120, 112},
        frame = quads.rose_kitchen
    }

    local greg = {
        sheet = spriteSheet,
        pos = {217, 0},
        animation = nil,
        animations = {
            walk_down = {
                {quads.greg_down_0, .25},
                {quads.greg_down_1, .25},
                {quads.greg_down_0, .25},
                {quads.greg_down_2, .25},
            }
        },
        frameTime = 0,
        frameNum = 0,
        frame = quads.greg_down_0
    }

    return {
        frames = quads,
        rose = rose,
        greg = greg,
        sprites = {rose, greg},

        update = function(self, dt)
            for _,sprite in pairs(self.sprites) do
                if sprite.animation then
                    sprite.frameTime = sprite.frameTime + dt
                    if sprite.frameTime > sprite.animation[frameNum][2] then
                        sprite.frameTime = 0
                        sprite.frameNum = sprite.frameNum + 1
                        if sprite.frameNum > #sprite.animation then
                            sprite.frameNum = 1
                        end
                        sprite.frame = sprite.animation[sprite.frameNum][1]
                    end
                end
            end
        end,
        draw = function(self)
            love.graphics.draw(backgroundLayer)

            for _,sprite in pairs(self.sprites) do
                love.graphics.draw(sprite.sheet, sprite.frame, unpack(sprite.pos))
            end

            love.graphics.draw(foregroundLayer)
        end
    }
end

return scenes