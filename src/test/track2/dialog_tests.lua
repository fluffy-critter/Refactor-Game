--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local cute = require('thirdparty.cute')
local notion = cute.notion
local check = cute.check
local minion = cute.minion
local report = cute.report

local dialog = require('track2.dialog')
local TextBox = require('track2.TextBox')

notion("Text all fits within the dialog box", function()
    local box = TextBox.new({text="asdf"})

    local function checkLineCount(text, lines)
        local _, wrapped = box:getWrappedText(text or "")
        return #wrapped <= lines
    end

    for state,items in pairs(dialog) do
        if type(items) == "table" then
            for _,item in pairs(items) do
                if not checkLineCount(item.text, 3) then
                    error(state .. ": text too large: " .. item.text)
                end

                for _,response in pairs(item.responses or {}) do
                    if not checkLineCount(response[1], 1) then
                        error(state .. ": response too long: " .. response[1])
                    end
                end
            end
        end
    end
end)

