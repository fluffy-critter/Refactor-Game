local util = require('util')

notion("Enums thing the thing", function()
    local myEnum = util.enum("first", "second", "third")

    check(myEnum.first.val).is(1)
    check(myEnum(1).val).is(1)

    check(myEnum.first == myEnum(1)).is(true)
    check(myEnum.first == myEnum(2)).is(false)
    check(myEnum.first == myEnum(3)).is(false)

    check(myEnum.second == myEnum(1)).is(false)
    check(myEnum.second == myEnum(2)).is(true)
    check(myEnum.second == myEnum(3)).is(false)

    check(myEnum.third == myEnum(1)).is(false)
    check(myEnum.third == myEnum(2)).is(false)
    check(myEnum.third == myEnum(3)).is(true)
end)

notion("Enums sort lexically", function()
    local myEnum = util.enum("first", "second", "third")

    check(myEnum.second < myEnum.first).is(false)
    check(myEnum.second < myEnum.second).is(false)
    check(myEnum.second < myEnum.third).is(true)

    check(myEnum.second <= myEnum.first).is(false)
    check(myEnum.second <= myEnum.second).is(true)
    check(myEnum.second <= myEnum.third).is(true)

    check(myEnum.second == myEnum.first).is(false)
    check(myEnum.second == myEnum.second).is(true)
    check(myEnum.second == myEnum.third).is(false)

    check(myEnum.second >= myEnum.first).is(true)
    check(myEnum.second >= myEnum.second).is(true)
    check(myEnum.second >= myEnum.third).is(false)

    check(myEnum.second > myEnum.first).is(true)
    check(myEnum.second > myEnum.second).is(false)
    check(myEnum.second > myEnum.third).is(false)
end)

notion("applyDefaults works right", function()
    local defaults = { foo = 1, bar = 2 }
    local applyTo = { bar = 3, baz = 5 }
    util.applyDefaults(applyTo, defaults)

    check(applyTo.foo).is(1)
    check(applyTo.bar).is(3)
    check(applyTo.baz).is(5)
    check(applyTo.qwer).is(nil)
end)

notion("clamp", function()
    check(util.clamp(5,0,15)).is(5)
    check(util.clamp(-1,0,15)).is(0)
    check(util.clamp(100,0,15)).is(15)
end)

notion("array comparisons", function()
    check(util.arrayLT({1,2,3},{2,3,4})).is(true)
    check(util.arrayLT({1,2,3},{1,2,3})).is(false)
    check(util.arrayLT({1,2},{1,2,3})).is(true)
    -- TODO more of these
end)

notion("arrays are comparable", function()
    local a1 = util.comparable({1,2,3})
    local a2 = util.comparable({2,3,4})

    check(a1 < a1).is(false)
    check(a1 <= a1).is(true)
    check(a1 == a1).is(true)
    check(a1 >= a1).is(true)
    check(a1 > a1).is(false)
    check(a1 ~= a1).is(false)

    check(a1 < a2).is(true)
    check(a1 <= a2).is(true)
    check(a1 == a2).is(false)
    check(a1 >= a2).is(false)
    check(a1 > a2).is(false)
    check(a1 ~= a2).is(true)
end)

notion("color premultiplication", function()
    check(util.premultiply({255,255,255})).shallowMatches({255,255,255,255})
    check(util.premultiply({255,255,255,0})).shallowMatches({0,0,0,0})
end)

notion("quadratics", function()
    check({util.solveQuadratic(1, 0, -1)}).shallowMatches({-1,1})
    check(util.solveQuadratic(1, 0, 0)).is(0)
    check(util.solveQuadratic(1, 0, 1)).is(nil)
end)
