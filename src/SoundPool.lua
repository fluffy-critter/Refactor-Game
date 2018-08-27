--[[
Refactor

(c)2018 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

sound pool functions

]]

local SoundPool = {}

function SoundPool.new(o)
    local self = o or {}

    self.datas = {}
    self.sources = {}

    setmetatable(self, {__index = SoundPool})
    return self
end

function SoundPool:load(path)
    if not self.datas[path] then
        self.datas[path] = love.sound.newSoundData(path)
    end
    return self.datas[path]
end

-- Play a sound, optionally calling a pre-play callback first
function SoundPool:play(sdata, cb)
    if not self.sources[sdata] then
        self.sources[sdata] = {}
    end
    local spool = self.sources[sdata]

    local source
    for _,s in ipairs(spool) do
        if not s:isPlaying() then
            source = s
            break
        end
    end
    if not source then
        source = love.audio.newSource(sdata)
        table.insert(self.sources, source)
    end

    source:stop()
    if cb then
        cb(source)
    end
    source:play()
    return source
end

return SoundPool

