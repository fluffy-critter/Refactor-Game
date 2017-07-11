--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local input = {
    -- ramp time for digital inputs, in seconds
    rampTime = 0.25,

    -- current joystick position
    x = 0,
    y = 0
}

-- state to keep hidden from outsiders
local state = {
    x = 0,
    y = 0
}

function input.update(dt)
    local x, y = state.x, state.y

    local xDown, yDown

    if love.keyboard.isDown('right', 'd') then
        x = x + dt/input.rampTime
        xDown = true
    end
    if love.keyboard.isDown('left', 'a') then
        x = x - dt/input.rampTime
        xDown = true
    end
    if love.keyboard.isDown('up', 'w') then
        y = y - dt/input.rampTime
        yDown = true
    end
    if love.keyboard.isDown('down', 's') then
        y = y + dt/input.rampTime
        yDown = true
    end

    if not xDown then
        x = 0
    end
    if not yDown then
        y = 0
    end

    state.x = math.min(math.max(x, -1), 1)
    state.y = math.min(math.max(y, -1), 1)

    -- TODO actual joysticks should override this
    local mag = math.max(1, math.sqrt(state.x*state.x + state.y*state.y))
    input.x = state.x/mag
    input.y = state.y/mag
end

return input
