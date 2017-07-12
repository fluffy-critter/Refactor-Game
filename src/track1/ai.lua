--[[
Refactor: 1 - Little Bouncing Ball

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

AI utilities
]]

local ai = {}

-- compute the relative danger value for a given position
function ai.computeDanger(x, y, balls)
    local danger = 0
    for _,b in pairs(balls) do
        -- vector from ball to mob
        local dx = x - b.x
        local dy = y - b.y
        local dmag2 = dx*dx + dy*dy
        -- local vmag = math.sqrt(b.vx*b.vx + b.vy*b.vy)

        -- concordance is dot(d,v)/dm/vm
        -- danger is concordance*vm/dm
        -- therefore danger = concordance/(dm^2)

        local dd = (dx*b.vx + dy*b.vy)/(dmag2 + 1)
        if dd > 0 then
            danger = danger + dd
        end
    end
    return danger
end


return ai
