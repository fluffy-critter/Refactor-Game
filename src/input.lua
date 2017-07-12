--[[
Refactor

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local input = {
    -- ramp time for digital inputs, in seconds
    rampTime = 0.33,

    -- dead zone for analog sticks
    deadZone = 0.1,

    -- current joystick position
    x = 0,
    y = 0,

    onPress = function(key)
        -- override this to get button/axis press events
    end,
    onRelease = function(key)
        -- override this to get button/axis release events
    end,
}

-- state to keep hidden from outsiders
local state = {
    padX = 0,
    padY = 0,
    analogX = 0,
    analogY = 0,
    pressed = {},
}

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
    local analogX, analogY

    -- buttons which are pressed
    local pressed = {}

    -- Handle the keyboard
    pressed['up']    = pressed['up']    or love.keyboard.isDown('up',    'w')
    pressed['down']  = pressed['down']  or love.keyboard.isDown('down',  's')
    pressed['left']  = pressed['left']  or love.keyboard.isDown('left',  'a')
    pressed['right'] = pressed['right'] or love.keyboard.isDown('right', 'd')
    pressed['start'] = pressed['start'] or love.keyboard.isDown('p')
    pressed['back']  = pressed['back']  or love.keyboard.isDown('esc')
    pressed['fire']  = pressed['fire']  or love.keyboard.isDown('space', 'enter')

    pressed['skip']  = pressed['skip']  or love.keyboard.isDown('.')

    -- handle the joysticks
    local joysticks = love.joystick.getJoysticks()
    for _,j in ipairs(joysticks) do
        analogX = analogX or j:getGamepadAxis("leftx")
        analogY = analogY or j:getGamepadAxis("lefty")

        pressed['up']    = pressed['up']    or j:isGamepadDown("dpup")
        pressed['down']  = pressed['down']  or j:isGamepadDown("dpdown")
        pressed['left']  = pressed['left']  or j:isGamepadDown("dpleft")
        pressed['right'] = pressed['right'] or j:isGamepadDown("dpright")
        pressed['start'] = pressed['start'] or j:isGamepadDown("start")
        pressed['back']  = pressed['back']  or j:isGamepadDown("back")
        pressed['fire']  = pressed['fire']  or j:isGamepadDown("a")

        pressed['skip']  = pressed['skip']  or j:isGamepadDown("rightshoulder")
    end

    -- TODO also handle touch events

    if pressed['left'] then
        padX = padX - padRate
    end
    if pressed['right'] then
        padX = padX + padRate
    end
    if not pressed['left'] and not pressed['right'] then
        padX = 0
    end

    if pressed['up'] then
        padY = padY + padRate
    end
    if pressed['down'] then
        padY = padY - padRate
    end
    if not pressed['up'] and not pressed['down'] then
        padY = 0
    end

    padX = math.max(-1, math.min(padX, 1))
    padY = math.max(-1, math.min(padY, 1))

    -- TODO manage pressed for up/down/left/right based on analogX/analogY

    -- TODO this should really be handled using love.joystickpressed, love.joystickreleased
    -- see which buttons are now pressed but weren't before
    for k,v in pairs(pressed) do
        if v and not state.pressed[k] then
            input.onPress(k)
        end
    end

    -- see which buttons are now released
    for k,v in pairs(state.pressed) do
        if v and not pressed[k] then
            input.onRelease(k)
        end
    end

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
    state.pressed = pressed
end

return input
