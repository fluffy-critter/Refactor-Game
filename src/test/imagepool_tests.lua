local imagepool = require('imagepool')
local cute = require('thirdparty.cute')
local notion = cute.notion
local check = cute.check
local minion = cute.minion
local report = cute.report


notion("images get loaded only once", function()
    minion("newImage", love.graphics, 'newImage')

    local shader1 = imagepool.load('mainmenu/ground.png')
    local shader2 = imagepool.load('mainmenu/ground.png')
    check(shader1 == shader2).is(true)
    check(report('newImage').calls).is(1)

    imagepool.pool = {}
    imagepool.lru = {}
end)

notion("images get LRU pooling", function()
    minion("newImage", love.graphics, 'newImage')

    imagepool.load('mainmenu/ground.png')
    imagepool.load('mainmenu/ground.png')
    imagepool.load('mainmenu/ground.png')
    imagepool.load('mainmenu/ground.png')
    imagepool.load('mainmenu/ground.png')
    check(report('newImage').calls).is(1)

    imagepool.load('mainmenu/forest-stuff.png')
    imagepool.load('mainmenu/forest-stuff.png')
    imagepool.load('mainmenu/forest-stuff.png')
    imagepool.load('mainmenu/forest-stuff.png')
    imagepool.load('mainmenu/forest-stuff.png')
    check(report('newImage').calls).is(2)

    imagepool.load('mainmenu/ground.png')
    imagepool.load('mainmenu/ground.png')
    imagepool.load('mainmenu/ground.png')
    imagepool.load('mainmenu/ground.png')
    imagepool.load('mainmenu/ground.png')
    check(report('newImage').calls).is(2)

    imagepool.pool = {}
    imagepool.lru = {}
end)

notion("image configs are unique", function()
    minion("newImage", love.graphics, 'newImage')

    local img1 = imagepool.load('mainmenu/ground.png')

    local img2 = imagepool.load('mainmenu/ground.png', {mipmaps = false})
    local img3 = imagepool.load('mainmenu/ground.png', {mipmaps = true})

    check(img1 == img2).is(true)
    check(img1 == img3).is(false)

    local img4 = imagepool.load('mainmenu/ground.png', {nearest = false})
    local img5 = imagepool.load('mainmenu/ground.png', {nearest = true})

    check(img1 == img4).is(true)
    check(img1 == img5).is(false)

    local img6 = imagepool.load('mainmenu/ground.png', {nearest = true, mipmaps = true})
    check(img1 == img6).is(false)

    check(report('newImage').calls).is(4)

    imagepool.pool = {}
    imagepool.lru = {}
end)

