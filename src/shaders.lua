--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Some useful shaders
]]

local shaders = {
    hueshift =  love.graphics.newShader("shaders/hueshift.fs"),
    waterRipple = love.graphics.newShader("shaders/waterRipple.fs"),
    waterReflect = love.graphics.newShader("shaders/waterReflect.fs"),
    sphereDistort = love.graphics.newShader("shaders/sphereDistort.fs")
}

return shaders
