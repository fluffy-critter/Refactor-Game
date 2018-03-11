local shaders = require 'shaders'
local cute = require 'thirdparty.cute'
local notion = cute.notion
local check = cute.check
local minion = cute.minion
local report = cute.report


notion("shaders get loaded only once", function()
    minion("newShader", love.graphics, 'newShader')

    local shader1 = shaders.load('shaders/gaussToneMap.fs')
    local shader2 = shaders.load('shaders/gaussToneMap.fs')
    check(shader1 == shader2).is(true)
    check(report('newShader').calls).is(1)

    shaders.pool = {}
    shaders.lru = {}
end)

notion("shaders get LRU pooling", function()
    minion("newShader", love.graphics, 'newShader')

    shaders.load('shaders/gaussToneMap.fs')
    shaders.load('shaders/gaussToneMap.fs')
    shaders.load('shaders/gaussToneMap.fs')
    shaders.load('shaders/gaussToneMap.fs')
    shaders.load('shaders/gaussToneMap.fs')
    check(report('newShader').calls).is(1)

    shaders.load('shaders/gaussBlur.fs')
    shaders.load('shaders/gaussBlur.fs')
    shaders.load('shaders/gaussBlur.fs')
    shaders.load('shaders/gaussBlur.fs')
    shaders.load('shaders/gaussBlur.fs')
    check(report('newShader').calls).is(2)

    shaders.load('shaders/gaussToneMap.fs')
    shaders.load('shaders/gaussToneMap.fs')
    shaders.load('shaders/gaussToneMap.fs')
    shaders.load('shaders/gaussToneMap.fs')
    shaders.load('shaders/gaussToneMap.fs')
    check(report('newShader').calls).is(2)

    shaders.pool = {}
    shaders.lru = {}
end)
