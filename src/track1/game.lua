--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local Game = {}

local StarterBall = require 'track1.StarterBall'

local function load()
    print("1.load")
    Game.music = love.audio.newSource('Refactor/01 little bouncing ball.mp3')

    Game.canvas = love.graphics.newCanvas(320, 240)
    Game.canvas:setFilter("nearest", "nearest")

    Game.board = {
        left = 8,
        right = 320 - 8,
        top = 8,
        bottom = 240
    }

    Game.paddle = {
        x = 160,
        y = 220,
        w = 20,
        h = 2,

        vx = 0,
        vy = 0,

        speed = 100,
        friction = 0.8,
        rebound = 0.5,
        tiltFactor = 0.05,

        -- get the upward vector for the paddle
        tiltVector = function(self)
            local x = self.vx * self.tiltFactor
            local y = -60
            local d = math.sqrt(x * x + y * y)
            return { x = x / d, y = y / d }
        end,

        getPolygon = function(self)
            local up = self:tiltVector()
            local rt = { x = -up.y, y = up.x }

            return {
                self.x + up.x*self.h - rt.x*self.w, self.y + up.y*self.h - rt.y*self.w,
                self.x + up.x*self.h + rt.x*self.w, self.y + up.y*self.h + rt.y*self.w,
                self.x - up.x*self.h + rt.x*self.w, self.y - up.y*self.h + rt.y*self.w,
                self.x - up.x*self.h - rt.x*self.w, self.y - up.y*self.h - rt.y*self.w
            }
        end
    }

    Game.balls = {}
    table.insert(Game.balls, StarterBall.new(Game))
end

function Game:setPhase(phase)
    if phase == 0 then
        self.music:play()
    end

    self.phase = phase
end

-- Find the distance between the point x0,y0 and the projection of the line segment x1,y1 -- x2,y2, with sign based on winding
local function linePointDistance(x0, y0, x1, y1, x2, y2)
    -- adapted from https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line#Line_defined_by_two_points
    local dx = x2 - x1
    local dy = y2 - y1
    return ((y2 - y1)*x0 - (x2 - x1)*y0 + x2*y1 - y2*x1)/math.sqrt(dx*dx + dy*dy)
end

-- check to see if a ball collides with a polygon; returns false if it's not collided, collision normal as {x,y} if it is
local function pointPolyCollision(x, y, r, poly)
    local npoints = #poly / 2
    local x1, y1, x2, y2
    local centerOutside = {}
    local nearest
    local nx, ny
    local edgeCount = 0

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

        print("collided on side " .. i)

        if d > 0 then
            -- the center is outside on this side
            edgeCount = edgeCount + 1
            print("centroid outside")
        end

        if nearest == nil or d > nearest then
            -- this is the closest edge so far
            nx = y2 - y1
            ny = x1 - x2
            nearest = d

            print("nearest, normal = ", nx, ny)
        end
    end

    -- if we were outside on multiple sides, we need to check corners instead
    if edgeCount > 1 then
        local minD, minX, minY
        for i = 1, npoints do
            x1 = poly[i*2 - 1]
            y1 = poly[i*2]

            local dx = x - x1
            local dy = y - y1
            local d = dx*dx + dy*dy
            if not minD or d < minD then
                nx = dx
                ny = dy
                minD = d
            end
        end
    end

    local mag = math.sqrt(nx*nx + ny*ny)
    if mag then
        return { nx / mag, ny / mag }
    end

    return { 0, 0 }
end

local function update(dt)
    local p = Game.paddle
    local b = Game.board

    if love.keyboard.isDown("right") then
        p.vx = p.vx + p.speed
    end
    if love.keyboard.isDown("left") then
        p.vx = p.vx - p.speed
    end
    p.vx = p.vx * p.friction

    p.x = p.x + dt * p.vx
    p.y = p.y + dt * p.vy

    if p.x + p.w > b.right then
        p.x = b.right - p.w
        p.vx = -p.vx * p.rebound
    end
    if p.x - p.w < b.left then
        p.x = b.left + p.w
        p.vx = -p.vx * p.rebound
    end

    local paddlePoly = p:getPolygon()

    local nextBalls = {}
    for _,ball in pairs(Game.balls) do
        local remove

        if ball:update(dt) == false then
            remove = true
        end

        -- check for collision with the paddle
        local c = pointPolyCollision(ball.x, ball.y, ball.r, paddlePoly)
        if c then
            if ball:onPaddle(c) == false then
                remove = true
            end
        end

        if not remove then
            table.insert(nextBalls, ball)
        end
    end
    Game.balls = nextBalls


end

local function draw()
    Game.canvas:renderTo(function()
        love.graphics.clear(0, 0, 0)

        -- draw the paddle
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.polygon("fill", Game.paddle:getPolygon())

        -- draw the balls
        for k,ball in pairs(Game.balls) do
            love.graphics.setColor(unpack(ball.color))
            love.graphics.circle("fill", ball.x, ball.y, ball.r)
        end
    end)
    return Game.canvas
end

return {
    load=load,
    update=update,
    draw=draw
}
