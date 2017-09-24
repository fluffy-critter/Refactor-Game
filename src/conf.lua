--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

conf.lua - LÖVE configuration

]]

function love.conf(t)
    t.modules.joystick = true
    t.modules.physics = false
    t.window.resizable = true
    t.window.width = 1280
    t.window.height = 720
    t.window.fullscreen = false

    t.version = "0.10.2"

    t.identity = "SockpuppetRefactor"
    t.window.title = "Sockpuppet - Refactor"
end
