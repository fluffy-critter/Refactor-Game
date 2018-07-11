--[[
Refactor

(c)2018 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

AABB tree
]]

local geom = require 'geom'
local util = require 'util'

local AABBTree = {}

local Bucket = {}
function Bucket.new(parent)
    local self = {}
    setmetatable(self, {__index=Bucket})

    self.items = {}
    setmetatable(self.items, {__mode="v"})

    self.children = {}
    setmetatable(self.children, {__mode="v"})

    self.parent = parent

    return self
end

function AABBTree.new(o)
    local self = o or {}
    setmetatable(self, {__index=AABBTree})

    util.applyDefaults(self, {
        splitThreshold = 4
    })

    -- maps an object to its current bucket
    self.allObjects = {}
    setmetatable(self.allObjects, {__mode="k"})

    self.root = Bucket.new(self)

    return self
end

-- Add an item to the tree
function AABBTree:put(item, x1, y1, x2, y2)
    -- Is the object already in the tree?
    local node = self.allObjects[item]

    -- Search for the correct bucket to go into
    local bucket = self.root:findLeaf(x1, y1, x2, y2)

    -- Did it move between nodes? Then remove it from there
    if node and bucket ~= node.bucket then
        util.runQueue(node.bucket.items, function(test)
            return item == test
        end)
    end

    node = node or {}
    node.item = util.weakRef(item)
    node.bounds = {x1, y1, x2, y2}
    node.bucket = bucket
    self.allObjects[item] = node

    table.insert(bucket.items, node)
    bucket:updateBounds()
    bucket.noSplit = false

    return bucket
end

-- Find items within a search range
function AABBTree:find(x1, y1, x2, y2)
    local output = {}
    self:_find(self.root, output, x1, y1, x2, y2)
    return output
end

-- Internal recursive function for finding items
function AABBTree:_find(bucket, output, x1, y1, x2, y2)
    if #bucket.items > self.splitThreshold then
        print("splitting ", #bucket.items)
        bucket:split()
    end

    for _,node in ipairs(bucket.items) do
        if node and geom.quadsOverlap(x1, y1, x2, y2, unpack(node.bounds)) then
            local item = node.item()
            if item then
                table.insert(output, item)
            end
        end
    end

    for d,child in pairs(bucket.children) do
        print("child", d, "#items", #child.items, "bounds", unpack(child.bounds))
        if geom.quadsOverlap(x1, y1, x2, y2, unpack(child.bounds)) then
            self:_find(child, output, x1, y1, x2, y2)
        end
    end
end

-- Get the leaf bucket for an AABB
function Bucket:findLeaf(x1, y1, x2, y2)
    if not self.bounds then
        return self
    end

    local child = self.children[self:_cnum(x1, y1, x2, y2)]
    if child then
        return child:findLeaf(x1, y1, x2, y2)
    end
    return self
end

-- Get the child number for an AABB
function Bucket:_cnum(x1, y1, x2, y2)
    local sx, sy = (self.bounds[1] + self.bounds[3])/2,
        (self.bounds[2] + self.bounds[4])/2

    return (x1 < sx and 1 or 0) +
        (x2 > sx and 2 or 0) +
        (y1 < sy and 4 or 0) +
        (y2 > sy and 8 or 0)
end

-- Update our bounding coordinates
function Bucket:updateBounds()
    local x1, y1, x2, y2

    for _,_,node in util.cpairs(self.items, self.children) do
        local ix1, iy1, ix2, iy2 = unpack(node.bounds)
        x1 = math.min(x1 or ix1, ix1)
        x2 = math.max(x2 or ix2, ix2)
        y1 = math.min(y1 or iy1, iy1)
        y2 = math.max(y2 or iy2, iy2)
    end

    self.bounds = {x1, y1, x2, y2}
end

-- Split a bucket that's gotten too big
function Bucket:split()
    if self.noSplit then
        return
    end

    for _,item in ipairs(self.items) do
        local cnum = self:_cnum(unpack(item.bounds))
        if not self.children[cnum] then
            self.children[cnum] = Bucket.new(self)
        end
        table.insert(self.children[cnum].items, item)
    end

    local numChildren = 0
    for _,child in pairs(self.children) do
        numChildren = numChildren + 1
        child:updateBounds()
    end
    if numChildren == 1 then
        -- We only have a single child so cull it
        self.children = {}
        self.noSplit = true
    elseif numChildren > 1 then
        -- The items now live in child nodes instead
        self.items = {}
    end
end

return AABBTree
