--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Useful utility functions

]]

local util = {}

function util.applyDefaults(dest, defaults)
    for k,v in pairs(defaults) do
        if dest[k] == nil then
            dest[k] = v
        end
    end
end

return util
