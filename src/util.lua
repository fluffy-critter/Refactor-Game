--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Useful utility functions

]]

local util = {}

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

return util
