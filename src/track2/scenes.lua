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
local TextBox = require('track2.TextBox')

local scenes = {}

local function loadSprites(imageFile, quadFile)
    local spriteSheet = imagepool.load(imageFile, {nearest=true})
    local quads = quadtastic.create_quads(love.filesystem.load(quadFile)(),
        spriteSheet:getWidth(), spriteSheet:getHeight())
    return spriteSheet, quads
end

local function updateLayers(layers, dt, time)
    for _,layer in ipairs(layers) do
        if layer.update then
            layer:update(dt, time)
        end
    end
end

local function drawLayers(layers)
    for _,thing in ipairs(layers) do
        if thing.draw then
            thing:draw()
        elseif thing.frame then
            love.graphics.draw(thing.sheet, thing.frame, unpack(thing.pos or {}))
        elseif thing.image then
            love.graphics.draw(thing.image, unpack(thing.pos or {}))
        end
    end
end

function scenes.kitchen()
    local backgroundLayer = imagepool.load('track2/kitchen.png')
    local foregroundLayer = imagepool.load('track2/kitchen-fg.png')
    local spriteSheet, quads = loadSprites('track2/kitchen-sprites.png', 'track2/kitchen-sprites.lua')

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

    local greg
    greg = Sprite.new({
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
            },
            crying = {
                {quads.greg.crying[1], 1/12},
                {quads.greg.crying[2], 1/9},
                {quads.greg.crying[3], 1/6},
                {quads.greg.crying[2], 1/12},
            }
        },
        pose = {
            next_to_rose = {
                pos = {136,104}
            },
            kneeling_by_rose = {
                pos = {135,117},
                onComplete = function(sprite)
                    sprite.frame = quads.greg.clench
                end
            },
            right_of_rose = {
                pos = {152,108},
            },
            left_of_stairs = {
                pos = {182,118},
            },
            bottom_of_stairs = {
                pos = {214,80}
            },
            left_of_couch = {
                pos = {200,124}
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
                pos = {204,120},
                onComplete = function(sprite)
                    sprite.frame = quads.greg.sitting.normal
                end
            },
            couch_sitting_crying = {
                pos = {204,120},
                onComplete = function(sprite)
                    sprite.animation = greg.animations.crying
                end
            },
            couch_sitting_thinking = {
                pos = {204,120},
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
            clench = {
                animation = {stop=quads.greg.clench}
            },
            kitchen = {
                pos = {88,38}
            },
            behind_rose = {
                pos = {128, 60}
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

    local layers = {
        {image = backgroundLayer},
        openDoor,
        greg,
        closedDoor,
        {image = foregroundLayer},
        rose,
    }

    return {
        frames = quads,
        rose = rose,
        greg = greg,

        update = function(_, dt)
            updateLayers(layers, dt)
        end,

        draw = function(_)
            love.graphics.setColor(255,255,255)
            drawLayers(layers)
            return true
        end
    }
end

function scenes.phase11(game, duration)
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
            return not game.npc.gone
        end
    }
end

function scenes.hospital(duration)
    local spriteSheet, quads = loadSprites('track2/hospital-sprites.png', 'track2/hospital-sprites.lua')

    local bgImage = imagepool.load("track2/hospital-bg.png", {nearest=true})

    local bg = {
        {image = bgImage},
        Sprite.new({
            pos = {17, 112},
            animation = {
                {quads.tech[1], 2/3},
                {quads.tech[2], 2/3}
            },
            sheet = spriteSheet
        }),
        Sprite.new({
            pos = {120, 96},
            sheet = spriteSheet,
            animation = {
                {quads.mri[1], 2/30},
                {quads.mri[2], 2/30},
                {quads.mri[3], 2/30},
                {quads.mri[4], 2/30},
                {quads.mri[5], 2/30},
                {quads.mri[6], 2/30},
                {quads.mri[7], 2/30},
                {quads.mri[8], 2/30},
                {quads.mri[9], 2/30},
                {quads.mri[10], 2/30},
            }
        })
    }

    local fg = {
        Sprite.new({
            pos = {120, 112},
            sheet = spriteSheet,
            frame = quads.rose
        }),
    }

    local time = 0

    return {
        update = function(_, dt)
            time = time + dt

            updateLayers(bg, dt)
            updateLayers(fg, dt)
        end,
        draw = function()
            local t = math.min(time/duration, 1)
            local ofs = (224 - bgImage:getHeight())*util.smoothStep(1 - t)

            love.graphics.translate(0, ofs)
            drawLayers(bg)

            love.graphics.translate(0, -ofs)
            drawLayers(fg)

            return true
        end
    }
end

function scenes.missing(label)
    return {
        update = function() end,
        draw = function()
            love.graphics.clear(0,0,0)
            love.graphics.setColor(255,255,255)
            love.graphics.print("(scene missing: " .. label .. ")", 64, 128)
            return true
        end
    }
end

function scenes.endKitchen(game, version)
    local backgroundLayer = imagepool.load('track2/kitchen.png')
    local foregroundLayer = imagepool.load('track2/kitchen-fg.png')
    -- TODO different outfits? are they older?
    local spriteSheet, quads = loadSprites('track2/kitchen-sprites.png', 'track2/kitchen-sprites.lua')

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
            },
        }
    })


    local layers = {
        {image = backgroundLayer},
    }

    -- does Greg exist?
    if version == "wtf" then
        table.insert(layers, Sprite.new({
            sheet = spriteSheet,
            pos = {88,113},
            frame = quads.greg.down[1],
        }))
        rose.animation = rose.animations.normal
    elseif version == "alienated" or version == "alien_endgame" then
        table.insert(layers, Sprite.new({
            sheet = spriteSheet,
            pos = {120,113},
            frame = quads.greg.leaning,
        }))
        rose.frame = quads.rose.kitchen.blink
    elseif version == "vacation" then
        table.insert(layers, Sprite.new({
            sheet = spriteSheet,
            pos = {120,113},
            frame = quads.greg.leaning,
        }))
        rose.animation = rose.animations.eyes_left
    elseif version == "brain_problems" or version == "stroke" then
        table.insert(layers, Sprite.new({
            sheet = spriteSheet,
            pos = {204,130},
            frame = quads.greg.sitting.thinking
        }))
        rose.animation = rose.animations.eyes_right
    elseif version == "herpderp" then
        rose.animation = {{quads.fluffy.open, 3}, {quads.fluffy.blink, 0.2}}
        game.textBox = TextBox.new({text = "Nice job breaking it, hero."})
    else
        print(version .. ": nobody's there?")
        rose.animation = rose.animations.normal
    end

    table.insert(layers, {image = foregroundLayer})
    table.insert(layers, rose)

    return {
        layers = layers,
        update = function(_, dt)
            updateLayers(layers, dt)
        end,
        draw = function(_)
            love.graphics.setColor(255,255,255)
            drawLayers(layers)
            return true
        end
    }
end

function scenes.parkBench(gregMissing)
    local spriteSheet, quads = loadSprites("track2/parkbench-sprites.png", "track2/parkbench-sprites.lua")
    local time = 0

    local flockX, flockY = false, 40

    local function birb()
        local age = 0
        local dx = math.random(-10,10)/10
        local dy = 0
        local flappy = false

        local ox, oy = math.random(-20, 20), math.random(-20, 20)

        local birbAnims = {
            left = {
                {quads.birb.left.up, math.random()*3 + 0.25},
                {quads.birb.left.peck, 0.1},
                {quads.birb.left.up, math.random() + 0.5},
                {quads.birb.left.peck, 0.1}
            },
            right = {
                {quads.birb.right.up, math.random()*3 + 0.25},
                {quads.birb.right.peck, 0.1},
                {quads.birb.right.up, math.random() + 0.5},
                {quads.birb.right.peck, 0.1}
            },
            flap = {
                {quads.birb.flap[1], 0.05},
                {quads.birb.flap[2], 0.05},
                {quads.birb.flap[3], 0.05},
                {quads.birb.flap[4], 0.05},
                {quads.birb.flap[3], 0.05},
                {quads.birb.flap[2], 0.05},
            }
        }

        local sprite = Sprite.new({
            pos = {math.random(-16,240), math.random(160,224)},
            sheet = spriteSheet
        })

        if dx < 0 then
            sprite.animation = birbAnims.left
        else
            sprite.animation = birbAnims.right
        end

        sprite.update = function(self, dt)
            Sprite.update(self, dt)
            age = age + dt

            if not flappy and flockX and flockX >= self.pos[1] then
                flappy = true
                self.animation = birbAnims.flap
            end

            if flappy then
                -- local ax = 2*(flockX + ox - self.pos[1] - dx*3)
                -- local ay = 2*(flockY + oy - self.pos[2] - dy*3)
                local ax = (flockX + ox - self.pos[1])/2
                local ay = (flockY + oy - self.pos[2])/3
                dx = dx + ax*dt
                dy = dy + ay*dt
                self.animSpeed = 0.2 + ax/30
            end

            self.pos[1] = self.pos[1] + dt*dx
            self.pos[2] = self.pos[2] + dt*dy
        end

        return sprite
    end

    local sky = {
        {image = imagepool.load('track2/parkbench-sky.png', {nearest=true})},
        {
            img = imagepool.load('track2/parkbench-clouds-1.png', {nearest=true}),
            x = math.random(0,255),
            update = function(self, dt)
                self.x = self.x + dt*3/2
            end,
            draw = function(self)
                love.graphics.draw(self.img, self.x%256 - 256, 55)
                love.graphics.draw(self.img, self.x%256, 55)
            end
        },
        {
            img = imagepool.load('track2/parkbench-clouds-2.png', {nearest=true}),
            x = math.random(0,255),
            update = function(self, dt)
                self.x = self.x + dt*3
            end,
            draw = function(self)
                love.graphics.draw(self.img, self.x%256 - 256, 13)
                love.graphics.draw(self.img, self.x%256, 13)
            end
        }
    }

    local bg = {
        {image = imagepool.load('track2/parkbench-bg.png', {nearest=true})},
        Sprite.new({
            pos = {120,112},
            sheet = spriteSheet,
            animation = {
                {quads.rose.open, 1.75},
                {quads.rose.blink, 0.1},
                {quads.rose.open, 1.25},
                {quads.rose.blink, 0.1},
                {quads.rose.open, 0.75},
                {quads.rose.blink, 0.1},
            }
        })
    }

    if not gregMissing then
        table.insert(bg, Sprite.new({
            pos = {131,112},
            sheet = spriteSheet,
            animation = {
                {quads.greg[1], 2},
                {quads.greg[2], 0.07},
                {quads.greg[3], 0.07},
                {quads.greg[2], 0.07},
                {quads.greg[1], 0.12},
                {quads.greg[2], 0.07},
                {quads.greg[3], 0.07},
                {quads.greg[2], 0.07},
                {quads.greg[1], 1.2},
                {quads.greg[2], 0.07},
                {quads.greg[3], 0.07},
                {quads.greg[2], 0.07},
                {quads.greg[1], 0.12},
                {quads.greg[2], 0.07},
                {quads.greg[3], 0.07},
                {quads.greg[2], 0.07},
            }
        }))
    end

    local fg = {}
    for _ = 1,64 do
        table.insert(fg, birb())
    end
    table.sort(fg, function(a,b)
        return a.pos[2] < b.pos[2]
    end)

    return {
        update = function(_, dt)
            time = time + dt
            if not gregMissing then
                flockX = (time - 1.5)*384
                flockY = 40 - 80*util.clamp(flockX/200,0,2)
            end

            updateLayers(sky, dt)
            updateLayers(bg, dt)
            updateLayers(fg, dt)
        end,
        draw = function(_)
            drawLayers(sky)
            drawLayers(bg)
            drawLayers(fg)

            return true
        end
    }
end

function scenes.doctor(game)
    local spriteSheet, quads = loadSprites("track2/doctor-sprites.png", "track2/doctor-sprites.lua")

    local cartpusher = Sprite.new({
        pos = {220, -16},
        sheet = spriteSheet,
        frame = quads.cartpusher
    })

    local function pushCart(when)
        if cartpusher.pos[2] < 224 then
            game:addAnimation({
                target = cartpusher,
                endPos = {cartpusher.pos[1], cartpusher.pos[2] + 12},
                easing = Animator.Easing.ease_out,
                duration = 0.25
            }, when)
            game.eventQueue:addEvent({
                what = pushCart,
                when = {when[1], when[2], when[3] + 1}
            })
        end
    end
    pushCart({0,0,0})

    local layers = {
        {image = imagepool.load('track2/doctor-bg.png', {nearest=true})},
        Sprite.new({
            pos = {120,112},
            sheet = spriteSheet,
            animation = {
                {quads.rose.open, 3.75},
                {quads.rose.blink, 0.1},
                {quads.rose.open, 1.75},
                {quads.rose.blink, 0.1},
                {quads.rose.open, 0.75},
                {quads.rose.blink, 0.1},
            }
        }),
        cartpusher
    }

    -- TODO medical staff wandering the hall, stepping on the beat

    return {
        update = function(_, dt)
            updateLayers(layers, dt)
        end,
        draw = function(_)
            drawLayers(layers)
            return true
        end
    }
end

function scenes.therapist()
    local spriteSheet, quads = loadSprites("track2/therapist-sprites.png", "track2/therapist-sprites.lua")

    local layers = {
        {image = imagepool.load('track2/therapist-bg.png', {nearest=true})},
        Sprite.new({
            pos = {120,112},
            sheet = spriteSheet,
            animation = {
                {quads.rose.open, 1.7},
                {quads.rose.blink, 0.1},
                {quads.rose.open, 2.3},
                {quads.rose.blink, 0.1},
                {quads.rose.open, 0.5},
                {quads.rose.blink, 0.1},
            }
        }),
        Sprite.new({
            pos = {152,112},
            sheet = spriteSheet,
            animation = {
                {quads.greg.open, 0.5},
                {quads.greg.blink, 0.1},
                {quads.greg.open, 1.5},
                {quads.greg.blink, 0.1},
                {quads.greg.open, 2.2},
                {quads.greg.blink, 0.1},
            }
        }),
        Sprite.new({
            pos = {216,92},
            sheet = spriteSheet,
            frame = quads.clock.pendulum,
            theta = 0,
            update = function(self, _, time)
                local beat = math.floor(time[3])
                local ofs = time[3] % 1

                local tgt = .35*((beat % 2)*2 - 1)
                local blend = util.smoothStep(math.min(1, ofs*3))
                self.theta = tgt*blend + -tgt*(1 - blend)
            end,
            draw = function(self)
                love.graphics.draw(self.sheet, self.frame,
                    self.pos[1], self.pos[2],
                    self.theta,
                    1, 1, 3, 0)
            end
        }),
        Sprite.new({
            pos = {208,80},
            sheet = spriteSheet,
            frame = quads.clock.face
        }),
        Sprite.new({
            pos = {118,178},
            sheet = spriteSheet,
            animation = {
                {quads.therapist[1], 1/3},
                {quads.therapist[2], 1/3}
            }
        })
        -- TODO therapist's hand
    }

    return {
        update = function(_, dt, time)
            updateLayers(layers, dt, time)
        end,
        draw = function(_)
            drawLayers(layers)
            return true
        end
    }
end

function scenes.vacation()
    local time = 0
    local beat = 0
    local waterMask = shaders.load('track2/waterMask.fs')
    waterMask:send('mask', imagepool.load('track2/vacation-watermask.png'))

    local spriteSheet, quads = loadSprites('track2/vacation-sprites.png', 'track2/vacation-sprites.lua')
    local filteredSprites = imagepool.load('track2/vacation-sprites.png') -- let this one be filtered

    local layers = {
        {image = imagepool.load('track2/vacation-bg.png', {nearest=true})},
        {
            image = imagepool.load('track2/vacation-water.png', {nearest=false}),
            draw = function(self)
                local theta = math.cos(beat*math.pi/2)
                local x = 8*math.sin(theta)
                local t = (beat/2)%1
                local y = 24 - 18*util.smoothStep(t)

                local depth = t < 0.5 and 1 or 1 - util.smoothStep((t - 0.5)*2)

                love.graphics.setShader(waterMask)
                love.graphics.setColor(7,131,189,255*depth)
                love.graphics.draw(self.image, x, y)
                love.graphics.setShader()

                love.graphics.setColor(5,81,138,255*depth)
                love.graphics.draw(self.image, x/2, 24 - 9*util.smoothStep(t))

                love.graphics.setColor(4,56,113,255)
                love.graphics.draw(self.image, 0, 24)

                love.graphics.setColor(255,255,255)
           end
        },
        {
            draw = function()
                local t = (beat/2) % 1

                -- y follows a circular arc
                local yt = t*2 - 1
                local y = 64 - 32*math.sqrt(1 - yt*yt)

                -- x follows the second half of smoothstep
                local xt = (t + 1)/2
                local xdir = (math.floor(beat/2) % 2)*2 - 1
                local x = 64 + xdir*(util.smoothStep(xt) - 0.75)*96

                local theta = math.sin(beat*math.pi/2)*math.pi/2
                love.graphics.draw(spriteSheet, quads.ball.base, x, y, theta, 1, 1, 8, 8)
            end
        },
        Sprite.new({
            pos = {120,112},
            sheet = spriteSheet,
            animation = {
                {quads.rose.open, 1.9},
                {quads.rose.blink, 0.1},
                {quads.rose.open, 1.4},
                {quads.rose.blink, 0.1},
            }
        }),
        Sprite.new({
            pos = {157,120},
            sheet = spriteSheet,
            animation = {
                {quads.greg[1], 1/3},
                {quads.greg[2], 1/3}
            }
        }),
    }

    return {
        update = function(_, dt, timePos)
            time = time + dt
            beat = timePos[3]

            updateLayers(layers, dt, time)
        end,
        draw = function(_)
            drawLayers(layers)
            return true
        end
    }
end

return scenes
