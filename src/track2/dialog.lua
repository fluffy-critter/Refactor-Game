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
                text to show (nil=silence),
                adjustments to the parameter space,
                name of pool to jump to (optional)
        },
        onReach=function(npc), -- function to call if we've reached this state
        setState = "state", -- which state to switch to if we get to this point
        max_count=..., -- Maximum number of times this fragment can appear (default: 1)
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
            pos = {silence_total=2, silence_cur=1},
            text = "You okay?",
            responses = {
                {"Yeah, I'm just... a bit preoccupied.", {}},
                {"No.", {}},
                {"Why are you even talking to me?", {}, "alienated"}
            }
        },
        {
            pos = {silence_total=3, silence_cur=1},
            text = "What's with the cold shoulder?",
            responses = {
                {"What should I say?", {}},
                {"Are you in the right home?", {}},
                {"Who do you think you are?", {}, "alienated"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {silence_total=6, silence_cur=1},
            text = "So you're back on that now, huh?",
            responses = {
                {"Back to what?", {}},
                {"I think you're confused.", {}},
                {"Who are you and why are you in my home?", {}, "brain_problems"},
                {nil, {}, "silence"}
            }
        },

    },

    -- starting point
    intro = {
        {
            pos = {},
            text = "# Good morning, dear! #",
            responses = {
                {"Uh... hi...", {}, "normal"},
                {"Who are you...?", {}, "last_night"},
                {"What are you doing here?", {}, "alienated"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {},
            text = "Good morning... how are you feeling today?",
            responses = {
                {"I'm... fine...", {}, "normal"},
                {"Uh, fine, but... who are you?", {}, "brain_problems"},
                {"What are you doing in my house?", {}, "alienated"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {},
            text = "Good morning.",
            responses = {
                {"...good morning...", {}, "normal"},
                {"Who are you?", {}, "last_night"},
                {"What are you doing here?", {}, "alienated"},
                {nil, {}, "silence"}
            }
        }
    },

    -- path where Rose never responds
    silence = {
        {
            pos = {phase=2},
            text = "I said, good morning.",
            responses = {
                {"Um... hello.", {}, "normal"},
                {"Oh, sorry, I didn't hear you.", {}, "normal"},
                {"Mmhmm.", {}, "anger"}
            }
        },
        {
            pos = {phase=2},
            text = "Hello? I said good morning.",
            responses = {
                {"Um... hello.", {}, "normal"},
                {"Oh, sorry, I didn't hear you.", {}, "normal"},
                {"Mmhmm.", {}, "anger"}
            }
        },
        {
            pos = {phase=3},
            text = "Is everything okay?",
            responses = {
                {"Not really.", {}, "normal"},
                {"... Who are you?", {}, "brain_problems"},
                {"Yeah, I guess.", {}, "normal"}
            }
        },
        {
            pos = {phase=4},
            text = "Why are you looking at me like that?",
            responses = {
                {"Like what?", {}, "normal"},
                {"What are you doing here?", {}, "last_night"},
                {"I don't even know you.", {}, "last_night"}
            }
        },
        {
            pos = {phase=5},
            text = "What's wrong?%% You can talk to me.",
            responses = {
                {"Who are you?", {}, "brain_problems"},
                {"You're intruding.", {}, "alienated"},
                {"I'm not sure what's going on.", {}, "normal"}
            }
        },

        {
            pos = {phase=6},
            text = "This isn't like you.",
            responses = {
                {"Like who?", {}, "normal"},
                {"Who ARE you?", {}, "brain_problems"},
                {"How should I be?", {}, "normal"}
            }
        },
        {
            pos = {phase=6},
            text = "This is just like you.",
            responses = {
                {"What is?", {}, "normal"},
                {"Sorry, do I know you?", {}, "brain_problems"},
                {"I'm sorry.", {}, "normal"}
            }
        },

        {
            pos = {phase=7},
            text = "Is this about what I said last night? It was only a joke.",
            responses = {
                {"And I'm sure it was funny.", {}, "brain_problems"},
                {"Well it wasn't very funny.", {}, "last_night"},
                {"I don't remember what you said.", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=7},
            text = "Is this about what I said last night? I'm sorry, it was out of line.",
            responses = {
                {"...What did you say?", {}, "brain_problems"},
                {"Yes, it was.", {}, "normal"},
                {"It isn't that...", {}, "normal"}
            }
        },
        {
            pos = {phase=7},
            text = "If this is about what I said last night, well%.%.%.%% you deserved it.",
            responses = {
                {"...What did you say?", {}, "brain_problems"},
                {"I doubt it.", {}, "normal"},
                {"Yeah, I guess I did.", {}, "normal"}
            }
        },

        {
            pos = {phase=8},
            text = "I'm just not sure why you're giving me the silent treatment, here...",
            responses = {
                {"I feel... numb...", {}, "stroke"},
                {"Who are you?", {}, "brain_problems"},
                {"Please just go away...", {}, "alienated"}
            }
        },
        {
            pos = {phase=8},
            text = "So you can cut it out with the silent treatment.",
            responses = {
                {"Who are you?", {}, "brain_problems"},
                {"Why are you even here?", {}, "last_night"},
                {"Please. Go away.", {}, "alienated"},
            }
        },
        {
            pos = {phase=9},
            text = "...",
            responses = {
                {"What?", {}, "normal"},
                {"Yep.", {}, "alienated"},
                {"Three dots", {}, "stroke"},
            }
        },
        {
            pos = {phase=10},
            text = "Hahaha...%% please...%% just tell me, what's going on...?",
            responses = {
                {"I feel... numb...", {}, "stroke"},
                {"Who are you?", {}, "brain_problems"},
                {"Please just go away...", {}, "alienated"}
            }
        },
        {
            pos = {phase=10},
            text = "Ha ha, fine, don't tell me anything...",
            responses = {}
        },

        {
            pos = {phase=11},
            text = "Are you... are you crying?",
            responses = {
                {"no, I...", {}, "brain_problems"},
                {"y....yes....", {}, "brain_problems"},
                {"what's happening...", {}, "brain_problems"},
                {nil, {}, "stroke"}
            }
        },

        -- fillers for someone who is enough of a doofus to stay silent while also accelerating the NPC text
        {
            pos = {interrupted=2},
            text = "You look like you want to say something...",
        },
        {
            pos = {interrupted=4},
            text = "You know you can tell me anything...",
        },
        {
            pos = {interrupted=6},
            text = "Please say something.",
        },
        {
            pos = {interrupted=8},
            text = "Please say something. Anything.",
        },
        {
            pos = {interrupted=9.1},
            text = "I just want to know why you aren't talking...",
        },
        {
            pos = {interrupted=10.2},
            text = "I mean...%% Why are you skipping my text% if you don't% have anything% to say?",
            responses = {
                {"Because it's funny", {}, "alienated"},
                {"Because I'm impatient", {}, "normal"},
                {"Because this is just a game", {}, "brain_problems"},
            }
        },
        {
            pos = {interrupted=11.5},
            text = "You know you're throwing off the timing of this whole dialog, right?",
            onInterrupt = function(self)
                self.text = self.text .. "\n... dammit"
            end
        },
        {
            pos = {interrupted=13},
            text = "Okay, now I just KNOW you're doing this to see what I say."
        },
        {
            pos = {interrupted=14},
            text = "M%a%y%b%e% %I% %s%h%o%u%l%d% %t%a%l%k% %%e%%x%%t%%r%a%% %%%s%%%l%%%o%%%w%%%l%%%y%%%"
                .. " from now on.%%%.%%%.%%%.%%%.%%%",
            cantInterrupt=true
        },
    },

    sidebar_going_somewhere = {
        {
            pos = {},
            text = "What? No, I was just wondering if you'd eaten.",
            responses = {
                {"Oh, my mind was elsewhere.", {}, "normal"},
                {"So you aren't abducting me, then?", {}, "brain_problems"},
                {"I'm not hungry.", {}, "normal"},
                {nil, {}, "silence"}
            }
        }
    },

    -- path where Greg thinks everything is normal
    normal = {
        {
            pos = {phase=1},
            text = "How are you this morning?",
            responses = {
                {"... Fine ...", {}},
                {"What are you doing here?", {}, "last_night"},
                {"Confused.", {}, "brain_problems"}
            }
        },

        {
            pos = {phase=2},
            text = "Have you had breakfast already?",
            responses = {
                {"Not yet.", {}},
                {"No...", {}},
                {"Are we going somewhere?", {}, "sidebar_going_somewhere"},
            }
        },
        {
            pos = {phase=2},
            text = "You're looking tired. Didn't you sleep well?",
            responses = {
                {"Not particularly...", {}},
                {"How did you get in here?", {}, "wtf"},
                {"Please go away.", {}, "wtf"}
            }
        },
        {
            pos = {phase=2},
            text = "What's the matter?",
            responses = {
                {"Who are you?", {}, "brain_problems"},
                {"What are you doing here?", {}, "last_night"},
                {"Why are you in my house?", {}, "wtf"}
            }
        },

        {
            pos = {phase=3},
            text = "It's a beautiful morning, isn't it?",
            responses = {
                {"Yeah...", {}},
                {"Why are you in my house?", {}, "wtf"},
                {"Who are you?", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=3},
            text = "So, last night...",
            responses = {
                {"What about it?", {}},
                {"I'm sorry, but who are you?", {}, "brain_problems"},
                {"What happened?", {}, "last_night"}
            }
        },

        {
            pos = {phase=4},
            text = "When we got home last night I was worried about you.",
            responses = {
                {"We came home together?", {}},
                {"This is my home...", {}, "brain_problems"},
                {"What happened last night?", {}, "last_night"}
            }
        },
        {
            pos = {phase=4},
            text = "When we got home last night I was afraid I'd upset you.",
            responses = {
                {"Why would you think that?", {}},
                {"That's okay...", {}},
                {"I don't even know who you are.", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=4},
            text = "I'm a bit frustrated about last night.",
            responses = {
                {"What happened?", {}, "last_night"},
                {"Did I promise you something?", {}},
                {"So you went home with a stranger, huh?", {}, "brain_problems"}
            }
        },

        {
            pos = {phase=5},
            text = "But I mean, we've been married for so long, I guess we were overdue for an argument.",
            responses = {
                {"I don't remember it.", {}},
                {"Sorry, what was it about?", {}, "brain_problems"},
                {"Sorry...", {}}
            }
        },
        {
            pos = {phase=5},
            text = "We've been married HOW long? Why didn't you tell me how you felt before?",
            responses = {
                {"We're... married?", {}, "brain_problems"},
                {"I... guess it just didn't come up.", {}},
                {"Who are you?", {}, "last_night"}
            }
        },

        {
            pos = {phase=6},
            text = "I guess I'm just surprised, is all. I thought you'd gotten past your anxiety problems...",
            responses = {
                {"How do you know about that?", {}, "brain_problems"},
                {"I don't even know who you are.", {}, "wtf"},
                {"What happened?", {}, "last_night"}
            }
        },
        {
            pos = {phase=6},
            text = "You told me you had that under control.",
            responses = {
                {"Had what under control?", {}, "brain_problems"},
                {"I'm sorry for whatever I did.", {}},
                {"What are you talking about?", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=6},
            text = "You seemed to have it under control%.%.%.% until last night.",
            responses = {
                {"Had what under control?", {}},
                {"I'm sorry for whatever I did.", {}},
                {"What are you talking about?", {}}
            }
        },

        {
            pos = {phase=7},
            text = "Sigh...% Sorry to ramble about this. I guess I'm just not feeling so great myself, lately.",
            responses = {
                {"Anything I can do to help?", {}},
                {"Why don't you tell me who you are first?", {}, "brain_problems"},
                {"That's too bad.", {}, "alienated"}
            }
        },
        {
            pos = {phase=7.5},
            text = "Where did everything go so wrong?",
            responses = {
                {"When you went home with a stranger?", {}, "brain_problems"},
                {"Who can tell.", {}, "alienated"},
                {"Last...night?", {}, "last_night"},
                {nil, {}, "alienated"}
            }
        },
    },

    -- path where Greg is feeling attacked out of the blue
    wtf = {
        { pos = {}, text = "DIALOG PATH INCOMPLETE: wtf" },

        {
            pos = {phase=2},
            text = "Uh... what?",
            responses = {
                {"You heard me.", {}},
                {"Who are you?", {}, "brain_problems"},
                {"What are you doing in my house?", {}}
            }
        },

        {
            pos = {},
            text = "What the hell is wrong with you today?!",
            responses = {
                {"What do you mean?", {}},
                {"I don't like strangers in my house.", {}, "brain_problems"},
                {"Do you belong here?", {}, "alienated"}
            }
        },
        {
            pos = {},
            text = "Why are you being like this?",
            responses = {
                {"Like what?", {}},
                {"You're intruding!", {}, "alienated"},
                {"Who are you?", {}, "brain_problems"}
            }
        }
    },

    -- path where Greg thinks "who are you?" is metaphorically, about his behavior last night
    last_night = {
        { pos = {}, text = "DIALOG PATH INCOMPLETE: last_night" },

        {
            pos = {phase=5},
            text = "Wait... you ACTUALLY don't know who I am?",
            responses = {
                {"No.", {}, "brain_problems"},
                {"You're my husband...right?", {}, "brain_problems"},
                {"Of course I do.", {}, "wtf"}
            }
        },

        {
            pos = {phase=10},
            text = "Ha ha ha, oh gosh, are we even talking about the same thing?",
            responses = {}
        },
        {
            pos = {phase=10},
            text = "Ha ha, what? Are we even talking about the same thing?",
            responses = {}
        }
    },

    -- path where Greg has determined Rose is having brain problems
    brain_problems = {
        {
            pos = {phase=2.5},
            text = "Hon, are you feeling okay?",
            responses = {}
        },

        {
            pos = {phase=3},
            text = "Lately you've been forgetting a lot of stuff...%% I wonder...",
            responses = {}
        },

        {
            pos = {phase=4},
            text = "Please stop looking at me like that. Like I'm a stranger...",
            responses = {}
        },
        {
            pos = {phase=4},
            text = "Please stop looking at me like that. I'm not a stranger.",
            responses = {}
        },
        {
            pos = {phase=4},
            text = "Stop looking at me like that. I'm not a stranger.",
            responses = {}
        },
        {
            pos = {phase=4},
            text = "Stop looking at me like that. I'm not a stranger...% Am I?",
            responses = {}
        },

        {
            pos = {phase=5},
            text = "We've been married so long...% I never thought your memories of ME would be the first to go.",
            responses = {}
        },

        {
            pos = {phase=6},
            text = "But you have a family history of this.%.%.%",
            responses = {}
        },
        {
            pos = {phase=6},
            text = "But you DO have a family history of this.%.%.%",
            responses = {}
        },
        {
            pos = {phase=6},
            text = "But you DO have a family history.%.%.% Oh.%%%\n\nOH.",
            responses = {}
        },

        {
            pos = {phase=7},
            text = "Can you remember anything about me? Anything at all?",
            responses = {}
        },
        {
            pos = {phase=7},
            text = "Surely you must remember SOMETHING about me...",
            responses = {}
        },

        {
            pos = {phase=8},
            text = "Our wedding day was the happiest I'd ever seen you...",
            responses = {}
        },

        {
            pos = {phase=10},
            text = "Ha ha ha, okay, this.%.%.% this explains so much...",
            responses = {
                {"What's so funny?", {}},
                {"Please don't laugh...", {}},
                {"Explains what?", {}},
                {nil, {}, "silence"}
            }
        },

        {
            pos = {phase=11},
            text = "You don't... you don't remember anything, do you.",
            responses = {
                {"I have no idea who you are.", {}},
                {"Why are there pictures of us together?", {}},
                {"I'm feeling faint...", {}},
            }
        },

        {
            pos = {phase=12},
            text = "I wonder how long this has been going on... Is this why you've been forgetting so much?",
            responses = {
                {"What have I forgotten?", {}},
                {"I'm so confused.", {}},
                {"What's going on?", {}}
            }
        },
        {
            pos = {phase=12},
            text = "I wonder how long this has been going on... Let's go to the doctor.",
            responses = {
                {"What have I forgotten?", {}},
                {"I'm so confused.", {}},
                {"What's going on?", {}}
            }
        },
        {
            pos = {phase=13},
            text = "Let's go to a doctor, okay?",
            maxCount = 20,
            responses = {
                {"A doctor? Why?", {}},
                {"I don't want to...", {}},
                {"You're trying to trick me.", {}}
            }
        }
    },

    -- path where Greg is feeling alienated
    alienated = {
        { pos = {}, text = "DIALOG PATH INCOMPLETE: alienated" },

        {
            pos = {phase=10},
            text = "Ha ha, wow, this is just... what the hell is going on here.",
            responses = {}
        },

        {
            pos = {interrupted=5, phase=2},
            text = "Could you let me finish?"
        },
        {
            pos = {interrupted=10, phase=3},
            text = "Could you please let me finish?"
        },
        {
            pos = {interrupted=15, phase=4},
            text = "Could you PLEASE let me finish?"
        },
        {
            pos = {interrupted=20, phase=5},
            text = "I don't really like being talked over, you know."
        },
        {
            pos = {interrupted=20, phase=5},
            text = "I don't like being talked over.%%\nStop it.%%",
            cantInterrupt=true
        },
    },

    -- path where Greg gets really angry at Rose
    anger = {
        { pos = {}, text = "DIALOG PATH INCOMPLETE: anger" },

    },

    -- path where Greg has given up on helping Rose
    gave_up = {
        { pos = {}, text = "DIALOG PATH INCOMPLETE: gave_up" },

        {
            pos = {phase=12},
            text = "What does it matter? You won't even remember this anyway."
        },
        {
            pos = {phase=12},
            text = "% .%.%.% %%You don't even...% remember...%% me.",
            cantInterrupt=true
        },

        {
            pos = {phase=10},
            text = "Ha ha.%.%.% everything we've been through...%% it's just meaningless now, isn't it?",
            cantInterrupt=true
        },

        {
            pos = {phase=12.5},
            text = "I just can't do this anymore. Goodbye.",
            onReach=function(npc)
                npc.gone=true
            end
        },
    },

    -- state where Greg believes Rose is having a stroke
    stroke = {
        {
            pos = {phase=0},
            text = "Yes, emergency services? It's my spouse, something's very wrong with them.",
        },
        {
            pos = {phase=-1},
            text = "Someone is coming.... everything will be okay.",
            max_count=5
        },
        {
            pos = {phase=-2},
            text = "Shh, shh, it's okay...%% Everything will be fine...%#%#%#",
            max_count=5
        },
        {
            pos = {phase=-2},
            text = "They'll be here soon.",
            max_count=5
        },
        {
            pos = {phase=-2},
            text = "I love you.%#%\n\nWe'll get through this.",
            max_count=5
        },
        {
            pos = {phase=-2},
            text = "It's okay, I'm here for you.",
            max_count=5
        },
    },

 }

return dialog
