--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Some useful shaders
]]

local shaders = {
    hueshift =  love.graphics.newShader("shaders/hueshift.fs"),
    waterRipple = love.graphics.newShader("shaders/waterRipple.fs"),
    waterReflect = love.graphics.newShader("shaders/waterReflect.fs"),
    sphereDistort = love.graphics.newShader("shaders/sphereDistort.fs"),
    gaussToneMap = love.graphics.newShader("shaders/gaussToneMap.fs"),
    gaussBlur = love.graphics.newShader("shaders/gaussBlur.fs"),
    crtScaler = love.graphics.newShader("shaders/crtScaler.fs"),
}

return shaders
