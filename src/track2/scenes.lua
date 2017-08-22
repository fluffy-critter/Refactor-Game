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
    local sprite, quads = loadSprites()

    local downAnimation = {
        {quads.greg_down_0, .25},
        {quads.greg_down_1, .25},
        {quads.greg_down_0, .25},
        {quads.greg_down_2, .25},
    }
    local frameNum = 1
    local frameTime = 0

    return {
        rosePos = {120, 112},
        gregPos = {217, 0},

        update = function(self, dt)
            frameTime = frameTime + dt
            if frameTime > downAnimation[frameNum][2] then
                frameTime = 0
                frameNum = frameNum + 1
                if frameNum > #downAnimation then
                    frameNum = 1
                end
            end

            self.gregPos[2] = self.gregPos[2] + dt*8
        end,
        draw = function(self)
            love.graphics.draw(backgroundLayer)

            love.graphics.draw(sprite, quads.rose_kitchen, unpack(self.rosePos))
            love.graphics.draw(sprite, downAnimation[frameNum][1], unpack(self.gregPos))

            love.graphics.draw(foregroundLayer)
        end
    }
end

return scenes