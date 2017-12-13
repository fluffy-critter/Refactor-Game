--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Profiler thingus. Inspired by classic 'CRT-scanline' profiling techniques.

]]

local util = require('util')

local profiler = {}

local font = love.graphics.newFont(16)

local frameTime
local contexts = {}
local context

local function hook()
    local info = debug.getinfo(2)
    if info then
        local where = tostring(info.name) .. info.source .. ':' .. info.linedefined
        context.counts[where] = (context.counts[where] or 0) + 1
        context.total = context.total + 1
    end
end

function profiler.attach(name, dt)
    if dt then
        frameTime = dt
    end

    if not contexts[name] then
        contexts[name] = {
            counts = {},
            total = 0
        }
    end
    context = contexts[name]

    context.startTime = love.timer.getTime()

    debug.sethook(hook, "", 100)
end

function profiler.detach()
    debug.sethook()

    context.totalTime = love.timer.getTime() - context.startTime
    context = nil
end

function profiler.draw()
    if total == 0 then
        return
    end

    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setBlendMode("alpha")
    local y0 = 0

    local activeTime = 0
    for _,ctx in pairs(contexts) do
        activeTime = activeTime + ctx.totalTime
    end

    for _,ctx in pairs(contexts) do
        local y = y0
        local h0 = love.graphics.getHeight()*ctx.totalTime/activeTime
        local dy = h0/ctx.total
        for k,count in util.spairs(ctx.counts, function(t,a,b) return t[b] < t[a] end) do
            local h = dy * count
            love.graphics.rectangle("line", 0, y, 10, h)
            if h > 8 then
                love.graphics.setFont(font)
                love.graphics.setColor(255,255,255)
                love.graphics.print(k, 15, y)
            end
            y = y + h
        end
        y0 = y0 + h0

        for k,v in pairs(ctx.counts) do
            ctx.counts[k] = v*.9
        end
        ctx.total = ctx.total*.9
    end
    love.graphics.pop()
end

return profiler
