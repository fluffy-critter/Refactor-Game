--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local imagepool = require('imagepool')
local quadtastic = require('thirdparty.libquadtastic')

local Sprite = require('track2.Sprite')
local Animator = require('Animator')

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
                {quads.greg.down[1], .2},
                {quads.greg.down[2], .2},
                {quads.greg.down[1], .2},
                {quads.greg.down[3], .2},
                stop = quads.greg.down[1],
                -- walkRate = 24,
            },
            walk_up = {
                {quads.greg.up[1], .2},
                {quads.greg.up[2], .2},
                {quads.greg.up[1], .2},
                {quads.greg.up[3], .2},
                stop = quads.greg.up[1],
            },
            walk_left = {
                {quads.greg.left[1], .2},
                {quads.greg.left[2], .2},
                {quads.greg.left[1], .2},
                {quads.greg.left[3], .2},
                stop = quads.greg.left[1],
            },
            walk_right = {
                {quads.greg.right[1], .2},
                {quads.greg.right[2], .2},
                {quads.greg.right[1], .2},
                {quads.greg.right[3], .2},
                stop = quads.greg.right[1],
            }
        },
        pose = {
            next_to_rose = {
                pos = {136,104}
            },
            next_to_rose_worried = {
                pos = {136,104},
                worried = true,
                -- onComplete = function(sprite)
                --     sprite.animation = greg.animations.stand_left_worried
                -- end
            },
            right_of_rose = {
                pos = {152,108},
            },
            left_of_stairs = {
                pos = {182,118},
            },
            bottom_of_stairs = {
                pos = {217,80}
            },
            left_of_couch = {
                pos = {200,128}
            },
            below_doors = {
                pos = {147,90}
            },
            leaving = {
                pos = {147,-80}, -- TODO we'll probably want to open the door when he's near it
                rate = 0.2,
                easing = Animator.Easing.ease_in
            },
            couch_sitting = {
                pos = {204,124},
                onComplete = function(sprite)
                    sprite.frame = quads.greg.sitting.normal
                end
            },
            couch_sitting_thinking = {
                pos = {204,124},
                onComplete = function(sprite)
                    sprite.frame = quads.greg.sitting.thinking
                end
            },
            facing_down = {
                onComplete = function(sprite)
                    sprite.frame = quads.greg.down[1]
                end
            },
            facing_up = {
                onComplete = function(sprite)
                    sprite.frame = quads.greg.up[1]
                end
            },
            facing_right = {
                onComplete = function(sprite)
                    sprite.frame = quads.greg.right[1]
                end
            },
            facing_left = {
                onComplete = function(sprite)
                    sprite.frame = quads.greg.left[1]
                end
            },
            kitchen = {
                pos = {88,38}
            },
            behind_rose = {
                pos = {128, 60},
                onComplete = function(sprite)
                    sprite.frame = quads.greg.down[1]
                end
            }
        },
        mapAnimation = function(self, dx, dy, _)
            -- TODO: pose (final arg) can choose 'worried' modifier etc.

            if math.abs(dx) < math.abs(dy) then
                return dy > 0 and self.animations.walk_down or self.animations.walk_up
            end

            return dx > 0 and self.animations.walk_right or self.animations.walk_left
        end,
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