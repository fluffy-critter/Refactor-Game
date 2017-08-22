--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Design:

dialog top-level object contains named pools; each pool contains a bunch of fragments, in the form of:

    poolName = {
        pos = {...}, -- position in the parameter space
        text = "...", -- text displayed by the NPC
        responses = { -- choice box to create afterwards (if nil, just select another dialog)
            { "responseText", {paramchanges}, "poolChange" } --
                text to show (nil = silence),
                adjustments to the parameter space,
                name of pool to jump to (optional)
        },
        setState = "state", -- which state to switch to if we get to this point
        max_count = ..., -- Maximum number of times this fragment can appear (default: 1)
    },

"pos" matches against attributes including the following:

    phase - music phase (fractional?)

    interrupted - the number of times the player has interrupted NPC's speech

    silence_cur - how many times in a row the player has been silent
    silence_total - how many times the player has been silent in all

Only attributes present in the snippet's position will be considered; any attribute present in the snippet but not in
the current position will be treated as 0.

NOTE: Since this is stored as a module, please don't modify any of the table data within the game. Use sideband data to
track stuff.

]]

local dialog = {
    start_state = "intro",

    -- things that are always available
    always = {
        {
            pos = {silence_total = 2, silence_cur = 1},
            text = "You okay?",
            responses = {
                {"Yeah, I'm just... a bit preoccupied.", {concern = 1}},
                {"No.", {defense = 3}},
                {"Why are you even talking to me?", {anger = 3}, "alienated"}
            }
        },
        {
            pos = {silence_total = 3, silence_cur = 1},
            text = "What's with the cold shoulder?",
            responses = {
                {"What should I say?", {defense = 5}},
                {"Are you in the right home?", {concern = 3}},
                {"Who do you think you are?", {anger = 2, defense = 2}, "alienated"},
                {nil, {anger = 5}, "silence"}
            }
        },
        {
            pos = {silence_total = 6, silence_cur = 1},
            text = "So you're back on that now, huh?",
            responses = {
                {"Back to what?", {defense = 1}},
                {"I think you're confused.", {defense = 2, concern = 1}},
                {"Who are you and why are you in my home?", {anger = 2, concern = 5}, "last_night"},
                {nil, {anger = 2}, "silence"}
            }
        },

    },

    -- starting point
    intro = {
        {
            pos = {},
            text = "# Good morning, dear! #",
            responses = {
                {"Uh... hi...", {concern = 1}, "normal"},
                {"Um... who are you...?", {concern = 1, defense = 1}, "last_night"},
                {"What are you doing here?", {defense = 1}, "alienated"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {concern = 2},
            text = "Good morning... how are you feeling today?",
            responses = {
                {"I'm... fine...", {concern = 1}, "normal"},
                {"Uh, fine, but... who are you?", {concern = -1}, "brain_problems"},
                {"What are you doing in my house?", {}, "alienated"},
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
                {"Oh, sorry, I didn't hear you.", {concern = -1}, "normal"},
                {"Mmhmm.", {defense = 1, anger = 2}, "anger"}
            }
        },
        {
            pos = {phase = 2, anger = 0},
            text = "Hello? I said good morning.",
            responses = {
                {"Um... hello.", {concern = 1}, "normal"},
                {"Oh, sorry, I didn't hear you.", {concern = -1}, "normal"},
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
            responses = {
                {"Like what?", {defense = 1}, "normal"},
                {"What are you doing here?", {defense = 3, anger = 2}, "last_night"},
                {"I don't even know you.", {defense = 2, concern = 1, anger = 1}, "last_night"}
            }
        },
        {
            pos = {phase = 5},
            text = "What's wrong?%% You can talk to me.",
            responses = {
                {"Who are you?", {concern = 5}, "brain_problems"},
                {"You're intruding.", {anger = 1, defense = 3}, "alienated"},
                {"I'm not sure what's going on.", {concern = 3}, "normal"}
            }
        },
        {
            pos = {phase = 6, anger = 0},
            text = "This isn't like you.",
            responses = {
                {"Like who?", {defense = 1, anger = 1}, "normal"},
                {"Who ARE you?", {concern = 10}, "brain_problems"},
                {"How should I be?", {defense = 3, anger = 1}, "normal"}
            }
        },
        {
            pos = {phase = 6, anger = 5},
            text = "This is just like you.",
            responses = {
                {"What is?", {}, "normal"},
                {"Sorry, do I know you?", {concern = 3}, "brain_problems"},
                {""}
            }
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
            text = "If this is about what I said last night, well%.%.%.%% you deserved it.",
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
            text = "Hahaha...%% please...%% just tell me, what's going on...?",
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
                {"what's happening...", {concern=10}, "brain_problems"},
                {nil, {}, "stroke"}
            }
        },

        -- fillers for someone who is enough of a doofus to stay silent while also accelerating the NPC text
        {
            pos = {interrupted = 3},
            text = "You look like you want to say something...",
        },
        {
            pos = {interrupted = 7, anger = 0},
            text = "You know you can tell me anything...",
        },
        {
            pos = {interrupted = 11, phase = 2},
            text = "Please say something.",
        },
        {
            pos = {interrupted = 11, phase = 4},
            text = "Please say something. Anything.",
        },
        {
            pos = {interrupted = 13, phase = 7},
            text = "I just want to know why you aren't talking...",
        },
        {
            pos = {interrupted = 15, anger = 1},
            text = "I mean...%% Why are you skipping my text% if you don't% have anything% to say?",
            responses = {
                {"Because it's funny", {}, "alienated"},
                {"Because I'm impatient", {}, "normal"},
                {"Because this is just a game", {concern=50}, "brain_problems"},
            }
        },
        {
            pos = {interrupted = 17},
            text = "You know you're throwing off the timing of this whole dialog, right?",
            onInterrupt = function(self)
                self.text = self.text .. "\n... dammit"
            end
        },
        {
            pos = {interrupted = 19},
            text = "Okay, now I just KNOW you're doing this to see what I say."
        },
        {
            pos = {interrupted = 20},
            text = "M%a%y%b%e% %I% %s%h%o%u%l%d% %t%a%l%k% %%e%%x%%t%%r%a%% %%%s%%%l%%%o%%%w%%%l%%%y%%%"
                .. " from now on.%%%.%%%.%%%.%%%.%%%",
            cantInterrupt = true
        },
    },

    sidebar_going_somewhere = {
        {
            pos = {},
            text = "What? No, I was just wondering if you'd eaten.",
            responses = {
                {"Oh, my mind was elsewhere.", {defense=2, concern=-2}, "normal"},
                {"So you aren't abducting me, then?", {concern=5}, "brain_problems"},
                {"I'm not hungry.", {concern=2}, "normal"},
                {nil, {}, "silence"}
            }
        }
    },

    -- path where Greg thinks everything is normal
    normal = {
        {
            pos = {phase = 1},
            text = "How are you this morning?",
            responses = {
                {"... Fine ...", {defense = 2, concern = 1}},
                {"What are you doing here?", {defense = 5}},
                {"Confused.", {concern = 3}}
            }
        },

        {
            pos = {phase = 2, concern = 0},
            text = "Have you had breakfast already?",
            responses = {
                {"Not yet.", {}},
                {"No...", {concern=1}},
                {"Are we going somewhere?", {defense=2}, "sidebar_going_somewhere"},
            }
        },
        {
            pos = {phase = 2, concern = 1},
            text = "You're looking tired. Didn't you sleep well?",
            responses = {}
        },
        {
            pos = {phase = 2, concern = 2},
            text = "What's the matter?",
            responses = {}
        },

        {
            pos = {phase = 3, concern = 0},
            text = "It's a beautiful morning, isn't it?",
            responses = {}
        },
        {
            pos = {phase = 3, defense = 2},
            text = "So, last night...",
            responses = {}
        },

        {
            pos = {phase = 4, concern = 0},
            text = "When we got home last night I was worried about you.",
            responses = {}
        },
        {
            pos = {phase = 4, concern = 1, defense = 2},
            text = "When we got home last night I was afraid I'd upset you.",
            responses = {}
        },
        {
            pos = {phase = 4, anger = 2},
            text = "I'm a bit frustrated about last night.",
            responses = {}
        },

        {
            pos = {phase = 5, concern = 0},
            text = "But I mean, we've been married for so long, I guess we were overdue for an argument.",
            responses = {}
        },
        {
            pos = {phase = 5, anger = 2, defense = 2},
            text = "We've been married HOW long? Why didn't you tell me how you felt before?",
            responses = {}
        },

        {
            pos = {phase = 6, concern = 2, anger = 0},
            text = "I guess I'm just surprised, is all. I thought you'd gotten past your social anxiety...",
            responses = {}
        },
        {
            pos = {phase = 6, anger = 3, concern = 0},
            text = "You told me you had that under control.",
            responses = {}
        },
        {
            pos = {phase = 6, anger = 3, concern = 2},
            text = "You seemed to have it under control%.%.%.% until last night.",
            responses = {}
        },

        {
            pos = {phase = 7},
            text = "Sigh...% Sorry to ramble about this. I guess I'm just not feeling so great myself, lately.",
            responses = {}
        },
        {
            pos = {phase = 7.5},
            text = "Where did everything go so wrong?",
            responses = {
                {},
                {},
                {},
                {nil, {}, "gave_up"}
            }
        },


    },

    -- path where Greg thinks "who are you?" is metaphorically, about his behavior last night
    last_night = {
        {
            pos = {concern = 10},
            text = "Wait... you ACTUALLY don't know who I am?",
            responses = {
                {"No.", {}, "brain_problems"},
                {"You're my husband...right?", {}, "brain_problems"},
                {"Of...course I do", {anger=1, defense=1, concern=-5}, "normal"}
            }
        },

        {
            pos = {phase = 10, defense = 0},
            text = "Ha ha ha, oh gosh, are we even talking about the same thing?",
            responses = {}
        },
        {
            pos = {phase = 10, defense = 5},
            text = "Ha ha, what? Are we even talking about the same thing?",
            responses = {}
        }
    },

    -- path where Greg has determined Rose is having brain problems
    brain_problems = {
    },

    -- path where Greg is feeling alienated
    alienated = {
        {
            pos = {interrupted = 5, phase = 2},
            text = "Could you let me finish?"
        },
        {
            pos = {interrupted = 10, phase = 3},
            text = "Could you please let me finish?"
        },
        {
            pos = {interrupted = 15, phase = 4},
            text = "Could you PLEASE let me finish?"
        },
        {
            pos = {interrupted = 20, phase = 5, anger = 0},
            text = "I don't really like being talked over, you know."
        },
        {
            pos = {interrupted = 20, phase = 5, anger = 5},
            text = "I don't really like being talked over, you know."
        },
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
            text = "% .%.%.% %%You don't even...% remember...%% me."
        },

        {
            pos = {phase = 10},
            text = "Ha ha.%.%.% everything we've been through...%% it's just meaningless now, isn't it?"
        },
    },

    -- state where Greg believes Rose is having a stroke
    stroke = {
        {
            pos = {phase = 11.5},
            text = "Hey, are you okay? You're looking a bit wobbly.",
        },
        {
            pos = {phase = 12},
            text = "Yes, emergency services? It's my spouse, I think they're having a stroke."
        },
        {
            pos = {phase = 12.5},
            text = "Someone is coming.... everything will be okay.",
            max_count = 5
        },
        {
            pos = {phase = 12.5},
            text = "Shh, shh, it's okay...%% Everything will be fine...%#%#%#",
            max_count = 5
        },
        {
            pos = {phase = 12.5},
            text = "They'll be here soon.",
            max_count = 5
        },
        {
            pos = {phase = 12.5},
            text = "I love you.%#%\n\nWe'll get through this.",
            max_count = 5
        },
        {
            pos = {phase = 12.5},
            text = "It's okay, I'm here for you.",
            max_count = 5
        },
    },

 }


return dialog