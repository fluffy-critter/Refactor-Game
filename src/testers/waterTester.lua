--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

water parameter test

]]

local waterTester = {}
local util = require('util')
local shaders = require('shaders')

function waterTester:init()
    local limits = love.graphics.getSystemLimits()

    self.canvas = love.graphics.newCanvas(1280, 720)

    self.layers = {}
    self.layers.arena = love.graphics.newCanvas(1280, 720, "rgba8", limits.canvasmsaa)
    self.layers.arena:renderTo(function()
        love.graphics.setColor(255, 255, 255)
        love.graphics.rectangle("fill", (1280 - 64)/2, (720 - 500)/2, 64, 500)
    end)

    self.layers.water = love.graphics.newCanvas(1280, 720, "rg32f")
    self.layers.waterBack = love.graphics.newCanvas(1280, 720, "rg32f")

    self.params = {
        fluidity = 1.5,
        damp = 0.913,
        timeMul = 15,
        rsize = 32,
        fresnel = 0.1,
        sampleRadius = 5.5,
    }

    self.music = {
        isPlaying = function() end,
        setPitch = function() end,
        pause = function() end,
        resume = function() end,
    }

    self.phase = 0
end

function waterTester:keypressed(key)
    if key == 'q' then
        self.params.damp = self.params.damp + 0.001
    elseif key == 'a' then
        self.params.damp = self.params.damp - 0.001
    elseif key == 'w' then
        self.params.fluidity = self.params.fluidity + 0.01
    elseif key =='s' then
        self.params.fluidity = self.params.fluidity - 0.01
    elseif key == 'e' then
        self.params.timeMul = self.params.timeMul + 0.1
    elseif key == 'd' then
        self.params.timeMul = self.params.timeMul - 0.1
    elseif key == 'r' then
        self.params.rsize = self.params.rsize + 0.5
    elseif key == 'f' then
        self.params.rsize = self.params.rsize - 0.5
    elseif key == 't' then
        self.params.fresnel = self.params.fresnel + 0.1
    elseif key == 'g' then
        self.params.fresnel = self.params.fresnel - 0.1
    elseif key == 'x' then
        self.params.sampleRadius = self.params.sampleRadius + 0.1
    elseif key == 'z' then
        self.params.sampleRadius = self.params.sampleRadius - 0.1
    elseif key == 'space' then
        self.layers.water:renderTo(function()
            love.graphics.clear(0,0,0)
        end)

        print("waterTerms = {")
        for k,v in pairs(self.params) do
            print("    " .. k .. " = " .. v .. ",")
        end
        print("}")
    end

end

function waterTester:update(dt)
    self.phase = self.phase + dt
    self.layers.water:renderTo(function()
        local ofsx = math.sin(self.phase*0.3)*720/2
        local ofsy = math.sin(self.phase*0.003)*320/2

        love.graphics.setColorMask(true, false, false, false)
        love.graphics.setColor(255, 0, 0)
        love.graphics.rectangle("fill", 1280/2 - 32 + ofsx, 720/2 - 32 + ofsy, 64, 64)
        love.graphics.setColor(-255, 0, 0)
        love.graphics.rectangle("fill", 1280/2 - 32 - ofsx, 720/2 - 32 - ofsy, 64, 64)
        love.graphics.setColorMask(true, true, true, true)
    end)

    self.layers.water, self.layers.waterBack = util.mapShader(self.layers.water, self.layers.waterBack,
        shaders.waterRipple, {
            psize = {self.params.sampleRadius/1280, self.params.sampleRadius/720},
            damp = self.params.damp,
            fluidity = self.params.fluidity,
            dt = dt*self.params.timeMul
        })
end

function waterTester:draw()
    self.canvas:renderTo(function()
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.clear(0,0,0,255)
        love.graphics.setColor(255, 255, 255, 255)

        love.graphics.setShader(shaders.waterReflect)
        shaders.waterReflect:send("psize", {1/1280, 1/720})
        shaders.waterReflect:send("rsize", self.params.rsize)
        shaders.waterReflect:send("fresnel", self.params.fresnel);
        shaders.waterReflect:send("source", self.layers.arena)
        shaders.waterReflect:send("bgColor", {0, 0, 0, 1})
        shaders.waterReflect:send("waveColor", {0, 0, 1, 1})
        love.graphics.draw(self.layers.water)
        love.graphics.setShader()

        -- love.graphics.setColor(20, 20, 20, 20)
        -- love.graphics.draw(self.layers.arena)
    end)

    return self.canvas
end

waterTester:init()
return waterTester