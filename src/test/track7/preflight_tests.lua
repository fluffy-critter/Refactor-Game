--[[
Refactor: 7 - flight

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local cute = require('thirdparty.cute')
local notion = cute.notion
local check = cute.check

local Game = require('track7')

notion("test face is disabled", function()
    local g = Game.new()
    check(not g.monk.face).is(true)
end)
