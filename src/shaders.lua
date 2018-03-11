--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Some useful shaders
]]

local shaders = {}

shaders.pool = {}
setmetatable(shaders.pool, {__mode="v"})

shaders.lru = {}

function shaders.load(filename)
    local key = filename

    local shader = shaders.pool[key]
    if not shader then
        shader = love.graphics.newShader(filename)
        shaders.pool[key] = shader
    end

    -- TODO this isn't quite LRU behavior but eh, good enough?
    for idx,used in ipairs(shaders.lru) do
        if used == shader then
            local last = #shaders.lru
            shaders.lru[idx] = shaders.lru[last]
            table.remove(shaders.lru, last)
        end
    end
    table.insert(shaders.lru, shader)
    while #shaders.lru > 5 do
        table.remove(shaders.lru, 1)
    end

    return shader
end

return shaders
