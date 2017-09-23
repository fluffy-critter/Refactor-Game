--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local config = require('config')
local util = require('util')

local input = {
    -- ramp time for digital inputs, in seconds
    rampTime = 1/6,

    -- dead zone for analog sticks
    deadZone = 0.1,

    -- current joystick position
    x = 0,
    y = 0,

    -- currently pressed buttons
    pressed = {},

    onPress = function(--[[key]])
        -- override this to get button/axis press events
    end,
    onRelease = function(--[[key]])
        -- override this to get button/axis release events
    end,
}

-- state to keep hidden from outsiders
local state = {
    padX = 0,
    padY = 0,
    analogPressed = {},
    padPressed = {}
}

-- map keys to the input mapping
local keyboardMap = config.keyboardMap or {}
util.applyDefaults(keyboardMap, {
    up = 'up',
    down = 'down',
    left = 'left',
    right = 'right',

    w = 'up',
    s = 'down',
    a = 'left',
    d = 'right',

    p = 'start',
    escape = 'back',
    f = 'fullscreen',

    ['return'] = 'a',
    space = 'a',
    z = 'b',
    x = 'a',

    ['.'] = config.debug and 'skip'
})

-- map gamepad buttons to the input mapping
local buttonMap = config.buttonmap or {}
util.applyDefaults(buttonMap, {
    dpup = 'up',
    dpdown = 'down',
    dpleft = 'left',
    dpright = 'right',

    a = 'a',
    b = 'b',
    x = 'x',
    y = 'y',

    back = 'back',
    start = 'start',

    rightshoulder = config.debug and 'skip'
})

local function handlePress(which, map)
    local event = map[which]
    if event and not input.pressed[event] then
        input.pressed[event] = true
        input.onPress(event)
    end
    if event then
        state.padPressed[event] = true
    end
    return event
end

local function handleRelease(which, map)
    local event = map[which]
    if event and input.pressed[event] then
        input.pressed[event] = false
        input.onRelease(event)
    end
    if event then
        state.padPressed[event] = false
    end
    return event
end

function love.gamepadpressed(_, button)
    -- print("gp pressed: " .. button)
    handlePress(button, buttonMap)
end

function love.gamepadreleased(_, button)
    -- print("gp released: " .. button)
    handleRelease(button, buttonMap)
end

local chainKeypressed = love.keypressed
function love.keypressed(key, code, isrepeat)
    -- print("kb pressed: " .. key, isrepeat)
    if not handlePress(key, keyboardMap) and chainKeypressed then
        chainKeypressed(key, code, isrepeat)
    end
end

local chainKeyreleased = love.keyreleased
function love.keyreleased(key, code)
    -- print("kb released: " .. key)
    if not handleRelease(key, keyboardMap) and chainKeyreleased then
        chainKeyreleased(key, code)
    end
end

function input.update(dt)
    --[[ hierarchy of things:

    analog position:
        if we have a stick that's in use, use that
        if not, d-pad-type inputs saturate towards 1 at the rate of dt/rampTime

    button presses:
        if we have d-pad-type inputs, use those
        if not, analog position > 0.6 triggers, < 0.4 releases

    ]]

    -- dpad positions
    local padX, padY = state.padX, state.padY
    local padRate = dt/input.rampTime

    -- analog positions
    local analogX, analogY = 0, 0

    -- handle the joysticks
    local joysticks = love.joystick.getJoysticks()
    for _,j in ipairs(joysticks) do
        local leftx = j:getGamepadAxis("leftx")
        if leftx and math.abs(leftx) > math.abs(analogX) then
            analogX = leftx
        end

        local lefty = j:getGamepadAxis("lefty")
        if lefty and math.abs(lefty) > math.abs(analogY) then
            analogY = lefty
        end
    end

    -- TODO also handle touch events

    if state.padPressed['left'] then
        padX = padX - padRate
    end
    if state.padPressed['right'] then
        padX = padX + padRate
    end
    if not state.padPressed['left'] and not state.padPressed['right'] then
        padX = 0
    end

    -- love treats up as <0, probably to make it match screen coords
    if state.padPressed['up'] then
        padY = padY - padRate
    end
    if state.padPressed['down'] then
        padY = padY + padRate
    end
    if not state.padPressed['up'] and not state.padPressed['down'] then
        padY = 0
    end

    padX = math.max(-1, math.min(padX, 1))
    padY = math.max(-1, math.min(padY, 1))

    -- generate pressed events based on stick position
    local function hysteresis(dir, val)
        if val and not state.analogPressed[dir] and val > 0.4 then
            state.analogPressed[dir] = true
            if not input.pressed[dir] then
                print("stick pressed: " .. dir)
                input.onPress(dir)
            end
            input.pressed[dir] = true
        elseif val and state.analogPressed[dir] and val < 0.3 then
            state.analogPressed[dir] = false
            if input.pressed[dir] then
                print("stick released: " .. dir)
                input.onRelease(dir)
            end
            input.pressed[dir] = false
        end
    end

    hysteresis('left', -analogX)
    hysteresis('right', analogX)
    hysteresis('up', -analogY)
    hysteresis('down', analogY)

    -- set our stick position as appropriate
    if analogX and math.abs(analogX) > input.deadZone then
        input.x = analogX
    else
        input.x = padX
    end

    if analogY and math.abs(analogY) > input.deadZone then
        input.y = analogY
    else
        input.y = padY
    end

    state.padX = padX
    state.padY = padY
end

return input
