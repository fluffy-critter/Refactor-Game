--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local cute = require('thirdparty.cute')
local util = require('util')
local notion = cute.notion
-- local check = cute.check
-- local minion = cute.minion
-- local report = cute.report

local dialog = require('track2.dialog')
local TextBox = require('track2.TextBox')
local Game = require('track2.game')

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

    local function checkLineCount(text, lines)
        local _, wrapped = box:getWrappedText(text or "")
        return #wrapped <= lines
    end

    checkAllDialogs(dialog, function(state,item)
        if not checkLineCount(item.text, 3) then
            error(state .. ": text too large: " .. item.text)
        end

        for _,response in pairs(item.responses or {}) do
            if not checkLineCount(response[1], 1) then
                error(state .. ": response too long: " .. response[1])
            end
        end
    end)
end)


notion("Position attributes spelled right", function()
    local speling = util.set(
        "anger",
        "concern",
        "confused",
        "defense",
        "interrupted",
        "phase",
        "sequence",
        "silence_cur",
        "silence_total"
    )

    local set = {
        -- attributes set by the dialog engine itself
        silence_cur = 1,
        silence_total = 1,
        interrupted = 1,
        phase = 1,

        -- attributes set by special callbacks
        sequence = 1,
    }
    local used = {}

    local function checkPos(pos, where)
        for k,_ in pairs(pos) do
            if not speling[k] then
                error("Check speling of " .. k)
            end
            where[k] = (where[k] or 0) + 1
        end
    end
    checkAllDialogs(dialog, function(_,item)
        checkPos(item.pos, used)
        for _,response in ipairs(item.responses or {}) do
            checkPos(response[2], set)
        end
    end)

    for k in pairs(used) do
        if not set[k] then
            error("Attribute " .. k .. " used but never set")
        end
    end

    for k in pairs(set) do
        if not used[k] then
            error("Attribute " .. k .. " set but never used")
        end
    end
end)

notion("Dialog response integrity", function()
    checkAllDialogs(dialog, function(state,item)
        if item.responses then
            local errorText = state .. ':' .. item.text
            if #item.responses == 0 then
                print("WARNING: Empty response list for " .. errorText)
            end

            if #item.responses > 4 then
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

            if yesCount > 3 then
                error(errorText .. ": has " .. yesCount .. " verbal responses")
            end
            if silenceCount > 1 then
                error(errorText .. ": has " .. silenceCount .. " silent repsonses")
            end
        end
    end)
end)

