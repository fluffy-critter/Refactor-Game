--[[
Colorful Critter

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

conf.lua - initial configuration

]]

function love.conf(t)
    t.modules.joystick = false
    t.modules.physics = false
    t.window.resizable = true
    t.window.height = 480
    t.window.width = 640
    t.version = "0.10.2"

    t.window.title = "Sockpuppet - Refactor"
end
