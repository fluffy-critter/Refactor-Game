--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Design:

dialog top-level object contains pools

each pool contains a bunch of fragments, in the form of:

    poolName = {
        pos = {...}, -- position in the parameter space
        text = "...", -- text displayed by the NPC
        responses = { -- choice box to create afterwards (if nil, just select another dialog)
            { "responseText", {paramchanges}, "poolChange" } -- text to show (nil = silence), adjustments to the parameter space, name of pool to jump to (optional)
        },
        setPool = "pool" -- which pool to switch to if we get to this point (used for no responses),
    },

"pos" matches against attributes including the following:

    phase - music phase (fractional?)

    interruptions - the number of times the player has interrupted NPC's speech

    silences - how many times in a row the player has been silent

Only attributes present in the snippet's position will be considered; any attribute present in the snippet but not in the current position will be treated as 0.

]]

dialog = {
    state = "intro",

    -- starting point
    intro = {
        {
            pos = {},
            text = "Good morning, dear!",
            responses = {
                {"Uh... hi...", {concern = +1}, "normal"},
                {"Who the hell are you?", {concern = +1, defense = +1}, "brain_problems"},
                {"What are you doing here?", {defense = +1}, "normal"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {concern = 2},
            text = "Good morning... how are you feeling today?",
            responses = {
                {"I'm... fine...", {concern = +1}, "normal"},
                {"Uh, fine, but... who are you?", {concern = -1}, "brain_problems"},
                {"What are you doing in my house?", {}, "brain_problems"},
                {nil, {defense = +1}, "silence"}
            }
        },
        {
            pos = {anger = 5},
            text = "Good morning.",
            responses = {
                {"...good morning...", {concern = +1, tired = +1}, "normal"},
                {"Who are you?", {concern = +1, defense = -1}, "brain_problems"},
                {"What are you doing here?", {anger = +3}, "alienated"},
                {nil, {anger = +1}, "silence"}
            }
        }
    },

    -- path where Rose never responds
    silence = {
        {
            pos = {phase = 2, anger = 3},
            text = "I said, good morning.",
            responses = {}
        },
        {
            pos = {phase = 2, anger = 0},
            text = "Hello? I said good morning.",
            responses = {}
        },
        {
            pos = {phase = 3},
            text = "Is everything okay?",
            responses = {}
        },
        {
            pos = {phase = 4},
            text = "Why are you looking at me like that?",
            responses = {}
        },
        {
            pos = {phase = 5},
            text = "Please, tell me what's wrong...",
            responses = {}
        },
        {
            pos = {phase = 6, anger = 0},
            text = "This isn't like you.",
            responses = {}
        },
        {
            pos = {phase = 6, anger = 5},
            text = "This is just like you.",
            responses = {}
        },
        {
            pos = {phase = 7, defense = 3},
            text = "Is this about what I said last night? It was only a joke.",
            responses = {}
        },
        {
            pos = {phase = 7, defense = 0, anger = 0},
            text = "Is this about what I said last night? I'm sorry, it was out of line.",
            responses = {
                {"...What did you say?", {concern = +2}, "brain_problems"},
                {"Yes, it was.", {defense = +1}, "normal"},
                {"It isn't that...", {defense = -1, anger = -1, concern = +2}, "normal"}
            }
        },
        {
            pos = {phase = 7, defense = 2, anger = 5},
            text = "If this is about what I said last night, well, you deserved it.",
            responses = {}
        },
        {
            pos = {phase = 8, defense = 0, anger = 0},
            text = "I'm just not sure why you're giving me the silent treatment, here...",
            responses = {}
        },
        {
            pos = {phase = 8, defense = 2, anger = 5},
            text = "So you can cut it out with the silent treatment.",
            responses = {}
        },
        {
            pos = {phase = 9},
            text = "...",
            responses = {}
        },
        {
            pos = {phase = 10, defense = 0, anger = 0, concern = 5},
            text = "Hahaha... please... just tell me, what's going on...?",
            responses = {}
        },
        {
            pos = {phase = 10, defense = 0, anger = 5, concern = -5},
            text = "Ha ha, fine, don't tell me anything...",
            responses = {}
        },

        {
            pos = {phase = 11},
            text = "Are you... are you crying?",
            responses = {
                {"no, I...", {}},
                {"y....yes....", {}},
                {"what's happening...", {concern=10}, "brain_problems"}
            }
        },
        {
            pos = {phase = 11.5},
            text = "Hey, are you okay? You're looking a bit wobbly."
        },
        {
            pos = {phase = 12},
            text = "Yes, emergency services? It's my spouse, I think they're having a stroke."
        },
        {
            pos = {phase = 12.5},
            text = "Someone is coming.... everything will be okay.",
            setPool = "stroke"
        },
    },

    -- path where Greg thinks everything is normal
    normal = {
    },

    -- path where Greg has determined Rose is having brain problems
    brain_problems = {
    },

    -- path where Greg is feeling alienated
    alienated = {
    },

    -- path where Greg has given up on helping Rose
    gave_up = {

    },

    -- state where Greg believes Rose is having a stroke
    stroke = {},

}


return dialog