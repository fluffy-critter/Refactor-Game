--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local geom = {}

geom.collision_stats = {
    tests = 0,
    fail_aabb = 0,
    fail_face_inclusion = 0,
    pass_face_projection = 0,
    fail_corner_inclusion = 0
}

-- Check if two rectangles overlap (note: x2 must be >= x1, same for y)
function geom.quadsOverlap(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
    return (
        (ax1 < bx2) and
        (bx1 < ax2) and
        (ay1 < by2) and
        (by1 < ay2))
end

--[[ Find the distance between the point x0,y0 and the projection of the line segment x1,y1 -- x2,y2, with sign based on winding.
Outside (positive) is considered to the left of the line (i.e. clockwise winding)
]]
function geom.linePointDistance(x0, y0, x1, y1, x2, y2)
    -- adapted from https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line#Line_defined_by_two_points
    local dx = x2 - x1
    local dy = y2 - y1
    return (dy*x0 - dx*y0 + x2*y1 - y2*x1)/math.sqrt(dx*dx + dy*dy)
end

-- Project a point onto the line segment, and return where it is relative to x1,y1=0 x2,x2=1
function geom.projectPointToLine(x, y, x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1

    local xo = x - x1
    local yo = y - y1

    return (xo*dx + yo*dy)/(dx*dx + dy*dy)
end

-- Get the perpendicular line - NOT NORMALIZED
function geom.getNormal(x1, y1, x2, y2)
    return { y2 - y1, x1 - x2 }
end

-- Normalize a vector to a particular length
function geom.normalize(nrm, len)
    if len == nil then
        len = 1
    end

    local x, y = unpack(nrm)
    local d = math.sqrt(x*x + y*y)
    return {x*len/d, y*len/d}
end

-- check to see if a ball collides with a polygon (clockwise winding); returns false if it's not collided, displacement vector as {x,y} if it is
function geom.pointPolyCollision(x, y, r, poly)
    local cs = geom.collision_stats

    cs.tests = cs.tests + 1

    local npoints = #poly / 2

    local minx = poly[1]
    local maxx = poly[1]
    local miny = poly[2]
    local maxy = poly[2]
    for i = 2, npoints do
        local px = poly[i*2 - 1]
        local py = poly[i*2]
        minx = math.min(minx, px)
        maxx = math.max(maxx, px)
        miny = math.min(miny, py)
        maxy = math.max(maxy, py)
    end

    -- do the fast AABB test (no need to do it as quads)
    if ((x + r <= minx) or
        (x - r >= maxx) or
        (y + r <= miny) or
        (y - r >= maxy)) then

        cs.fail_aabb = cs.fail_aabb + 1
        return false
    end

    local x1, y1, x2, y2
    x2 = poly[npoints*2 - 1]
    y2 = poly[npoints*2]

    local dist = {}
    local proj = {}

    local maxSide
    local maxSideDist
    local maxSideNormal
    local maxSideProj

    for i = 1, npoints do
        x1 = x2
        y1 = y2
        x2 = poly[i*2 - 1]
        y2 = poly[i*2]

        dist[i] = geom.linePointDistance(x, y, x1, y1, x2, y2)
        proj[i] = geom.projectPointToLine(x, y, x1, y1, x2, y2)

        if dist[i] >= r then
            -- We are fully outside on this side, so we are outside
            cs.fail_face_inclusion = cs.fail_face_inclusion + 1
            return false
        end

        -- find the closest side
        if maxSide == nil or dist[i] > maxSideDist then
            maxSide = i
            maxSideDist = dist[i]
            maxSideNormal = geom.getNormal(x1, y1, x2, y2)
            maxSideProj = geom.projectPointToLine(x, y, x1, y1, x2, y2)
        end
    end

    -- is our center inside the nearest segment? If so, we just use its normal
    if maxSideProj >= 0 and maxSideProj <= 1 then
        cs.pass_face_projection = cs.pass_face_projection + 1
        return geom.normalize(maxSideNormal, r - maxSideDist)
    end

    -- we are using the nearest corner instead; fortunately in this case the center of the circle is going to be outside the poly
    local cornerX, cornerY
    local cornerDist2
    for i = 1, npoints do
        local cx = x - poly[i*2 - 1]
        local cy = y - poly[i*2]
        local cd = cx*cx + cy*cy
        if cornerDist2 == nil or cd < cornerDist2 then
            cornerDist2 = cd
            cornerX = cx
            cornerY = cy
        end
    end

    if cornerDist2 >= r*r then
        -- oops, after all that work it turns out we're not actually intersecting
        cs.fail_corner_inclusion = cs.fail_corner_inclusion + 1
        return false
    end

    return geom.normalize({cornerX, cornerY}, r - math.sqrt(cornerDist2))
end

-- Generate a random vector of a given length (default=1)
function geom.randomVector(length)
    local vx = math.random() - 0.5
    local vy = math.random() - 0.5
    return geom.normalize({vx, vy}, length)
end

return geom
