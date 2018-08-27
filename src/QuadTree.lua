--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Quad tree

]]

local util = require 'util'

local QuadTree = {}

local weakRef = {__mode="v"}

function QuadTree.new(o)
    local self = o or {}
    setmetatable(self, {__index = QuadTree})

    util.applyDefaults(self, {
        maxDepth = nil,
        cx = (self.left + self.right)/2,
        cy = (self.top + self.bottom)/2,
        minSize = 1,
        items = {},
        children = {}
    })

    setmetatable(self.children, weakRef)
    return self
end

-- Find the quadtree node that should own this bounding rect
function QuadTree:find(bounds)
    if self.maxDepth == 0 then
        return self
    end

    local child
    local left, right, top, bottom

    -- find left/right axis
    if bounds[3] <= self.cx then
        child = 1
        left = self.left
        right = self.cx
    elseif bounds[1] >= self.cx then
        child = 2
        left = self.cx
        right = self.right
    else
        child = nil
    end

    if child then
        -- We have an X split, so let's find the Y split
        if bounds[4] <= self.cy then
            top = self.top
            bottom = self.cy
        elseif bounds[2] >= self.cy then
            child = child + 2
            top = self.cy
            bottom = self.bottom
        else
            child = nil
        end
    end

    if child and (right - left < self.minSize or bottom - top < self.minSize) then
        -- Bail out if the minimum size constraint is being violated
        -- This can happen for infimitessimally-small objects, and also
        -- for items which go outside of our top-level bounds
        child = nil
    end

    if not child then
        return self
    end

    local node = self.children[child]
    if not node then
        -- create a new child node
        -- print("creating new node for child " .. child)
        -- print("    our bounds", self.left, self.top, self.right, self.bottom)
        -- print("    center", self.cx, self.cy)
        -- print("    child bounds", left, top, right, bottom)
        node = QuadTree.new({
            parent = self,
            left = left,
            right = right,
            top = top,
            bottom = bottom,
            minSize = self.minSize,
            maxDepth = self.maxDepth and self.maxDepth - 1 or nil
        })
        self.children[child] = node
    end
    return node:find(bounds)
end

-- Insert the item into this node
function QuadTree:insert(item)
    self.items[item] = item
end

-- Remove the item from this quadtree node
function QuadTree:remove(item)
    self.items[item] = nil
end

--[[ Visit all items in the quadtree that are in nodes intersecting the bounds

    callback is function(item)
]]
function QuadTree:visit(bounds, callback)
    for item,_ in pairs(self.items) do
        callback(item)
    end

    -- Visit left children (1 and 3)
    if bounds[1] < self.cx then
        -- top
        if self.children[1] and bounds[2] <= self.cy then
            self.children[1]:visit(bounds, callback)
        end
        -- bottom
        if self.children[3] and bounds[4] >= self.cy then
            self.children[3]:visit(bounds, callback)
        end
    end

    -- Visit right children (2 and 4)
    if bounds[3] >= self.cx then
        -- top
        if self.children[2] and bounds[2] <= self.cy then
            self.children[2]:visit(bounds, callback)
        end
        -- bottom
        if self.children[4] and bounds[4] >= self.cy then
            self.children[4]:visit(bounds, callback)
        end
    end
end

return QuadTree
