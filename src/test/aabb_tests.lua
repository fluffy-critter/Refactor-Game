--[[
Refactor

(c)2018 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

AABB tree tests

]]

local cute = require 'thirdparty.cute'
local notion = cute.notion
local check = cute.check

local AABBTree = require 'AABBTree'
local geom = require 'geom'

local function randomAABB()
    local x1, y1 = math.random(0, 1000), math.random(0, 1000)
    local x2, y2 = x1 + math.random(0, 1000), y1 + math.random(0, 1000)
    return x1, y1, x2, y2
end


notion("AABBTree stores a single item", function()
    local tree = AABBTree.new()
    local item = {}

    tree:put(item, 0, 0, 100, 100)

    check(#tree.root.children).is(0)
    check(#tree.root.items).is(1)

    check(#tree:find(50, 50, 52, 52)).is(1)
    for _,found in ipairs(tree:find(50, 50, 52, 52)) do
        check(found == item).is(true)
    end

    check(#tree:find(-100,-100,-50,-50)).is(0)

    check(#tree:find(-50, -50, 5, 5)).is(1)
    for _,found in ipairs(tree:find(-50, -50, 5, 5)) do
        check(found == item).is(true)
    end
end)

notion("AABBTree passes smoke test", function()
    local tree = AABBTree.new()
    local items = {}

    for n = 1,1000 do
        local x1, y1, x2, y2 = randomAABB()
        local item = {name = "item" .. n, bounds = {x1, y1, x2, y2}}
        table.insert(items, item)
        tree:put(item, x1, y1, x2, y2)
    end

    for _ = 1,100 do
        local x1, y1, x2, y2 = randomAABB()

        local naiveCounts = {}
        local treeCounts = {}

        for _,item in ipairs(items) do
            if geom.quadsOverlap(x1, y1, x2, y2, unpack(item.bounds)) then
                naiveCounts[item] = 1 + (naiveCounts[item] or 0)
            end
        end

        for _,item in ipairs(tree:find(x1, y1, x2, y2)) do
            treeCounts[item] = 1 + (treeCounts[item] or 0)
        end

        for _,item in ipairs(items) do
            check((treeCounts[item] or 0) < 2).is(true)
            check(naiveCounts[item]).is(treeCounts[item])
        end
    end
end)
