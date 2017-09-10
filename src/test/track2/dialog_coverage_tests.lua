--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

local cute = require('thirdparty.cute')
local util = require('util')
local notion = cute.notion

local dialog = require('track2.dialog')
local Game = require('track2.game')

-- whether to check dialog coverage
local CheckCoverage = false
local MaxLinkChecks = 5 -- maximum number of times to consider a dialog path
local MaxNodeVisits = 15 -- maximum number of times to consider a node total
local MaxNodeTimeVisits = 3 -- maximum number of times to consider a node in time
local TestDuration = 250000 -- how many probes to try

--[[ generate a dotfile that represents all possible conversation paths ]]
local function generateDotFile()
    local function nodeName(node)
        if not node then
            return "nil"
        end
        return "node_" .. tostring(node):sub(10)
    end

    local statePools = {}
    local function getPoolInfo(poolName)
        if not statePools[poolName] then
            statePools[poolName] = {
                limits = {},
                transitions = {}
            }
        end
        return statePools[poolName]
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
                local label = '{' .. state .. '|' .. item.text:gsub('"', '\\"'):gsub('\n', '\\n'):gsub('%%', '') .. '}'
                local posDesc = posToStr(item.pos)
                if posDesc then
                    label = label .. '|{' .. posDesc .. '}'
                end
                file:write(nodeName(item) .. ' [ label="' .. label .. '" shape="record"]\n')
            end
        end
    end

    local function clone(state)
        local ret = {}
        for k,v in pairs(state) do
            ret[k] = (k ~= "from") and util.shallowCopy(v) or v
        end

        return ret
    end

    local function printState(state)
        print(" node=" .. tostring(state.from))
        if state.from then
            print("    text=" .. state.from.text)
            print("    pos=" .. (state.from.pos and posToStr(state.from.pos) or "nil"))
        end
        print(" state=" .. state.dialogState)
        print(" dialogCounts=" .. tostring(state.dialogCounts))
        for k,v in pairs(state.dialogCounts) do
            print("   " .. tostring(k) .. ": " .. v)
        end
        print(" npc=" .. tostring(state.npc))
        for k,v in pairs(state.npc) do
            print("   " .. k .. " = " .. v)
        end

        if state.from and not state.dialogCounts[state.from] then
            error("Something awry")
        end
    end

    -- queue of states to visit
    local queue = {}
    local visited = {}

    for _,starts in ipairs(dialog.intro) do
        local startState = {
            dialogState = dialog.start_state,
            npc = {phase = 1},
            dialogCounts = {},
            weights = game.weights,
            offsets = game.offsets
        }
        util.applyDefaults(startState.npc, starts.pos)
        -- insert multiple times to account for nondeterminism
        for _ = 1,3 do
            table.insert(queue, startState)
        end
    end

    local links = {}
    local boxphasecounts = {}

    local floop = 0
    while #queue > 0 and floop < TestDuration do
        print(floop .. " queue size: " .. #queue)
        local idx = math.random(1,#queue)
        local here = queue[idx]
        table.remove(queue, idx)

        floop = floop + 1
        if floop % 200 == -1 then
            for i,q in pairs(queue) do
                print(i)
                printState(q)
            end
        end

        local prevCounts = 0
        for _,v in pairs(here.dialogCounts) do
            prevCounts = prevCounts + v
        end

        local from = clone(here)
        local node = (from.npc.phase < 13) and game.chooseDialog(here)

        local fromState = getPoolInfo(from.dialogState)
        for k,v in pairs(from.npc) do
            if not fromState.limits[k] then
                fromState.limits[k] = {v,v}
            else
                fromState.limits[k] = {
                    math.min(fromState.limits[k][1], v),
                    math.max(fromState.limits[k][2], v)
                }
            end
        end

        if not node then
            local exit = (from.npc.phase < 13 and 'EARLY_EXIT' or 'END')
            local choiceLink = nodeName(here.from) .. ' -> ' .. exit
            if not links[choiceLink] then
                print(choiceLink)
                file:write(choiceLink .. '\n')
            end
            links[choiceLink] = (links[choiceLink] or 0) + 1
            fromState.transitions[exit] = true
        end

        if node then
            visited[node] = (visited[node] or 0) + 1
            boxphasecounts[node] = (boxphasecounts[node] or {})
            local bpc = boxphasecounts[node]
            local phs = math.floor(here.npc.phase*4)
            bpc[phs] = (bpc[phs] or 0) + 1

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
                file:write(choiceLink .. '\n')
            end
            links[choiceLink] = (links[choiceLink] or 0) + 1

            if node.setState then
                here.dialogState = node.setState
                fromState.transitions[node.setState] = true
            end

            if node.onReach then
                node.onReach(here.npc)
            end

            here.from = node

            if node.responses
                and links[choiceLink] <= MaxLinkChecks
                and bpc[phs] <= MaxNodeTimeVisits
                and visited[node] <= MaxNodeVisits then
                local silence = {nil,{}}

                for _,response in pairs(node.responses) do
                    if response[1] then
                        local responded = clone(here)
                        responded.choiceText = response[1]
                        for k,v in pairs(response[2]) do
                            responded.npc[k] = (responded.npc[k] or 0) + v
                        end
                        if response[3] then
                            responded.dialogState = response[3]
                            fromState.transitions[response[3]] = true
                        end

                        -- interruption type: interrupted text, fast close, play through
                        for _,interruption in ipairs({{true, true}, {true, false}, {false, false}}) do
                            -- response speed: fast, slow
                            for _,responseSpeed in ipairs({0.25, 0.5}) do
                                local version = clone(responded)
                                local time = responseSpeed

                                if interruption[1] then
                                    version.npc.interrupted = (version.npc.interrupted or 0) + 1
                                else
                                    time = time + 0.25
                                end
                                if not interruption[2] then
                                    time = time + 0.25
                                end

                                version.npc.phase = version.npc.phase + time
                                version.npc.silence_cur = 0
                                table.insert(queue, version)
                            end
                        end
                    else
                        silence = response
                    end
                end

                -- add the silence response
                for k,v in pairs(silence[2]) do
                    here.npc[k] = (here.npc[k] or 0) + v
                end
                if silence[3] then
                    here.dialogState = silence[3]
                    fromState.transitions[silence[3]] = true
                end
                here.npc.silence_total = (here.npc.silence_total or 0) + 1
                here.npc.silence_cur = (here.npc.silence_cur or 0) + 1

                -- interruption type: interrupted text, fast close, play through
                for _,interruption in ipairs({{true, true}, {true, false}, {false, false}}) do
                    local version = clone(here)
                    local time = 0.5

                    if interruption[1] then
                        version.npc.interrupted = (version.npc.interrupted or 0) + 1
                    else
                        time = time + 0.25
                    end
                    if not interruption[2] then
                        time = time + 0.25
                    end

                    version.npc.phase = version.npc.phase + time

                    table.insert(queue, version)
                end
            elseif not node.responses then
                -- interruption type: interrupted text, fast close, play through
                for _,interruption in ipairs({{true, true}, {true, false}, {false, false}}) do
                    local version = clone(here)
                    local time = 0.25

                    if interruption[1] then
                        version.npc.interrupted = (version.npc.interrupted or 0) + 1
                    else
                        time = time + 0.25
                    end
                    if not interruption[2] then
                        time = time + 0.25
                    end

                    version.npc.phase = version.npc.phase + time

                    table.insert(queue, version)
                end
            end
        end
    end

    for k,v in pairs(statePools) do
        local stateNode = 'state_' .. k .. ' [shape=record label="' .. k
        for name,vals in pairs(v.limits) do
            stateNode = stateNode .. '|{' .. name .. '|' .. vals[1] .. '|' .. vals[2] .. '}'
        end
        stateNode = stateNode .. '"]'
        file:write(stateNode .. '\n')
        for dest in pairs(v.transitions) do
            if dest ~= k then
                file:write('state_' .. k .. ' -> state_' .. dest .. '\n')
            end
        end
    end

    file:write("}\n")
    file:close()

    return visited
end

notion("dialog coverage", function()
    if not CheckCoverage then
        return
    end

    local visited = generateDotFile()
    local unvisited = {}

    -- every node should have been visited at least once
    for state,items in pairs(dialog) do
        if type(items) == "table" then
            for _,item in pairs(items) do
                if not visited[item] then
                    table.insert(unvisited, state .. ":" .. item.text)
                end
            end
        end
    end

    for _,missing in ipairs(unvisited) do
        print("Not visited: " .. missing)
    end

    -- check(#unvisited).is(0)
end)
