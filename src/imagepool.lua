--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

imagepool = {}

imagepool.pool = {}
setmetatable(imagepool.pool, {__mode="v"})

function imagepool.load(filename)
    local img = imagepool.pool[filename]
    if not img then
        img = love.graphics.newImage(filename)
        imagepool.pool[filename] = img
    end
    return img
end

return imagepool