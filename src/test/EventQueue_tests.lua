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

    eq:insert({when = {}, what = cb})
    eq:insert({when = {1}, what = cb})

    check(#eq.queue).is(2)
    check(eq:next()).shallowMatches({})

    eq:insert(
        {when = {2}, what = cb},
        {when = {2}, what = cb}
    )

    check(#eq.queue).is(4)
    check(eq:next()).shallowMatches({})

    eq:run({0})
    check(#eq.queue).is(3)
    check(count).is(1)
    check(lastRan).shallowMatches({0})
    check(eq:next()).shallowMatches({1})

    eq:run({0})
    check(count).is(1)

    eq:run({1})
    check(#eq.queue).is(2)
    check(count).is(2)
    check(lastRan).shallowMatches({1})

    eq:insert({when = {11}, what = cb})
    eq:run({10})

    check(count).is(4)
    check(#eq.queue).is(1)
    check(lastRan).shallowMatches({10})
    check(eq:next()).shallowMatches({11})

    eq:run({11})
    check(count).is(5)
    check(#eq.queue).is(0)
    check(lastRan).shallowMatches({11})
    check(eq:next()).is(nil)
end)
