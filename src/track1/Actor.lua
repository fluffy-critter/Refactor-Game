--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Actor functions:

getBoundingCircle() - get the bounding circle, in the form of {x, y, r}
getPolygon() - get the collision poly, in the form of {x1, y1, x2, y2, ...}, clockwise winding

preUpdate(dt) - prepare for the frame
postUpdate(dt) - handle the results of the update

isTangible(ball) - return whether this actor is tangible to the specified ball
isAlive() - return whether this actor should still persist

onHitBall(nrm, ball) - did a ball hit us?
    NOTE - it is up to us to apply any forces to the ball. ball:onHitActor(nrm,self) is a convenience method for this.

draw() - render the actor

]]

local Actor = {}

function Actor:getBoundingCircle()
    -- no default
end

function Actor:getPolygon()
    return {}
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
