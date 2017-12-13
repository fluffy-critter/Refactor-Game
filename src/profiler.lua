--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Profiler thingus. Inspired by classic 'CRT-scanline' profiling techniques.

]]

local util = require('util')

local profiler = {}

local font = love.graphics.newFont(16)

local counts = {}
local total = 0

function profiler.attach(context)
    print("attaching profiler for " .. context)
    debug.sethook(function()
        local info = debug.getinfo(2)
        if info then
           local where = tostring(info.name) .. info.source .. ':' .. info.linedefined
           counts[where] = (counts[where] or 0) + 1
           total = total + 1
       end
    end, "", 100)
end

function profiler.detach()
    print("detach")
    debug.sethook()
end

function profiler.draw()
    print("drawing")
    if total == 0 then
        return
    end

    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setBlendMode("alpha")
    local y = 0
    local dy = love.graphics.getHeight()/total
    for k,count in util.spairs(counts, function(t,a,b) return t[b] < t[a] end) do
        local h = dy * count
        love.graphics.rectangle("line", 0, y, 10, h)
        if h > 8 then
            love.graphics.setFont(font)
            love.graphics.setColor(255,255,255)
            love.graphics.print(k, 15, y)
        end
        y = y + h
    end
    love.graphics.pop()

    counts = {}
    total = 0
end

return profiler
