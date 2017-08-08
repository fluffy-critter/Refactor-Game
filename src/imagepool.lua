--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local imagepool = {}

imagepool.pool = {}
setmetatable(imagepool.pool, {__mode="v"})

imagepool.lru = {}

function imagepool.load(filename, cfg)
    cfg = cfg or {}

    local key = filename

    if cfg.mipmaps then key = key .. "|mipmap" end
    if cfg.nearest then key = key .. "|nearest" end

    local img = imagepool.pool[key]
    if not img then
        img = love.graphics.newImage(filename, {mipmaps = cfg.mipmaps})
        if cfg.mipmaps then
            img:setMipmapFilter("linear")
        end

        if cfg.nearest then
            img:setFilter("nearest", "nearest")
        else
            img:setFilter("linear", "linear")
        end

        imagepool.pool[key] = img
    end

    -- TODO this isn't quite LRU behavior but eh, good enough?
    for idx,used in ipairs(imagepool.lru) do
        if used == img then
            local last = #imagepool.lru
            imagepool.lru[idx] = imagepool.lru[last]
            table.remove(imagepool.lru, last)
        end
    end
    table.insert(imagepool.lru, img)
    while #imagepool.lru > 30 do
        table.remove(imagepool.lru, 1)
    end

    return img
end

return imagepool