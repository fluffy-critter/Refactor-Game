--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Actor functions:

checkHitBalls(balls) - run the collision loop for a bunch of balls
getBoundingCircle() - get the bounding circle, in the form of {x, y, r}
getPolygon() - get the collision poly, in the form of {x1, y1, x2, y2, ...}, clockwise winding

preUpdate(dt, rawt) - prepare for the frame (rawt = time without judder effect)
postUpdate(dt, rawt) - handle the results of the update

isTangible(ball) - return whether this actor is tangible to the specified ball
isAlive() - return whether this actor should still persist

onHitBall(nrm, ball) - did a ball hit us?
    NOTE - it is up to us to apply any forces to the ball. ball:onHitActor(nrm,self) is a convenience method for this.

draw() - render the actor

]]

local geom = require 'geom'

local Actor = {}

function Actor:getBoundingQuad()
    local bounds = self:getAABB()
    if bounds then
        return bounds
    end

    local poly = self:getPolygon()
    if poly then
        return geom.getAABB(poly)
    end

    local bcircle = self:getBoundingCircle()
    if bcircle then
        return {
            bcircle[1] - bcircle[3],
            bcircle[2] - bcircle[3],
            bcircle[1] + bcircle[3],
            bcircle[2] + bcircle[3]
        }
    end

    print(self, "no bounding quad")
    return nil
end

function Actor:checkHitBalls(balls)
    -- default implementation - test each ball against the bounding circle and then the polygon, memoizing as we go
    local poly, aabb, bcircle

    local function checkBall(ball)
        if not self:isTangible(ball) then
            return false
        end

        if bcircle == nil then
            bcircle = self:getBoundingCircle()
        end
        if not bcircle then
            return false
        end

        if not geom.pointPointCollision(ball.x, ball.y, ball.r, unpack(bcircle)) then
            return false
        end

        if poly == nil then
            poly = self:getPolygon() or false
        end
        if not poly then
            return false
        end

        if aabb == nil then
            aabb = self:getAABB() or geom.getAABB(poly) or false
        end
        if not aabb then
            return false
        end

        if not geom.pointAABBCollision(ball.x, ball.y, ball.r, aabb) then
            return false
        end

        return geom.pointPolyCollision(ball.x, ball.y, ball.r, poly)
    end

    --[[
        TODO store actors in a spatial partitioning structure and have the ball
        run the check against actors which are
        in nearby cells
    ]]
    for _,ball in pairs(balls) do
        local nrm = checkBall(ball)
        if nrm then
            self:onHitBall(nrm, ball)
        end
    end
end

function Actor:getBoundingCircle()
    -- no default
end

function Actor:getAABB()
    return nil
end

function Actor:getPolygon()
    return nil
end

function Actor:preUpdate(--[[dt]])
    -- no default
end

function Actor:postUpdate(--[[dt]])
    -- no default
end

function Actor:isTangible(--[[ball]])
    return true
end

function Actor:isAlive()
    return true
end

function Actor:onHitBall(--[[nrm, ball]])
    return false
end

function Actor:draw()
    -- no default
end

function Actor:drawPost()
    -- no default
end

return Actor
