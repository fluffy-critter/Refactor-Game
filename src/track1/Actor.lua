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

local geom = require('geom')

local Actor = {}

function Actor:checkHitBalls(balls)
    -- default implementation - test each ball against the bounding circle and then the polygon, memoizing as we go
    local poly, aabb
    local bcircle = self:getBoundingCircle()

    local function checkBall(ball)
        if not self:isTangible(ball) then
            return false
        end

        if bcircle then
            if not geom.pointPointCollision(ball.x, ball.y, ball.r, unpack(bcircle)) then
                return false
            end

            -- TODO: fail the bound check if the ball is moving away as well
        end

        if not poly then
            poly = self:getPolygon()
            if not poly then
                return false
            end
        end

        if not aabb then
            aabb = geom.getAABB(poly)
            if not aabb then
                return false
            end
        end

        if not geom.pointAABBCollision(ball.x, ball.y, ball.r, aabb) then
            return false
        end

        return geom.pointPolyCollision(ball.x, ball.y, ball.r, poly)
    end

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

function Actor:getPolygon()
    return nil
end

function Actor:preUpdate(dt)
    -- no default
end

function Actor:postUpdate(dt)
    -- no default
end

function Actor:isTangible(ball)
    return true
end

function Actor:isAlive()
    return true
end

function Actor:onHitBall(nrm, ball)
    return false
end

function Actor:draw()
    -- no default
end

return Actor
