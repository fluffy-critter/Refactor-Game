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
local Game = require('track2.game')

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

--[[ generate a dotfile that represents all possible conversation paths ]]
local function generateDotFile()
    local function nodeName(node)
        if not node then
            return "nil"
        end
        return "node" .. tostring(node):sub(10)
    end

    local game = Game.new()

    local file = love.filesystem.newFile("track2.dot")
    file:open("w")
    file:write("digraph {\nrankdir = LR\n")

    file:write(nodeName(nil) .. ' [ label = "start" ]\n')

    local function posToStr(pos)
        local posDesc
        for k,v in pairs(pos or {}) do
            posDesc = (posDesc and posDesc .. '|' or '') .. k .. '=' .. v
        end
        return posDesc
    end

    for state,items in pairs(dialog) do
        if type(items) == "table" then
            for _,item in pairs(items) do
                local label = '{' .. state .. '|' .. item.text:gsub('"', '\\"'):gsub('\n', '--'):gsub('%%', '') .. '}'
                local posDesc = posToStr(item.pos)
                if posDesc then
                    label = label .. '|{' .. posDesc .. '}'
                end
                file:write(nodeName(item) .. ' [ label="' .. label .. '" shape="record"]\n')
            end
        end
    end

    local function clone(tbl)
        if type(tbl) ~= "table" then
            return tbl
        end

        local ret = {}
        for k,v in pairs(tbl) do
            if type(v) == "table" and k ~= "from" then
                ret[k] = clone(v)
            else
                ret[k] = v
            end
        end

        return ret
    end

    local startState = {
        dialogState = dialog.start_state,
        npc = {phase = 1},
        dialogCounts = {},
        weights = game.weights
    }

    -- queue of states to visit
    local queue = {startState}
    local visited = {startState}

    local function deepCompare(tbl1, tbl2)
        for k,v in pairs(tbl1) do
            if not tbl2[k] then
                return false
            end
            if type(v) == "table" then
                if type(tbl2[k]) ~= "table" or not deepCompare(v, tbl2[k]) then
                    return false
                end
            elseif v ~= tbl2[k] then
                return false
            end
        end
        for k,v in pairs(tbl2) do
            if not tbl1[k] then
                return false
            end
            if type(v) == "table" then
                if type(tbl1[k]) ~= "table" or not deepCompare(v, tbl1[k]) then
                    return false
                end
            elseif v ~= tbl1[k] then
                return false
            end
        end
        return true
    end

    local function wasVisited(state)
        for _,v in ipairs(visited) do
            if deepCompare(v, state) then
                return true
            end
        end
        return false
    end

    local links = {}

    local floop = 0
    while #queue > 0 and floop < 20000 do
        print("queue size: " .. #queue)
        local here = queue[1]
        table.remove(queue, 1)

        if floop % 100 == 0 then
            for i,q in ipairs(queue) do
                print(i .. ": node=" .. tostring(q.from) .. ' npc=' .. posToStr(q.npc))
            end
        end

        local prevCounts = 0
        for _,v in pairs(here.dialogCounts) do
            prevCounts = prevCounts + v
        end

        local node = game.chooseDialog(here)

        if node then
            local postCounts = 0
            for _,v in pairs(here.dialogCounts) do
                postCounts = postCounts + v
            end
            print("dialog counts: " .. prevCounts .. ' -> ' .. postCounts)

            local choiceLink = nodeName(here.from) .. ' -> ' .. nodeName(node)
            -- if here.choiceText then
            --     choiceLink = choiceLink .. ' [label="' .. here.choiceText:gsub('"', '\\"') .. '"]'
            -- end
            if not links[choiceLink] then
                print(choiceLink)
                links[choiceLink] = true
                file:write(choiceLink .. '\n')
                floop = floop + 1
            end

            if node.onReach then
                node.onReach(here.npc)
            end

            local there = clone(here)
            there.from = node

            if node.responses then
                local silence = {nil,{}}

                for _,response in pairs(node.responses) do
                    if response[1] then
                        local responded = clone(there)
                        responded.choiceText = response[1]
                        for k,v in pairs(response[2]) do
                            responded.npc[k] = (responded.npc[k] or 0) + v
                        end
                        if response[3] then
                            responded.dialogState = response[3]
                        end

                        -- TODO track three box time changes: interrupted, closed, played through
                        -- TODO track three response time changes: fast, slow, silence
                        responded.npc.phase = responded.npc.phase + 0.5
                        responded.npc.silence_cur = 0

                        if not wasVisited(responded) then
                            table.insert(queue, responded)
                        end
                    else
                        silence = response
                    end
                end

                -- add the silence response
                for k,v in pairs(silence[2]) do
                    there.npc[k] = (there.npc[k] or 0) + v
                end
                there.npc.phase = there.npc.phase + 1
                there.npc.silence_total = (there.npc.silence_total or 0) + 1
                there.npc.silence_cur = (there.npc.silence_cur or 0) + 1
                if not wasVisited(there) then
                    table.insert(queue, there)
                end
            else
                -- TODO track box time changes: interrupted, closed, played through
                there.npc.phase = there.npc.phase + 1
                if not wasVisited(there) then
                    table.insert(queue, there)
                end
            end
        end
    end

    file:write("}\n")
    file:close()
end
-- generateDotFile()
