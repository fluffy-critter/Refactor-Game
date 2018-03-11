--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

SoundGroup: a thing for managing a group of sounds

Takes the following members:

bgm - the background music we manage
sounds - individual sounds we manage

]]

local util = require 'util'

local SoundGroup = {}

function SoundGroup.new(o)
    local self = o or {}
    setmetatable(self, {__index = SoundGroup})

    util.applyDefaults(self, {
        paused = {},
        bgm = nil,
        pitch = 1,
        sounds = {}
    })

    return self
end

function SoundGroup:iter()
    return util.cpairs({self.bgm}, self.sounds)
end

function SoundGroup:play()
    self.bgm:play()
end

function SoundGroup:pause()
    for _,_,v in self:iter() do
        if v:isPlaying() then
            table.insert(self.paused, v)
            v:pause()
        end
    end
end

function SoundGroup:resume()
    for _,v in ipairs(self.paused) do
        v:resume()
    end
    self.paused = {}
end

function SoundGroup:stop()
    for _,_,v in self:iter() do
        v:stop()
    end
end

function SoundGroup:setPitch(pitch)
    -- TODO relative pitch adjustment?
    self.pitch = pitch
    for _,_,v in self:iter() do
        v:setPitch(pitch)
    end
end

function SoundGroup:getPitch()
    return self.pitch
end

function SoundGroup:setVolume(volume)
    for _,_,v in self:iter() do
        v:setVolume(volume)
    end
end

function SoundGroup:tell()
    return self.bgm:tell()
end

function SoundGroup:isPlaying()
    return self.bgm:isPlaying()
end

function SoundGroup:seek(pos)
    self.bgm:seek(pos)
end

return SoundGroup
