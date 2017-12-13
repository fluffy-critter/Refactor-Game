--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Profiler thingus. Inspired by classic 'CRT-scanline' profiling techniques.

]]

local util = require('util')

local profiler = {}

local font = love.graphics.newFont(16)

local frameTime
local context
local stats = {
    counts = {},
    total = 0
}

local lastTime

local function hook()
    local info = debug.getinfo(2)
    if info then
        local where = context .. ':' .. tostring(info.name) .. info.source .. ':' .. info.linedefined
        local now = love.timer.getTime()
        stats.counts[where] = (stats.counts[where] or 0) + now - lastTime
        stats.total = stats.total + now - lastTime
        lastTime = now
    end
end

function profiler.attach(name)
    context = name

    lastTime = love.timer.getTime()
    debug.sethook(hook, "", 73)
end

function profiler.detach()
    debug.sethook()
    context = nil
end

function profiler.draw()
    if total == 0 then
        return
    end

    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setBlendMode("alpha")

    local y = 0
    local dy = love.graphics.getHeight()/stats.total
    for k,count in util.spairs(stats.counts, function(t,a,b) return t[b] < t[a] end) do
        local h = dy * count
        love.graphics.rectangle("line", 0, y, 10, h)
        if h > 8 then
            love.graphics.setFont(font)
            love.graphics.setColor(255,255,255)
            love.graphics.print(k, 15, y)
        end
        y = y + h
    end

    for k,v in pairs(stats.counts) do
        stats.counts[k] = v*.9
    end
    stats.total = stats.total*.9

    love.graphics.pop()
end

return profiler
