--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local cute = require('thirdparty.cute')
local notion = cute.notion
-- local check = cute.check
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

notion("Text all fits within the dialog box", function()
    local box = TextBox.new({text="asdf"})

    local function checkLineCount(text, lines, padRight)
        local _, wrapped = box:getWrappedText(text or "", padRight)
        return #wrapped <= lines
    end

    checkAllDialogs(dialog, function(state,item)
        if not checkLineCount(item.text, 3) then
            error(state .. ": text too large: " .. item.text)
        end

        for _,response in pairs(item.responses or {}) do
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

        -- attributes set by special callbacks
    }
    local used = {}

    local function checkPos(pos, where, status)
        for k,_ in pairs(pos) do
            where[k] = status
        end
    end
    checkAllDialogs(dialog, function(status, item)
        checkPos(item.pos, used, status .. ':' .. item.text)
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
                print("WARNING: Empty response list for " .. errorText)
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

            if item.pose and not greg.pose[item.pose] then
                error(errorText .. ": nonexistent pose " .. item.pose)
            end
        end
    end)
end)

