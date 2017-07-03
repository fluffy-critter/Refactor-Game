--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

-- Find the distance between the point x0,y0 and the projection of the line segment x1,y1 -- x2,y2, with sign based on winding
local function linePointDistance(x0, y0, x1, y1, x2, y2)
    -- adapted from https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line#Line_defined_by_two_points
    local dx = x2 - x1
    local dy = y2 - y1
    return ((y2 - y1)*x0 - (x2 - x1)*y0 + x2*y1 - y2*x1)/math.sqrt(dx*dx + dy*dy)
end

-- check to see if a ball collides with a polygon; returns false if it's not collided, displacement vector as {x,y} if it is
local function pointPolyCollision(x, y, r, poly)
    local npoints = #poly / 2
    local x1, y1, x2, y2
    local centerOutside = {}
    local nx = 0
    local ny = 0

    x2 = poly[npoints*2 - 1]
    y2 = poly[npoints*2]
    for i = 1, npoints do
        x1 = x2
        y1 = y2
        x2 = poly[i*2 - 1]
        y2 = poly[i*2]

        local d = linePointDistance(x, y, x1, y1, x2, y2)
        if d > r then
            -- We are fully outside on this side, so we are outside
            return false
        end

        if d > -r then
            -- we are only partially intersecting on this wall, so we use this to apply the normal force
            local depth = r - d
            local px = y2 - y1
            local py = x1 - x2
            local mag = math.sqrt(px*px + py*py)
            nx = nx + px*depth/mag
            ny = ny + py*depth/mag
        end
    end

    local mag = math.sqrt(nx*nx + ny*ny)
    if mag then
        return { nx / mag, ny / mag }
    end

    -- uh oh, we're fully embedded in the object... TODO: handle this
    return { 0, 0 }
end

return {
    linePointDistance = linePointDistance,
    pointPolyCollision = pointPolyCollision
}
