--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Design:

dialog top-level object contains named pools; each pool contains a bunch of fragments, in the form of:

    poolName = {
        pos = {...}, -- position in the parameter space
        text = "...", -- text displayed by the NPC
        responses = { -- choice box to create afterwards (if nil, just select another dialog)
            { "responseText", {paramchanges}, "poolChange" } -- text to show (nil = silence), adjustments to the parameter space, name of pool to jump to (optional)
        },
        setState = "state", -- which state to switch to if we get to this point
        max_count = ..., -- Maximum number of times this fragment can appear (default: 1)
    },

"pos" matches against attributes including the following:

    phase - music phase (fractional?)

    interrupted - the number of times the player has interrupted NPC's speech

    silence_cur - how many times in a row the player has been silent
    silence_total - how many times the player has been silent in all

Only attributes present in the snippet's position will be considered; any attribute present in the snippet but not in the current position will be treated as 0.

NOTE: Since this is stored as a module, please don't modify any of the table data within the game. Use sideband data to track stuff.

]]

local dialog = {
    start_state = "intro",

    -- starting point
    intro = {
        {
            pos = {},
            text = "Good morning, dear!",
            responses = {
                {"Uh... hi...", {concern = 1}, "normal"},
                {"Who the hell are you?", {concern = 1, defense = 1}, "last_night"},
                {"What are you doing here?", {defense = 1}, "normal"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {concern = 2},
            text = "Good morning... how are you feeling today?",
            responses = {
                {"I'm... fine...", {concern = 1}, "normal"},
                {"Uh, fine, but... who are you?", {concern = -1}, "brain_problems"},
                {"What are you doing in my house?", {}, "brain_problems"},
                {nil, {defense = 1}, "silence"}
            }
        },
        {
            pos = {anger = 5},
            text = "Good morning.",
            responses = {
                {"...good morning...", {concern = 1, tired = 1}, "normal"},
                {"Who are you?", {concern = 1, defense = 7}, "last_night"},
                {"What are you doing here?", {anger = 3}, "alienated"},
                {nil, {anger = 1}, "silence"}
            }
        }
    },

    -- path where Rose never responds
    silence = {
        {
            pos = {phase = 2, anger = 3},
            text = "I said, good morning.",
            responses = {
                {"Um... hello.", {concern = 1}, "normal"},
                {"Oh, sorry, I couldn't hear you.", {concern = -1}, "normal"},
                {"Mmhmm.", {defense = 1, anger = 2}, "anger"}
            }
        },
        {
            pos = {phase = 2, anger = 0},
            text = "Hello? I said good morning.",
            responses = {
                {"Um... hello.", {concern = 1}, "normal"},
                {"Oh, sorry, I couldn't hear you.", {concern = -1}, "normal"},
                {"Mmhmm.", {defense = 1, anger = 2}, "anger"}
            }
        },
        {
            pos = {phase = 3},
            text = "Is everything okay?",
            responses = {
                {"Not really.", {concern = 2}, "normal"},
                {"... Who are you?", {concern = 3}, "brain_problems"},
                {"Yeah, I guess.", {concern = 1}, "normal"}
            }
        },
        {
            pos = {phase = 4},
            text = "Why are you looking at me like that?",
            responses = {}
        },
        {
            pos = {phase = 5},
            text = "Please, tell me what's wrong... You can talk to me.",
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
                {"...What did you say?", {concern = 2}, "brain_problems"},
                {"Yes, it was.", {defense = 1}, "normal"},
                {"It isn't that...", {defense = -1, anger = -1, concern = 2}, "normal"}
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
            pos = {phase = 10, anger = 0},
            text = "Hahaha...\b\b please...\b\b just tell me, what's going on...?",
            responses = {}
        },
        {
            pos = {phase = 10, anger = 5},
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
            setState = "stroke"
        },

        -- fillers for the player advancing dialog manually
        {
            pos = {interrupted = 1},
            text = "Are you trying to say something?",
        },
        {
            pos = {interrupted = 2, phase = 3},
            text = "You look like you want to say something...",
        },
        {
            pos = {interrupted = 3, phase = 5},
            text = "Please, just tell me what you're trying to say...",
        },
        {
            pos = {interrupted = 3, phase = 5, anger = 3},
            text = "Well? Spit it out, already.",
        },
        {
            pos = {interrupted = 4, phase = 7, anger = 1},
            text = "You know you can tell me anything, right?",
        },
        {
            pos = {interrupted = 4, phase = 7},
            text = "You know you can tell me anything...",
        },
        {
            pos = {interrupted = 4, phase = 7},
            text = "Hon... Please.",
        },
        {
            pos = {interrupted = 4, phase = 7},
            text = "Please say something.",
        },
        {
            pos = {interrupted = 4},
            text = "Please say something. Anything.",
        },
        {
            pos = {interrupted = 5, phase = 8, anger = 0},
            text = "I love you, and I'm so worried about you.",
        },
        {
            pos = {interrupted = 5, phase = 8, anger = 2},
            text = "I love you. Please...\b\b Please talk to me.",
        },
        {
            pos = {interrupted = 5, phase = 8},
            text = "I just want to know why you aren't talking...",
        },
        {
            pos = {interrupted = 5, phase = 8},
            text = "Is there something I did?",
        },
        {
            pos = {interrupted = 12, phase = 4, anger = 1},
            text = "I mean...\b\b Why are you skipping my text\b if you don't\b have anything\b to say?",
        },

    },

    -- path where Greg thinks everything is normal
    normal = {
    },

    -- path where Greg thinks "who are you?" is metaphorically, about his behavior last night
    last_night = {

    },

    -- path where Greg has determined Rose is having brain problems
    brain_problems = {
    },

    -- path where Greg is feeling alienated
    alienated = {
    },

    -- path where Greg has given up on helping Rose
    gave_up = {
        {
            pos = {},
            text = "I just can't do this anymore. Goodbye."
        },
        {
            pos = {},
            text = "What does it matter? You won't even remember this anyway."
        },
        {
            pos = {},
            text = "\b .\b.\b.\b \b\bYou don't even...\b remember...\b\b me."
        }
    },

    -- state where Greg believes Rose is having a stroke
    stroke = {
        {
            pos = {},
            text = "Shh, shh, it's okay...\b\b Everything will be fine...",
        },
        {
            pos = {},
            text = "They'll be here soon.",
        },
        {
            pos = {},
            text = "I love you.\b We'll get through this.",
        },
        {
            pos = {},
            text = "It's okay, I'm here for you.",
        },
    },

}


return dialog