--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Useful utility functions

]]

local util = {}

-- Create an enum
function util.enum(...)
    local enum = {}
    local function checktype(o)
        if o.enum ~= enum then
            error("attempted to compare incompatible enum types")
        end
    end

    local meta = {
        __eq = function(o1, o2)
            checktype(o2)
            return o1.val == o2.val
        end,
        __lt = function(o1, o2)
            checktype(o2)
            return o1.val < o2.val
        end,
        __le = function(o1, o2)
            checktype(o2)
            return o1.val <= o2.val
        end,
        __tostring = function(o)
            return o.name
        end
    }

    local vals = {...}

    for k,v in ipairs(vals) do
        enum[v] = { enum = enum, val = k, name = v }
        setmetatable(enum[v], meta)
    end

    setmetatable(enum, {
        -- allows [de]serializing based on value, eg MyEnum(3)
        __call = function(_, n)
            return enum[vals[n]]
        end
    })

    return enum
end

-- Apply defaults to a dict
function util.applyDefaults(dest, defaults)
    for k,v in pairs(defaults) do
        if dest[k] == nil then
            dest[k] = v
        end
    end
end

-- Clamps n between low and high
function util.clamp(n, low, high)
    return math.max(low, math.min(n, high))
end

-- Returns true if a1 is lexically less than a2
function util.arrayLT(a1, a2)
    for k,v in ipairs(a1) do
        if a2[k] == nil or v > a2[k] then
            return false
        elseif v < a2[k] then
            return true
        end
    end

    if #a1 < #a2 then
        return true
    end

    return false
end

-- Compares two arrays for equality
function util.arrayEQ(a1, a2)
    if #a1 ~= #a2 then return false end

    for k,v in ipairs(a1) do
        if v ~= a2[k] then
            return false
        end
    end

    return true
end

-- Makes an array comparable
local arrayComparableMeta = {
    __lt = util.arrayLT,
    __le = function(a1, a2)
        return not util.arrayLT(a2, a1)
    end,
    __eq = util.arrayEQ
}
function util.comparable(ret)
    setmetatable(ret, arrayComparableMeta)
    return ret
end

-- Generate a weak reference to an object
local weakRefMeta = {__mode="v"}
function util.weakRef(data)
    local weak = setmetatable({content=data}, weakRefMeta)
    return function() return weak.content end
end

-- linear interpolate from A to B, at point X = 0..1
function util.lerp(a, b, x)
    return a + (b - a)*x
end

-- render a shader from a source buffer to a destination buffer with a shader and args; return the buffers swapped
function util.mapShader(source, dest, shader, args)
    dest:renderTo(function()
        love.graphics.setBlendMode("replace", "premultiplied")
        love.graphics.setShader(shader)
        for k,v in pairs(args) do
            shader:send(k,v)
        end
        love.graphics.draw(source)
        love.graphics.setShader()
    end)
    return dest, source
end

-- premultiply a color
function util.premultiply(color)
    local a = color[4] or 255
    return {color[1]*a/255, color[2]*a/255, color[3]*a/255, a}
end

-- get the solutions to a quadratic equation; returns up to two values, or nil if complex
function util.solveQuadratic(a, b, c)
    local det = b*b - 4*a*c
    if det < 0 then
        return nil
    end
    if det == 0 then
        return -b/2/a
    end
    det = math.sqrt(det)
    return (-b - det)/2/a, (-b + det)/2/a
end

-- Select the most-preferred canvas format from a list of formats
local graphicsFormats = love.graphics.getCanvasFormats()
for k,v in pairs(graphicsFormats) do print(k,v) end
function util.selectCanvasFormat(...)
    print("Requesting formats: " .. table.concat({...}, " "))
    for i,k in ipairs({...}) do
        if graphicsFormats[k] then
            print("  got choice " .. i .. ": " .. k)
            return k
        end
    end
    print("  no suitable choice found")
    return nil
end

-- shuffle a list the right way
function util.shuffle(list)
    local indices = {}
    for i in ipairs(list) do
        indices[i] = i
    end
    local ret = {}
    while #indices > 0 do
        local idx = math.random(1,#indices)
        table.insert(ret, list[indices[idx]])
        indices[idx] = indices[#indices]
        table.remove(indices, #indices)
    end
    return ret
end

-- Implements the cubic smoothStep from x=0..1
function util.smoothStep(x)
    return x*x*(3 - 2*x)
end

--[[ Returns a game clock
BPM - tempo

limits - the limits for each cadence; e.g. {8,4} = 8 measures per phase, 4 beats per measure.
    Can go as deeply as desired; position array is returned as most-significant first

ofs - time offset for the start of the clock

Returns an object with methods:

timeToPos(time) - converts a numerical position to a position array
posToTime(pos) - converts a position array to a numerical position
posToDelta(pos) - converts a position array to a numerical delta
normalize(pos) - normalize an offset array with the proper modulus
addOffset(pos, delta) - add an offset array to a position array, returning a new position array
iterator(startTime, endTime, delta) - returns an iterator that starts at startTime, ends at endTime, incrs by delta
]]
function util.clock(BPM, limits, ofs)
    ofs = ofs or 0

    local timeToPos = function(time)
        local remaining = (time - ofs)*BPM/60
        local pos = {}
        for idx = #limits, 1, -1 do
            local sz = limits[idx]
            local v = remaining % sz
            pos[idx + 1] = v
            remaining = (remaining - v)/sz
        end
        pos[1] = remaining
        return pos
    end

    local posToDelta = function(pos)
        local beat = 0
        for idx,sz in ipairs(limits) do
            beat = (beat + (pos[idx] or 0))*sz
        end
        beat = beat + (pos[#limits + 1] or 0)
        return beat*60/BPM
    end

    local posToTime = function(pos)
        return posToDelta(pos) + ofs
    end

    local normalize = function(pos)
        return timeToPos(posToTime(pos))
    end

    local addOffset = function(time, delta)
        local newPos = {}
        for k,v in ipairs(delta) do
            newPos[k] = v + (time[k] or 0)
        end
        return normalize(newPos)
    end

    local iterator = function(startTime, endTime, delta)
        local pos = normalize(startTime)
        endTime = normalize(endTime)
        return function()
            if util.arrayLT(endTime, pos) then
                return nil
            end

            local ret = util.shallowCopy(pos)
            pos = addOffset(pos, delta)
            return ret
        end
    end


    return {
        timeToPos = timeToPos,
        posToTime = posToTime,
        posToDelta = posToDelta,
        normalize = normalize,
        addOffset = addOffset,
        iterator = iterator
    }
end

-- Like ipairs(sequence) except it can take arbitrarily many tables. Returns tbl,idx,value
function util.cpairs(...)
    local tables = {...}

    return coroutine.wrap(function()
        for _,tbl in ipairs(tables) do
            for idx,val in ipairs(tbl) do
                coroutine.yield(tbl,idx,val)
            end
        end
    end)
end

-- Like pairs(sequence) except it can take arbitrarily many tables. Returns tbl,key,val
function util.mpairs(...)
    local tables = {...}

    return coroutine.wrap(function()
        for _,tbl in ipairs(tables) do
            for key,val in pairs(tbl) do
                coroutine.yield(tbl,key,val)
            end
        end
    end)
end

-- Shallow copy a table
function util.shallowCopy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end

    local ret = {}
    for k,v in pairs(tbl) do
        ret[k] = v
    end
    return ret
end

-- Convert a list into a set
function util.set(...)
    local ret = {}
    for _,v in ipairs({...}) do
        ret[v] = true
    end
    return ret
end

-- Run a function on a sequence as a queue; the function takes an item, and returns whether the item has been consumed
function util.runQueue(queue, consume)
    local removes = {}
    for idx,item in ipairs(queue) do
        if consume(item) then
            table.insert(removes, idx)
        end
    end

    for i = #removes,1,-1 do
        queue[removes[i]] = queue[#queue]
        queue[#queue] = nil
    end
end

return util
