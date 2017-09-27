--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local cute = require('thirdparty.cute')
local notion = cute.notion
local check = cute.check
-- local minion = cute.minion
-- local report = cute.report

local dialog = require('track2.dialog')
local TextBox = require('track2.TextBox')
local scenes = require('track2.scenes')

local function checkAllDialogs(dlog, func)
    for state,items in pairs(dlog) do
        if type(items) == "table" then
            for _,item in pairs(items) do
                func(state, item)
            end
        end
    end
end

notion("Correct types", function()
    checkAllDialogs(dialog, function(state,item)
        print(state, item.text)
        check(type(item.text)).is("string")
        for _,response in ipairs(item.responses or {}) do
            if response[1] then
                check(type(response[1])).is("string")
            end
            check(type(response[2])).is("table")
            if response[3] then
                check(type(response[3])).is("string")
            end
        end
    end)
end)

notion("Text all fits within the dialog box", function()
    local box = TextBox.new({text="asdf"})

    local function checkLineCount(text, lines, padRight)
        local _, wrapped = box:getWrappedText(text or "", padRight)
        return #wrapped <= lines
    end

    checkAllDialogs(dialog, function(state,item)
        print(state, item.text)
        if not checkLineCount(item.text, 3) then
            error(state .. ": text too large: " .. item.text)
        end

        for _,response in ipairs(item.responses or {}) do
            print('', response[1])
            if not checkLineCount(response[1], 1, 4) then
                error(state .. ": response too long: " .. response[1])
            end
        end
    end)
end)


notion("State value speling", function()
    local set = {
        -- attributes set by the dialog engine itself
        silence_cur = "engine",
        silence_total = "engine",
        interrupted = "engine",
        phase = "engine",
        fun = "engine",
        importance = "engine", -- not actually set by engine but that's how it looks to the match rules

        -- attributes set by special callbacks
    }
    local used = {
        -- used by the engine
        importance = "engine",
    }

    local function checkPos(pos, where, status)
        if pos then
            for k,_ in pairs(pos) do
                where[k] = status
            end
        end
    end
    checkAllDialogs(dialog, function(status, item)
        checkPos(item.pos, used, status .. ':' .. item.text)
        checkPos(item.setPos, set, status .. ':' .. item.text)
        for _,response in ipairs(item.responses or {}) do
            checkPos(response[2], set, status .. ':' .. item.text .. ':' .. (response[1] or 'silence'))
        end
    end)

    for k,v in pairs(used) do
        if not set[k] then
            error("Attribute " .. k .. " used in status " .. v .. " but never set")
        end
    end

    for k,v in pairs(set) do
        if not used[k] then
            error("Attribute " .. k .. " set in status " .. v .. " but never used")
        end
    end
end)

notion("Dialog response integrity", function()
    local scene = scenes.kitchen()
    local greg = scene.greg

    checkAllDialogs(dialog, function(state,item)
        if item.responses then
            local errorText = state .. ':' .. item.text
            if #item.responses == 0 then
                error("Empty response list for " .. errorText)
            elseif #item.responses > 4 then
                error(errorText .. " has " .. #item.responses)
            end

            local yesCount = 0
            local silenceCount = 0
            for idx,r in ipairs(item.responses) do
                if r[1] then
                    yesCount = yesCount + 1
                else
                    silenceCount = silenceCount + 1
                end

                if not r[2] then
                    error(errorText .. ": response " .. idx .. " has no modifiers")
                end

                if r[3] and not dialog[r[3]] then
                    error(errorText .. ": response " .. idx .. " -> invalid state " .. r[3])
                end
            end

            -- if we have responses we always want exactly three spoken ones (but 0 is a warning)
            if yesCount > 0 and yesCount ~= 3 then
                error(errorText .. ": has " .. yesCount .. " verbal responses")
            end
            if silenceCount > 1 then
                error(errorText .. ": has " .. silenceCount .. " silent repsonses")
            end

            if item.pose then
                if type(item.pose) == 'string' and not greg.pose[item.pose] then
                    error(errorText .. ": nonexistent pose " .. item.pose)
                elseif type(item.pose) == 'table' then
                    for _,p in ipairs(item.pose) do
                        if not greg.pose[p] then
                            error(errorText .. ": nonexistent pose " .. p)
                        end
                    end
                end
            end
        end
    end)
end)

notion("Transition reasonable ranges", function()
    local minPhase = {}
    local maxPhase = {}

    -- set the max phases
    checkAllDialogs(dialog, function(state, item)
        if item.pos.phase then
            maxPhase[state] = math.max(item.pos.phase + 0.5, maxPhase[state] or item.pos.phase)
            minPhase[state] = math.min(item.pos.phase - 1, minPhase[state] or item.pos.phase)
        end
    end)

    local function testExtent(src, dest, when)
        local max = maxPhase[dest] or 0
        if when > max then
            error(src .. ": wants to transition to " .. dest .. " at " .. when .. ", max=" .. max)
        end
        local min = minPhase[dest] or 0
        if when < min then
            error(src .. ": wants to transition to " .. dest .. " at " .. when .. ", min=" .. min)
        end
    end

    -- check the max phases
    checkAllDialogs(dialog, function(state, item)
        if item.pos.phase then
            local errorText = state .. ':' .. item.text
            if item.setState then
                testExtent(errorText, item.setState, item.pos.phase)
            end

            for idx,r in ipairs(item.responses or {}) do
                if r[3] then
                    testExtent(errorText .. ':' .. idx, r[3], item.pos.phase)
                end
            end
        end
    end)
end)

notion("Transitions are meaningful", function()
    checkAllDialogs(dialog, function(state, item)
        if item.responses then
            local errorText = state .. ':' .. item.text
            for idx,r in ipairs(item.responses) do
                if not r[1] and not r[2] and not r[3] then
                    error(errorText .. " has spurious silence " .. idx)
                end

                if (r[3] == state and not item.setState) or (r[3] and r[3] == item.setState) then
                    error(errorText .. " has spurious transition " .. idx)
                end
            end
        end
    end)
end)

notion("Poses getting set enough", function()
    local posesSet = {}
    local rosesSet = {}
    local count = {}

    checkAllDialogs(dialog, function(state, item)
        if not item.pos.phase or item.pos.phase < 11 then
            count[state] = (count[state] or 0) + 1
            if item.pose then
                posesSet[state] = (posesSet[state] or 0) + 1
            end
            if item.rose then
                rosesSet[state] = (rosesSet[state] or 0) + 1
            end
        end
    end)

    for k,v in pairs(count) do
        print(k, v, posesSet[k], rosesSet[k])
        local poseRatio = (posesSet[k] or 0)/v
        if poseRatio < 0.5 then
            error(string.format("%s: only setting %.0f%% of poses", k, poseRatio*100))
        end
        local roseRatio = (rosesSet[k] or 0)/v
        if roseRatio < 0.25 then
            error(string.format("%s: only setting %.0f%% of roses", k, roseRatio*100))
        end
    end
end)
