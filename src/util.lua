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
            return enum[n]
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
function util.comparable(ret)
    setmetatable(ret, {
        __lt = util.arrayLT,
        __le = function(a1, a2)
            return not util.arrayLT(a2, a1)
        end,
        __eq = util.arrayEQ
    })
    return ret
end

-- Generate a weak reference to an object
function util.weakRef(data)
    local weak = setmetatable({content=data}, {__mode="v"})
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
function util.selectCanvasFormat(...)
    for _,k in ipairs({...}) do
        if graphicsFormats[k] then
            return k
        end
    end
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


return util
