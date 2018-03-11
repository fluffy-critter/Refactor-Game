--[[
Refactor: 2 - Strangers

simple animated sprite class

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Sprite has the following properties:

sheet - the image that is referenced as the spritesheet
frame - the quad that represents the current frame in the spritesheet
animation - nil, or a sequence of {frame, duration} pairs
animSpeed - speed multiplier on the animation

]]

local util = require 'util'

local Sprite = {}

function Sprite.new(o)
    local self = o or {}
    setmetatable(self, {__index=Sprite})

    util.applyDefaults(self, {
        frameTime = 0,
        frameNum = 1,
        animSpeed = 1
    })

    return self
end

function Sprite:update(dt)
    if self.animation then
        if not self.frameNum or self.frameNum > #self.animation then
            self.frameNum = 1
        end
        self.frame = self.animation[self.frameNum][1]

        self.frameTime = self.frameTime + dt*self.animSpeed
        if self.frameTime > self.animation[self.frameNum][2] then
            self.frameTime = 0
            self.frameNum = self.frameNum + 1
            if self.frameNum > #self.animation then
                self.frameNum = 1
            end
        end
    end
end

return Sprite
