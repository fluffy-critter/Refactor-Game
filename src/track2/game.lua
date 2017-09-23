--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local DEBUG = false

local util = require('util')
local shaders = require('shaders')
local imagepool = require('imagepool')
local fonts = require('fonts')

local TextBox = require('track2.TextBox')

local EventQueue = require('EventQueue')
local Animator = require('Animator')
local SoundGroup = require('SoundGroup')

local Game = {
    META = {
        tracknum = 2,
        title = "strangers [PLAYTEST READY]",
        duration = 3*60 + 11
    }
}

function Game.new()
    local o = {}
    setmetatable(o, {__index=Game})

    o:init()
    return o
end

local BPM = 90
local clock = util.clock(BPM, {4, 4}, 0.25)

-- returns music position as {phase, measure, beat}. beat will be fractional.
function Game:musicPos()
    return clock.timeToPos(self.music:tell())
end

--[[ seeks the music to a particular spot, using the same format as musicPos(), with an additional timeOfs param
that adjusts it by seconds ]]
function Game:seekMusic(pos, timeOfs)
    self.music:seek(clock.posToTime(pos) + (timeOfs or 0))
end

function Game:init()
    self.BPM = BPM

    self.transcript = love.filesystem.newFile("strangers-" .. os.date("%Y%m%d-%H%M%S") .. ".txt")
    self.transcript:open("w")

    self.sounds = {}
    self.music = SoundGroup.new({
        bgm = love.audio.newSource('music/02-strangers.mp3'),
        sounds = self.sounds
    })

    self.phase = -1
    self.score = 0

    self.canvas = love.graphics.newCanvas(256, 224, util.selectCanvasFormat("rgb565", "rgba8"))
    self.canvas:setFilter("nearest")

    local blurFmt = util.selectCanvasFormat("rgba8", "rgb8")
    if blurFmt then
        self.back = love.graphics.newCanvas(256, 224, util.selectCanvasFormat("rgba8"))
        self.back:setFilter("nearest")
    end

    self.outputScale = 3
    self.scaled = love.graphics.newCanvas(256*self.outputScale, 224*self.outputScale)

    self.border = imagepool.load('track2/border.png', {premultiply=true})

    self.lyrics = require('track2.lyrics')
    self.lyricPos = 1
    self.nextLyric = self.lyrics[self.lyricPos]

    self.scenes = love.filesystem.load('track2/scenes.lua')()
    self.dialog = love.filesystem.load('track2/dialog.lua')()

    self.dialogCounts = {} -- sideband data for how many times each dialog has been seen
    self.nextDialog = {1} -- when to show the next dialog box
    self.nextTimeout = nil -- when the next dialog timeout is to occur
    self.dialogState = self.dialog.start_state

    -- the state of the NPC
    self.npc = {fun = math.random()*50}

    -- how much to emphasize an axis in the dialog scoring (default = 1)
    self.weights = {
        phase = 3,
        interrupted = 3,
        fun = 0.01,
        silence_cur = 10,
        silence_total = 7
    }

    -- how much to bias an axis by, if it's present in the match rule
    self.offsets = {
        silence_cur = 2,
        silence_total = 2
    }

    self.crtScaler = shaders.load("track2/crtScaler.fs")

    -- self.music.bgm:setVolume(0.1)

    self.sounds.print = love.audio.newSource("track2/printSound.wav", "static")
    self.sounds.print:setVolume(0.3)
    self.sounds.select = love.audio.newSource("track2/selectSound.wav", "static")
    self.sounds.select:setVolume(0.2)

    self.sounds.done = love.audio.newSource("track2/doneSound.wav", "static")
    self.sounds.done:setVolume(0.2)
    self.sounds.timeout = love.audio.newSource("track2/timeoutSound.wav", "static")
    self.sounds.timeout:setVolume(0.2)

    self.eventQueue = EventQueue.new()
    self.animator = Animator.new()

    self.flashColor = {0,0,0,0}
end

--[[
    trigger an animation with a known end time, right now

    anim - the Animation object
    startTime - when to start the animation (default: next frame)
    endTime - when to end the animation (default: anim.duration)
]]
function Game:addAnimation(anim, startTime, endTime)
    self.eventQueue:addEvent({
        when = startTime or {},
        what = function(now)
            if endTime then
                anim.duration = clock.posToTime(endTime) - clock.posToTime(now)
            end
            self.animator:add(anim, function(check)
                return anim.target == check.target
            end)
        end
    })
end

function Game:start()
    self.music:play()

    self.kitchenScene = self.scenes.kitchen()
    self.sceneStack = {self.kitchenScene}

    -- self.sceneStack = {self.scenes.parkBench()}

    -- animation: Greg walking down the stairs
    local scene = self.kitchenScene
    for y = 0, 13 do
        self:addAnimation(
            {
                target = scene.greg,
                endPos = {218, y*8 - 28},
                easing = Animator.Easing.ease_out,
                duration = 0.25,
                onStart = function()
                    scene.greg.frame = scene.frames.greg.down[2 + y % 2]
                end,
                onComplete = function()
                    scene.greg.frame = scene.frames.greg.down[1]
                end
            },
            {0, math.floor(y/4), y%4},
            {0, math.floor(y/4), y%4 + 0.5})
    end
    self.eventQueue:addEvent({
        when = {0, 3, 2.5},
        what = function()
            self:setPoseSequence(scene.greg, {"bottom_of_stairs", "right_of_rose", "facing_left"})
        end
    })

    self.eventQueue:addEvents({
        {
            when = {11},
            what = function()
                table.insert(self.sceneStack, self.scenes.phase11(16*60/BPM))
            end
        },
        {
            when = {11,2},
            what = function()
                self.kitchenScene.rose.animation = self.kitchenScene.rose.animations.crying
            end
        }
    })

    -- at {12,3,0.5} fade to white until {13}
    self:addAnimation({
        target = self,
        property = "flashColor",
        startPos = {255,255,255,0},
        endPos = {255,255,255,255},
        onStart = function(target)
            target.flashColor = {0,0,0,0}
        end,
    }, {12,3,.5}, {13})

    --[[
    at {13} choose a set of scenes based on ending dialog state; also change flashOut based on situation

    wtf, alienated - psychiatrist/therapist + vacation + park bench together -> kitchen/greg sitting next to
        rose at table (alienated he leans against them)

    brain_problems, stroke - hospital -> kitchen/greg sitting on couch, thinking

    gave_up - alone on park bench -> kitchen/no greg

    others - ???
    ]]

    self.eventQueue:addEvent({
        when = {13},
        what = function()
            -- choose a set of scenes based on dialog state

            local flashOut = {0,0,255,0}

            local selections

            if self.dialogState == "wtf" or self.dialogState == "alienated" then
                flashOut = {127,0,255,0}
                selections = {
                    self.scenes.missing("therapist"),
                    self.scenes.missing("vacation"),
                    self.scenes.missing("parkbench"),
                }
                -- self.miniGame = CardGame.new()
            elseif self.dialogState == "brain_problems" or self.dialogState == "stroke" then
                flashOut = {255,255,0,0}
                local hospital = self.scenes.hospital(clock.posToDelta({0,1}))
                local doctor = self.scenes.missing("doctor")
                local therapist = self.scenes.missing("therapist")
                local parkbench = self.scenes.missing("parkbench")

                selections = {
                    hospital,
                    doctor,
                    self.kitchenScene,
                    parkbench,

                    hospital,
                    self.kitchenScene,
                    doctor,
                    parkbench,

                    therapist,
                    self.kitchenScene,
                    doctor,
                    hospital,

                    self.kitchenScene,
                    self.scenes.missing("vacation"),
                    therapist,
                    doctor,
                }
                -- self.miniGame = CardGame.new()
            elseif self.dialogState == "gave_up" then
                flashOut = {0,0,255,0}
                selections = {self.scenes.missing("parkbench", true)}
                -- self.miniGame = PigeonGame.new()
            elseif self.dialogState == "vacation" then
                flashOut = {255,0,255,0}
                selections = {self.scenes.missing("vacation")}
            elseif self.dialogState == "herpderp" then
                selections = {
                    self.scenes.missing("what were you expecting")
                }
            else
                selections = {
                    self.scenes.missing("Unknown state:\n" .. self.dialogState)
                }
            end

            if selections and #selections > 1 then
                -- collate a list of greg poses
                local gregPoses = {}
                local rosePoses = {}

                -- TODO this should really just be sets of positions and frames/animations (including greg crying)
                for v in pairs(self.kitchenScene.greg.pose) do
                    table.insert(gregPoses, v)
                end

                for _,v in pairs(self.kitchenScene.rose.animations) do
                    table.insert(rosePoses, v)
                end

                -- cycle through the selections every other beat
                local idx = 1
                for when in clock.iterator({13}, {15,0,-1}, {0,0,2}) do
                    print(idx)
                    local which = selections[idx]
                    self.eventQueue:addEvent({
                        when = when, what = function()
                            print(which)
                            self.sceneStack = {which}

                            -- TODO just pop greg to a pose
                            self:setPose(self.kitchenScene.greg, gregPoses[math.random(#gregPoses)])
                            self.kitchenScene.rose.animation = rosePoses[math.random(#rosePoses)]
                        end
                    })
                    idx = (idx % #selections) + 1
                end
            elseif selections and #selections == 1 then
                self.sceneStack = selections
            else
                self.sceneStack = {self.scenes.missing(self.dialogState)}
            end

            -- set the fade to the new scenes
            self:addAnimation({
                target = self,
                property = "flashColor",
                startPos = {255,255,255,255},
                endPos = flashOut,
                easing = Animator.Easing.ease_out,
            }, {13}, {13,0,1})

            -- set the fade at the end of the instrumental
            self:addAnimation({
                target = self,
                property = "flashColor",
                startPos = {0,0,0,0},
                endPos = {0,0,0,255},
                easing = Animator.Easing.ease_out,
            }, {14,3,3}, {15,0,0})
            self:addAnimation({
                target = self,
                property = "flashColor",
                startPos = {0,0,0,255},
                endPos = {0,0,0,0},
                easing = Animator.Easing.ease_out,
            }, {15,0,0}, {15,1,0})
            self.eventQueue:addEvent({
                when = {15},
                what = function()
                    self.sceneStack = {self.scenes.endKitchen(self, self.dialogState)}
                end
            })
        end
    })
end

function Game:onButtonPress(button, code, isRepeat)
    if self.music:getPitch() < 0.5 then
        return
    end

    if button == 'skip' then
        print("tryin' ta skip")
        self:seekMusic({self.phase + 1})
        return true
    end

    if self.textBox then
        return self.textBox:onButtonPress(button, code, isRepeat)
    end
end

function Game:update(dt)
    local time = self:musicPos()

    self.eventQueue:runEvents(time)
    self.animator:update(dt)

    if time[1] > self.phase then
        print("phase = " .. self.phase)
        self.phase = time[1]
    end

    if self.nextLyric and util.arrayLT(self.nextLyric[1], time) then
        self.lyricText = self.nextLyric[2]
        self.lyricPos = self.lyricPos + 1
        self.nextLyric = self.lyrics[self.lyricPos]

        if self.lyricText then
            self:transcribe('\t♪ ' .. self.lyricText)
        end
    end

    if util.arrayLT(time, {12,3})
        and not self.textBox and self.nextDialog
        and not util.arrayLT(time, self.nextDialog)
    then
        print("advancing dialog")
        self.nextDialog = nil

        if self.nextChoices then
            self.textBox = self.nextChoices
            self.nextChoices = nil
            self.nextTimeout = self:getNextInterval(2, 4, -0.25)
        else
            self.npc.phase = time[1] + time[2]/4 + time[3]/16

            self:transcribe("\t" .. self.dialogState, self.npc)

            local node = self:chooseDialog(self.dialog)
            if node and not node.ended then
                self:transcribe("<NPC> " .. node.text)

                self.textBox = TextBox.new({
                    text = node.text,
                    cantInterrupt = node.cantInterrupt,
                    onInterrupt = node.onInterrupt,
                    printSound = self.sounds.print,
                    doneSound = self.sounds.done
                })

                local game = self
                self.textBox.onClose = function(textBox)
                    game:textFinished(textBox, node)
                end

                if node.setPos then
                    for k,v in pairs(node.setPos) do
                        self.npc[k] = v
                    end
                end

                if node.pose then
                    if type(node.pose) == "table" then
                        self:setPoseSequence(self.kitchenScene.greg, node.pose)
                    else
                        self:setPose(self.kitchenScene.greg, node.pose)
                    end
                end

                if node.rose then
                    print("setting rose animation to " .. node.rose)
                    local anim = self.kitchenScene.rose.animations[node.rose]
                    if not anim then
                        print("Warning: animation doesn't exist")
                    else
                        print(#anim .. " frames")
                    end
                    self.kitchenScene.rose.animation = self.kitchenScene.rose.animations[node.rose]
                end
            end

            self.nextTimeout = self:getNextInterval(2, 1, -0.25)
        end
    end

    if (self.textBox and self.textBox.state < TextBox.states.ready) then
        local extend = self:getNextInterval(1.5, 1, 0)
        if self.nextTimeout and util.arrayLT(self.nextTimeout, extend) then
            -- we're a chatosaurus, extend the timeout a little
            print("Extending timeout from " .. table.concat(self.nextTimeout,':') .. " to " .. table.concat(extend,':'))
            self.nextTimeout = extend
        end
    end

    if self.nextTimeout and not util.arrayLT(time, self.nextTimeout) then
        self.nextTimeout = nil
        if self.textBox then
            self.textBox:close()

            if self.textBox.choices then
                self.sounds.timeout:stop()
                self.sounds.timeout:rewind()
                self.sounds.timeout:play()
            end
        end
    end

    if self.textBox then
        self.textBox:update(dt)
        if not self.textBox:isAlive() then
            self.textBox = nil
        end
    end

    util.runQueue(self.sceneStack, function(scene)
        scene:update(dt)
    end)

    if util.arrayLT({17,1,0}, time) then
        if self.transcript then
            self.transcript:close()
        end
        self.gameOver = true
    end
end

function Game:getNextInterval(measures, beatRound, beatOfs)
    local now = self:musicPos()
    local nextBeat = (beatRound > 0 and math.floor(now[3]/beatRound)*beatRound) or 0
    local nextTime = clock.posToTime({now[1], now[2] + measures, nextBeat + (beatOfs or 0)})
    local nextPos = clock.timeToPos(nextTime)

    return nextPos
end

-- Called when the NPC textbox finishes
function Game:textFinished(textBox, node)
    if textBox.interrupted then
        print("moo")
        self.npc.interrupted = (self.npc.interrupted or 0) + 1
    else
        -- give it a fast cooldown
        self.npc.interrupted = (self.npc.interrupted or 0) / 2
    end

    if node.setState then
        print("new state = " .. node.setState)
        self.dialogState = node.setState
    end

    if node.responses then
        -- We have responses for this fragment...
        local choices = {}

        local silence = {}
        local onClose = function(cbox)
            if not cbox.selected then
                print("selection timed out")
                self.npc.silence_cur = (self.npc.silence_cur or 0) + 1
                self.npc.silence_total = (self.npc.silence_total or 0) + 1
                self:onChoice(silence)
            else
                self.npc.silence_cur = 0
            end
        end

        for _,response in ipairs(node.responses) do
            if response[1] then
                table.insert(choices, {
                    text = response[1],
                    onSelect = function()
                        print(response[1])
                        self:onChoice(response)
                    end,
                    debugText = response[3]
                })
            else
                -- no text means this is the timeout option
                silence = response
            end
        end

        print("choices: " .. #choices)

        self.nextChoices = TextBox.new({choices = choices, onClose = onClose, selectSound = self.sounds.select})
        self.nextDialog = self:getNextInterval(0.25, 1, 0)
    else
        self.nextDialog = self:getNextInterval(1, 2, 0)
    end
end

-- Called when the player makes a dialog choice (including timeout)
function Game:onChoice(response)
    if response[2] then
        for k,v in pairs(response[2]) do
            self.npc[k] = (self.npc[k] or 0) + v
            print(k .. " now " .. self.npc[k])
        end
    end
    if response[3] then
        self.dialogState = response[3]
        print("state now " .. self.dialogState)
    end

    self:transcribe("<you> " .. (response[1] or "(silence)"))

    self.nextDialog = self:getNextInterval(1, 2, 0)
end

function Game:transcribe(...)
    if not self.transcript then
        return
    end

    for idx,arg in ipairs({...}) do
        if idx > 1 then
            self.transcript:write('\t')
        end
        if type(arg) == "table" then
            self.transcript:write('[')
            local sep = ''
            for k,v in pairs(arg) do
                self.transcript:write(sep)
                sep = ','
                self.transcript:write(k .. '=' .. v)
            end
            self.transcript:write(']')
        else
            self.transcript:write(tostring(arg))
        end
    end
    self.transcript:write('\n')

    self.transcript:flush()
end

-- Get the next conversation node from the dialog tree
function Game:chooseDialog(dialog)
    if self.npc.gone then
        return nil
    end

    local minDistance, minNode

    for _,_,node in util.cpairs(dialog[self.dialogState], dialog.always) do
        if not self.dialogCounts[node] or self.dialogCounts[node] < (node.maxCount or 1) then
            local distance = (self.dialogCounts[node] or 0) + math.random()*0.1
            for k,v in pairs(node.pos or {}) do
                local dx = v - (self.npc[k] or 0)
                distance = distance + dx*dx*(self.weights[k] or 1) + (self.offsets[k] or 1)
            end
            if not minDistance or distance < minDistance then
                print("      d=" .. distance .. ": " .. node.text .. " d=" .. distance)
                minNode = node
                minDistance = distance
            end
        end
    end

    if minNode then
        print("NPC: " .. minNode.text .. " d=" .. minDistance)
        self.dialogCounts[minNode] = (self.dialogCounts[minNode] or 0) + 1
    end

    return minNode
end

-- set a pose of the Greg NPC
function Game:setPose(sprite, poseName, after)
    local pose = sprite.pose[poseName]
    if not pose then
        print("Warning: requested nonexistent pose " .. poseName)
        return
    end

    -- TODO: pathfinding? probably overkill...

    local dx = pose.pos and pose.pos[1] - sprite.pos[1] or 0
    local dy = pose.pos and pose.pos[2] - sprite.pos[2] or 0

    local animation = sprite.mapAnimation and sprite:mapAnimation(dx, dy, pose)
    local rate = animation and animation.walkRate or 32
    local speed = pose.speed or 1

    local duration = math.sqrt(dx*dx + dy*dy)/speed/rate

    self:addAnimation({
        target = sprite,
        easing = pose.easing,
        endPos = pose.pos,
        duration = pose.duration or duration,
        onStart = function()
            print("Started animation for " .. poseName)
            sprite.animation = animation
            sprite.animRate = speed
        end,
        onComplete = function()
            print("Completed animation for " .. poseName)
            if sprite.animation and sprite.animation.stop then
                sprite.frame = sprite.animation.stop
            end
            sprite.animation = nil

            if pose.onComplete then
                pose.onComplete(sprite)
            end

            if after then
                after()
            end
        end
    })
end

-- run a sequence of poses
function Game:setPoseSequence(sprite, poseList)
    local remain = util.shallowCopy(poseList)

    local function consume()
        local pose = remain[1]
        if not pose then
            return
        end
        table.remove(remain, 1)

        self:setPose(sprite, pose, consume)
    end
    consume()
end

function Game:draw()
    self.canvas:renderTo(function()
        love.graphics.clear(0, 0, 0, 255)

        love.graphics.setBlendMode("alpha")

        if self.phase < 17 then
            love.graphics.setColor(255, 255, 255)

            util.runQueue(self.sceneStack, function(scene)
                return not scene:draw()
            end)

            love.graphics.setBlendMode("alpha", "premultiplied")
            love.graphics.setColor(255, 255, 255)
            if self.phase >= 13 and self.phase < 15 then
                -- throb the border during the instrumental
                local musicPos = self:musicPos()
                local size = ((musicPos[1] - 13)*16 + musicPos[2]*4 + musicPos[3])*0.07/32
                local throb = 1 + size*(1 - math.sqrt(musicPos[3]%1))
                love.graphics.draw(self.border, 128, 112, 0, throb, throb, 128, 112)
            else
                love.graphics.draw(self.border)
            end
            love.graphics.setBlendMode("alpha")

            if self.flashColor and self.flashColor[4] and self.flashColor[4] > 0 then
                love.graphics.setColor(unpack(self.flashColor))
                love.graphics.rectangle("fill", 0, 0, 256, 224)
            end

            if self.textBox then
                self.textBox:draw()
            end
        end

        if self.lyricText then
            local font = fonts.chronoTrigger
            local width = font:getWrap(self.lyricText, 256)

            love.graphics.setColor(0, 0, 0, 127)
            love.graphics.rectangle("fill", 0, 0, width + 4, 14)

            love.graphics.setFont(font)
            love.graphics.setColor(255, 255, 255)
            love.graphics.print(self.lyricText, 2, 0)
        end

        if DEBUG then
            local y = fonts.debug:getHeight()

            love.graphics.setFont(fonts.debug)
            love.graphics.setColor(255,255,127)
            love.graphics.print(string.format("%d:%d:%.2f", unpack(self:musicPos()))
                .. ' ' .. self.dialogState, 0, y)
            y = y + fonts.debug:getHeight()

            for k,v in pairs({} or self.npc) do
                love.graphics.setColor(0, 0, 0)
                love.graphics.print(string.format("%s=%.1f", k, v), 1, y+1)
                love.graphics.setColor(255, 255, 127)
                love.graphics.print(string.format("%s=%.1f", k, v), 0, y)
                y = y + fonts.debug:getHeight()
            end

            if self.textBox and self.textBox.choices and self.textBox.index <= #self.textBox.choices then
                local nextState = self.textBox.choices[self.textBox.index].debugText or self.dialogState or 'nil'
                love.graphics.setColor(0, 0, 0)
                love.graphics.print("choice -> " .. nextState, 1, y+1)
                love.graphics.setColor(255, 255, 255)
                love.graphics.print("choice -> " .. nextState, 0, y)
                -- y = y + fonts.debug:getHeight()
            end
        end

    end)

    if self.back then
        self.back:renderTo(function()
            love.graphics.setBlendMode("alpha")
            love.graphics.setColor(255, 255, 255, 90)
            love.graphics.draw(self.canvas)
        end)
    end

    self.scaled:renderTo(function()
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setColor(255, 255, 255)
        local shader = self.crtScaler
        love.graphics.setShader(shader)
        shader:send("screenSize", {256, 224})
        love.graphics.draw(self.back or self.canvas, 0, 0, 0, self.outputScale, self.outputScale)
        love.graphics.setShader()
    end)
    return self.scaled, 4/3

end

return Game
