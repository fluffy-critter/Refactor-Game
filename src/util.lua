--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Useful utility functions

]]

local util = {}

-- Create an enum
function util.enum(...)
    local enum = {}
    for k,v in ipairs({...}) do
        enum[v] = k
    end
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
    for k,v in ipairs(a1) do
        if v ~= a2[k] then
            return false
        end
    end

    return #a1 == #a2
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

-- Weak reference (see https://stackoverflow.com/a/29110759/318857)
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

-- get the solutions to a quadratic equation; returns up two values, or nil if complex
function util.solveQuadratic(a, b, c)
    local det = b*b - 4*a*c
    if det < 0 then
        return nil
    end
    det = math.sqrt(det)
    return (-b - det)/2/a, (-b + det)/2/a
end

local graphicsFormats = love.graphics.getCanvasFormats()
-- print("supported graphics formats:")
-- for k,v in pairs(graphicsFormats) do
--     if v then print("\t" .. k) end
-- end
function util.selectCanvasFormat(...)
    for _,k in ipairs({...}) do
        if graphicsFormats[k] then
            return k
        end
    end
    return nil
end

-- shuffle a list
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

return util
