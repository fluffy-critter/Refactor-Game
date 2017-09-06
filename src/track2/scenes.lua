--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local imagepool = require('imagepool')
local quadtastic = require('thirdparty.libquadtastic')
local util = require('util')
local shaders = require('shaders')

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
        frame = quads.rose.kitchen.normal,
        animations = {
            normal = {
                {quads.rose.kitchen.normal, 3},
                {quads.rose.kitchen.blink, 0.1},
                {quads.rose.kitchen.normal, 2},
                {quads.rose.kitchen.blink, 0.1},
                {quads.rose.kitchen.normal, 5},
                {quads.rose.kitchen.blink, 0.1},
                {quads.rose.kitchen.normal, 0.5},
                {quads.rose.kitchen.blink, 0.1},
            },
            eyes_right = {
                {quads.rose.kitchen.eyes_right, 2},
                {quads.rose.kitchen.blink, 0.1},
                {quads.rose.kitchen.eyes_right, 3},
                {quads.rose.kitchen.blink, 0.1},
                {quads.rose.kitchen.eyes_right, 4},
                {quads.rose.kitchen.blink, 0.1},
                {quads.rose.kitchen.eyes_right, 0.6},
                {quads.rose.kitchen.blink, 0.1},
            },
            eyes_left = {
                {quads.rose.kitchen.eyes_left, 4},
                {quads.rose.kitchen.blink, 0.1},
                {quads.rose.kitchen.eyes_left, 1},
                {quads.rose.kitchen.blink, 0.1},
                {quads.rose.kitchen.eyes_left, 3},
                {quads.rose.kitchen.blink, 0.1},
                {quads.rose.kitchen.eyes_left, 0.3},
                {quads.rose.kitchen.blink, 0.1},
            },
            closed = {
                {quads.rose.kitchen.blink, 0.1},
            },
            crying = {
                {quads.rose.kitchen.cry[1], 2/3},
                {quads.rose.kitchen.cry[2], 2/3},
            }
        }
    })
    rose.animation = rose.animations.normal

    local openDoor = Sprite.new({
        sheet = spriteSheet,
        pos = {128,8},
        frame = nil
    })

    local closedDoor = Sprite.new({
        sheet = spriteSheet,
        pos = {144,0},
        frame = nil
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
            kneeling_by_rose = {
                pos = {135,115},
                onComplete = function(sprite)
                    sprite.frame = quads.greg.kneeling
                end
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
                pos = {149,2},
                speed = 0.75,
                easing = Animator.Easing.ease_inout,
                onComplete = function()
                    -- open the door
                    openDoor.frame = quads.door.open
                end
            },
            gone = {
                pos = {149,-20},
                onComplete = function(sprite)
                    -- close the door
                    openDoor.frame = nil
                    closedDoor.frame = quads.door.closed
                    -- disappear completely
                    sprite.frame = nil
                end
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
                animation = {stop=quads.greg.down[1]}
            },
            facing_up = {
                animation = {stop=quads.greg.up[1]}
            },
            facing_right = {
                animation = {stop=quads.greg.right[1]}
            },
            facing_left = {
                animation = {stop=quads.greg.left[1]}
            },
            on_phone = {
                animation = {stop=quads.greg.phone}
            },
            kitchen = {
                pos = {88,38}
            },
            behind_rose = {
                pos = {128, 60},
                onComplete = function(sprite)
                    sprite.frame = quads.greg.down[1]
                end
            },
            pause = {
                duration = 1
            }
        },
        mapAnimation = function(self, dx, dy, pose)
            print("mapAnimation dx=" .. dx .. " dy=" .. dy .. " pose=" .. tostring(pose))
            -- TODO: pose (final arg) can choose 'worried' modifier etc.

            if pose.animation then
                print("  pose provides animation of " .. #pose.animation .. " frames")
                return pose.animation
            end

            if math.abs(dx) < math.abs(dy) then
                print("  vertical " .. dy)
                return (dy > 0 and self.animations.walk_down) or (dy < 0 and self.animations.walk_up)
            end

            print("  horizontal " .. dx)
            return (dx > 0 and self.animations.walk_right) or (dx < 0 and self.animations.walk_left)
        end,
        frame = quads.greg.down[1]
    })
    greg.animation = nil

    return {
        frames = quads,
        rose = rose,
        greg = greg,

        layers = {
            {image = backgroundLayer},
            openDoor,
            greg,
            closedDoor,
            {image = foregroundLayer},
            rose,
        },

        update = function(self, dt)
            for _,layer in ipairs(self.layers) do
                if layer.update then
                    layer:update(dt)
                end
            end
        end,

        draw = function(self)
            love.graphics.setColor(255,255,255)
            for _,thing in ipairs(self.layers) do
                if thing.frame then
                    love.graphics.draw(thing.sheet, thing.frame, unpack(thing.pos or {}))
                elseif thing.image then
                    love.graphics.draw(thing.image, unpack(thing.pos or {}))
                end
            end
            return true
        end
    }
end

function scenes.phase11(duration)
    local image = imagepool.load("track2/phase11-pan.png", {nearest=false}) -- round at blit time, let shaders interp
    local blurSize = 1
    local panSize = image:getWidth() - 256 - blurSize
    local time = 0
    local shader = shaders.load('shaders/gaussBlur.fs')

    return {
        update = function(_, dt)
            time = time + dt
        end,
        draw = function()
            -- TODO alpha?
            local x = time/duration
            if x > 1 then
                return false
            end

            local p = math.floor(-util.smoothStep(x)*panSize + 0.5)

            if x < 0.02 then
                love.graphics.setColor(255,255,255,x*50*255)
            elseif x < 0.98 then
                love.graphics.setColor(255,255,255,255)
            else
                love.graphics.setColor(255,255,255,(1 - x)*50*255)
            end
            if x < 0.5 then
                love.graphics.draw(image, p)
            else
                local k = (x - 0.5)*2
                local b = k*blurSize
                love.graphics.setShader(shader)
                shader:send("sampleRadius", {b/image:getWidth(), 0})
                love.graphics.draw(image, p)
                love.graphics.setShader()
            end
            return true
        end
    }
end

function scenes.missing()
    return {
        update = function() end,
        draw = function()
            love.graphics.clear(0,0,0)
            love.graphics.setColor(255,255,255)
            love.graphics.print("(scene missing)", 64, 128)
            return true
        end
    }
end

return scenes