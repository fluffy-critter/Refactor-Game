--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Event queue unit tests

]]

local cute = require('thirdparty.cute')
local notion = cute.notion
local check = cute.check

local EventQueue = require('EventQueue')

notion("the queue functions", function()
    local eq = EventQueue.new()
    local count = 0
    local lastRan

    local function cb(when)
        count = count + 1
        lastRan = when
    end

    eq:addEvent({when = {}, what = cb})
    eq:addEvent({when = {1}, what = cb})

    check(#eq.queue).is(2)
    check(eq.nextEvent).shallowMatches({})

    eq:addEvents({
        {when = {2}, what = cb},
        {when = {2}, what = cb},
    })

    check(#eq.queue).is(4)
    check(eq.nextEvent).shallowMatches({})

    eq:runEvents({0})
    check(#eq.queue).is(3)
    check(count).is(1)
    check(lastRan).shallowMatches({0})
    check(eq.nextEvent).shallowMatches({1})

    eq:runEvents({0})
    check(count).is(1)

    eq:runEvents({1})
    check(#eq.queue).is(2)
    check(count).is(2)
    check(lastRan).shallowMatches({1})

    print("before")
    for k,v in pairs(eq.queue) do
        print(k,v)
    end

    eq:addEvent({when = {11}, what = cb})
    eq:runEvents({10})

    print("after")
    for k,v in pairs(eq.queue) do
        print(k,v)
    end

    check(count).is(4)
    check(#eq.queue).is(1)
    check(lastRan).shallowMatches({10})
    check(eq.nextEvent).shallowMatches({11})

    eq:runEvents({11})
    check(count).is(5)
    check(#eq.queue).is(0)
    check(lastRan).shallowMatches({11})
    check(eq.nextEvent).is(nil)
end)
