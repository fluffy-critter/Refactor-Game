--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

Design:

dialog top-level object contains named pools; each pool contains a bunch of fragments, in the form of:

    poolName = {
        pos = {...}, -- position in the parameter space
        text = "...", -- text displayed by the NPC (required, even if ended=true)
        responses = { -- choice box to create afterwards (if nil, just select another dialog)
            { "responseText", {paramchanges}, "poolChange" } --
                text to show (nil=silence),
                adjustments to the parameter space,
                name of pool to jump to (optional)
        },
        setPos = {...}, -- set position flags if we've gotten here
        setState = "state", -- which state to switch to if we get to this point
        maxCount=..., -- Maximum number of times this fragment can appear (default: 1)
        ended = true, -- indicates the dialog is now over
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

local config = require 'config'
local playlist = require 'playlist'

if config.debug then
    print(playlist.lastDesc)
end

local dialog = {
    start_state = "intro",

    -- things that are always available
    always = {
        {
            pos = {what_doing=1000},
            text = "What's with the tone?%% I just took a walk after we got home,% to clear my head.%% " ..
                "You were already asleep when I got back.",
            pose = "facing_left",
            rose = "eyes_right",
            responses = {
                {"I see.", {}},
                {"Why come here?", {}, "wtf"},
                {"Who let you in?", {who_let_you_in=1000}}
            }
        },

        {
            pos = {who_let_you_in=1000},
            text = "Um%.%.%. I did?%% With my key?",
            pose = "facing_left",
            rose = "normal",
            responses = {
                {"Why do you have a key?", {}, "wtf"},
                {"You live here?", {}, "brain_problems"},
                {"Oh.", {}}
            }
        }

    },

    -- starting point
    intro = {
        {
            pos = {fun=1},
            text = "# Good morning, dear! #",
            rose = "eyes_right",
            pose = {"right_of_rose", "facing_left"},
            responses = {
                {"Hi...", {}, "normal"},
                {"Who are you...?", {}, "last_night"},
                {"What are you doing here?", {what_doing=1000}, "alienated"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {fun=37},
            text = "Good morning... how are you feeling today?",
            pose = {"left_of_stairs", "facing_left"},
            rose = "eyes_right",
            responses = {
                {"I'm... fine...", {}, "normal"},
                {"Uh, fine, but... who are you?", {}, "brain_problems"},
                {"Who are you?", {}, "last_night"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {fun=50},
            text = "Good morning.",
            pose = "facing_down",
            rose = "eyes_right",
            responses = {
                {"...good morning...", {}, "normal"},
                {"Who are you?", {}, "last_night"},
                {"What are you doing here?", {what_doing=1000}, "alienated"},
                {nil, {}, "silence"}
            }
        }
    },

    -- path where Rose never responds
    silence = {
        {
            pos = {phase=2},
            text = "I said, good morning.",
            pose = "right_of_rose",
            rose = "normal",
            responses = {
                {"Um... hello.", {}, "normal"},
                {"Oh, sorry, I didn't hear you.", {}, "normal"},
                {"Mmhmm.", {}, "wtf"}
            }
        },
        {
            pos = {phase=2},
            text = "Hello? I said good morning.",
            pose = "next_to_rose",
            responses = {
                {"Um... hello.", {}, "normal"},
                {"Oh, sorry, I didn't hear you.", {}, "normal"},
                {"Mmhmm.", {}, "wtf"}
            }
        },
        {
            pos = {phase=3},
            text = "Is everything okay?",
            pose = {"next_to_rose", "facing_down"},
            responses = {
                {"Not really.", {}, "normal"},
                {"... Who are you?", {}, "brain_problems"},
                {"Yeah, I guess.", {}, "normal"}
            }
        },
        {
            pos = {phase=4},
            text = "Why are you looking at me like that?",
            pose = {"right_of_rose", "facing_left"},
            rose = "eyes_right",
            responses = {
                {"Like what?", {}, "normal"},
                {"What are you doing here?", {}, "last_night"},
                {"I don't even know you.", {}, "last_night"}
            }
        },
        {
            pos = {phase=5},
            text = "What's wrong?%% You can talk to me.",
            pose = {"next_to_rose", "facing_left"},
            rose = "normal",
            responses = {
                {"Who are you?", {}, "brain_problems"},
                {"You're intruding.", {}, "alienated"},
                {"I'm not sure what's going on.", {}, "normal"}
            }
        },

        {
            pos = {phase=6, angry=0, silence_likeyou=0},
            text = "This isn't like you.",
            pose = "facing_left",
            setPos = {silence_likeyou=1000},
            responses = {
                {"Like who?", {}, "normal"},
                {"Who ARE you?", {}, "brain_problems"},
                {"How should I be?", {}, "normal"}
            }
        },
        {
            pos = {phase=6, angry=1, silence_likeyou=0},
            text = "This is just like you.",
            pose = {"below_doors", "facing_right"},
            setPos = {silence_likeyou=1000},
            responses = {
                {"What is?", {}, "normal"},
                {"Sorry, do I know you?", {}, "brain_problems"},
                {"I'm sorry.", {}, "normal"}
            }
        },

        {
            pos = {phase=7, silence_whatisaid=0},
            text = "Is this about what I said last night? It was only a joke.",
            pose = {"below_doors", "facing_right"},
            rose = "eyes_right",
            setPos = {silence_whatisaid=1000},
            responses = {
                {"And I'm sure it was funny.", {}, "brain_problems"},
                {"Well it wasn't very funny.", {}, "last_night"},
                {"I don't remember what you said.", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=7, silence_whatisaid=0},
            text = "Is this about what I said last night? I'm sorry, it was out of line.",
            pose = {"below_doors", "facing_left"},
            rose = "normal",
            setPos = {silence_whatisaid=1000},
            responses = {
                {"...What did you say?", {}, "brain_problems"},
                {"Yes, it was.", {}, "normal"},
                {"It isn't that...", {}, "normal"}
            }
        },
        {
            pos = {phase=7, silence_whatisaid=0},
            text = "If this is about what I said last night, well%.%.%.%% you deserved it.",
            pose = {"below_doors", "facing_right"},
            rose = "eyes_left",
            setPos = {silence_whatisaid=1000},
            responses = {
                {"...What did you say?", {}, "brain_problems"},
                {"I doubt it.", {}, "normal"},
                {"Yeah, I guess I did.", {}, "normal"}
            }
        },

        {
            pos = {phase=8, silence_silenttreatment=0},
            text = "I'm just not sure why you're giving me the silent treatment, here...",
            pose = {"below_doors", "facing_up"},
            setPos = {silence_silenttreatment=1000},
            rose = "eyes_left",
            responses = {
                {"I feel... numb...", {}, "stroke"},
                {"Who are you?", {}, "brain_problems"},
                {"Please just go away...", {}, "alienated"}
            }
        },
        {
            pos = {phase=8, silence_silenttreatment=0},
            text = "So you can cut it out with the silent treatment.",
            pose = {"below_doors", "facing_right"},
            rose = "normal",
            setPos = {silence_silenttreatment=1000},
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
                {"What?", {}, "wtf"},
                {"Yep.", {}, "alienated"},
                {"Three dots", {}, "stroke"},
            }
        },
        {
            pos = {phase=10},
            text = "Hahaha...%% please...%% just tell me, what's going on...?",
            pose = {"right_of_rose", "facing_left"},
            rose = "closed",
            responses = {
                {"I feel... numb...", {}, "stroke"},
                {"Who are you?", {}, "brain_problems"},
                {"Please just go away...", {}, "alienated"}
            }
        },
        {
            pos = {phase=10},
            text = "Ha ha, fine, don't tell me anything...",
            pose = {"left_of_couch", "facing_right"},
            rose = "closed",
            responses = {
                {"I feel... numb...", {}, "stroke"},
                {"Who are you?", {}, "brain_problems"},
                {"Please just go away...", {}, "alienated"}
            }
        },

        {
            pos = {phase=11},
            text = "Are you... are you crying?",
            pose = {"right_of_rose", "facing_left"},
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
            text = "Please say something.%% Anything.",
        },
        {
            pos = {interrupted=8},
            text = "I just want to know why you aren't talking...",
        },
        {
            pos = {interrupted=10},
            text = "I mean...%% Why are you skipping my text% if you don't% have anything% to say?",
            pose = "couch_sitting",
            responses = {
                {"Because it's funny", {}, "alienated"},
                {"Because I'm impatient", {}, "normal"},
                {"Because this is just a game", {}, "brain_problems"},
            }
        },
        {
            pos = {interrupted=12},
            text = "You know you're throwing off the timing of this whole dialog, right?",
            pose = "facing_right",
            onInterrupt = function(self)
                self.text = self.text .. "\n... dammit"
            end
        },
        {
            pos = {interrupted=14},
            text = "Okay, now I just KNOW you're doing this to see what I say."
        },
        {
            pos = {interrupted=16},
            text = "M%a%y%b%e% %I% %s%h%o%u%l%d% %t%a%l%k% %%e%%x%%t%%r%a%% %%%s%%%l%%%o%%%w%%%l%%%y%%%"
                .. " from now on.%%%.%%%.%%%.%%%.%%%",
            rose = "eyes_right",
            setState = "herpderp",
            pose = {
                "bottom_of_stairs", "left_of_stairs", "bottom_of_stairs", "left_of_stairs",
                "left_of_couch",
                "bottom_of_stairs", "left_of_stairs", "bottom_of_stairs", "left_of_stairs",
            },
            cantInterrupt=true
        },
    },

    herpderp = {
        {
            pos = {},
            pose = {},
            rose = "eyes_left",
            text = '~%% <("<) %%^%% (>")> %%~',
            maxCount = 500,
            cantInterrupt = true
        },
    },

    -- path where Greg thinks everything is normal
    normal = {
        {
            pos = {silence_total=2, silence_cur=1},
            text = "You okay?",
            rose = "eyes_left",
            responses = {
                {"Yeah, I'm just... a bit preoccupied.", {}},
                {"No.", {}},
                {"Why are you even talking to me?", {}, "alienated"}
            }
        },

        {
            pos = {nrm_going_somewhere=500},
            text = "What? No, I was just wondering if you'd eaten.",
            pose = {"right_of_rose", "facing_left"},
            rose = "eyes_right",
            responses = {
                {"Oh, my mind was elsewhere.", {}, "alienated"},
                {"So you aren't abducting me, then?", {}, "brain_problems"},
                {"I'm not hungry.", {}},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {nrm_no_breakfast=500},
            text = "Oh.%% You know what your doctor said...%% How you should always have breakfast? %.%.%. " ..
                "Sorry to nag, I know you hate that.",
            rose = "eyes_left",
        },

        {
            pos = {phase=2, normal_tired=0, asked_about_breakfast=0},
            text = "Have you had breakfast already?",
            pose = "kitchen",
            rose = "normal",
            setPos = {asked_about_breakfast=500},
            responses = {
                {"Not yet.", {}},
                {"No...", {nrm_no_breakfast=500}},
                {"Are we going somewhere?", {nrm_going_somewhere=500}},
            }
        },
        {
            pos = {phase=2,normal_tired=0},
            text = "You're looking tired. Didn't you sleep well?",
            setPos = {normal_tired=100},
            responses = {
                {"Not particularly...", {}},
                {"How did you get in here?", {}, "wtf"},
                {"Please go away.", {}, "wtf"}
            }
        },
        {
            pos = {phase=2,normal_tired=0},
            text = "What's the matter?",
            rose = "eyes_right",
            responses = {
                {"Who are you?", {}, "brain_problems"},
                {"What are you doing here?", {what_doing=1000}, "last_night"},
                {"Why are you in my house?", {}, "wtf"}
            }
        },

        {
            pos = {phase=3, normal_solastnight=0},
            text = "It's a beautiful morning, isn't it?",
            rose = "normal",
            responses = {
                {"Yeah...", {}},
                {"Why are you in my house?", {}, "wtf"},
                {"Who are you?", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=3, normal_camehome=0, normal_tired=0},
            text = "So, last night...",
            rose = "eyes_left",
            responses = {
                {"What about it?", {normal_solastnight=100}},
                {"I'm sorry, but who are you?", {}, "brain_problems"},
                {"What happened?", {}, "last_night"}
            }
        },

        {
            pos = {phase=4, normal_camehome=0, normal_tired=50, importance=3},
            text = "When we got home last night I was worried about you.",
            setPos = {normal_camehome=100},
            responses = {
                {"We came home together?", {normal_whathuh=100}},
                {"This is my home...", {}, "brain_problems"},
                {"What happened last night?", {}, "last_night"}
            }
        },
        {
            pos = {phase=4, normal_camehome=0, normal_tired=100, importance=3},
            text = "When we got home last night I was afraid I'd upset you.",
            rose = "eyes_left",
            setPos = {normal_camehome=100},
            responses = {
                {"Why would you think that?", {}},
                {"That's okay...", {normal_sorry=100}},
                {"I don't even know who you are.", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=4, normal_camehome=0},
            text = "I'm a bit frustrated about last night.",
            pose = "facing_left",
            responses = {
                {"What happened?", {}, "last_night"},
                {"Did I promise you something?", {normal_camehome=100, normal_whathuh=100}},
                {"So you went home with a stranger, huh?", {}, "brain_problems"}
            }
        },

        {
            pos = {normal_whathuh=100},
            text = ".%.%.%What?",
            pose = "facing_left",
            rose = "eyes_right",
            responses = {
                {"Huh?", {}},
                {"Okay?", {}, "wtf"},
                {"Sorry.", {normal_sorry=100}}
            }
        },

        {
            pos = {phase=5, normal_wemarried=0, normal_whathuh=100},
            text = ".%.%.%Aaaanyway. We've been married for so long, I guess we were overdue " ..
                "for an argument eventually, right?",
            pose = {"bottom_of_stairs", "facing_right"},
            rose = "eyes_right",
            setPos = {normal_wemarried=100},
            responses = {
                {"I don't remember it.", {normal_sorry=-100}},
                {"Sorry, what was it about?", {}, "brain_problems"},
                {"Yeah, I guess so...", {}}
            }
        },
        {
            pos = {phase=5, normal_wemarried=0, normal_sorry=0},
            text = "But I mean, we've been married for so long, I guess we were overdue for an argument.",
            pose = {"bottom_of_stairs", "facing_right"},
            rose = "eyes_right",
            setPos = {normal_wemarried=100},
            responses = {
                {"I don't remember it.", {}},
                {"Sorry, what was it about?", {}, "brain_problems"},
                {"Sorry...", {normal_sorry=100}}
            }
        },
        {
            pos = {phase=5, normal_wemarried=0},
            text = "We've been married HOW long? Why didn't you tell me how you felt before?",
            pose = {"bottom_of_stairs", "facing_left"},
            rose = "eyes_left",
            setPos = {normal_wemarried=100},
            responses = {
                {"We're... married?", {}, "brain_problems"},
                {"I... guess it just didn't come up.", {}},
                {"Who are you?", {}, "last_night"}
            }
        },

        {
            pos = {phase=6, normal_wemarried=100, normal_undercontrol=0, normal_sorry=100, importance=2},
            text = "I guess I'm just surprised, is all. I thought you'd gotten past your anxiety problems...",
            pose = {"below_doors", "facing_left"},
            setPos = {normal_undercontrol=100},
            responses = {
                {"How do you know about that?", {}, "brain_problems"},
                {"I don't even know who you are.", {}, "wtf"},
                {"What happened?", {}, "last_night"}
            }
        },
        {
            pos = {phase=6, normal_wemarried=200, normal_undercontrol=0, normal_sorry=0},
            text = "You told me you had that under control.",
            setPos = {normal_undercontrol=100},
            responses = {
                {"Had what under control?", {}, "brain_problems"},
                {"I'm sorry for whatever I did.", {normal_undercontrol=100}},
                {"What are you talking about?", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=6, normal_wemarried=150, normal_undercontrol=0, normal_sorry=0},
            text = "You seemed to have it under control%.%.%.% until last night.",
            pose = {"right_of_rose", "facing_up"},
            rose = "eyes_left",
            setPos = {normal_undercontrol=100},
            responses = {
                {"Had what under control?", {normal_undercontrol=200}},
                {"I'm sorry for whatever I did.", {normal_undercontrol=150}, "last_night"},
                {"What are you talking about?", {}}
            }
        },

        {
            pos = {phase=7},
            text = "Sigh...% Sorry to ramble about this. I guess I'm just not feeling so great myself, lately.",
            pose = "facing_right",
            responses = {
                {"Anything I can do to help?", {}},
                {"Why don't you tell me who you are first?", {}, "brain_problems"},
                {"That's too bad.", {}, "alienated"}
            }
        },
        {
            pos = {phase=7.5},
            text = "Where did everything go so wrong?",
            rose = "normal",
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
        {
            pos = {silence_total=3, silence_cur=1},
            text = "And now the cold shoulder?!",
            responses = {
                {"What should I say?", {}},
                {"Are you in the right home?", {}},
                {"Who do you think you are?", {}, "alienated"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {silence_total=6, silence_cur=1},
            text = "So you're back on that now, huh.",
            responses = {
                {"Back to what?", {}},
                {"I think you're confused.", {}},
                {"Who are you and why are you in my home?", {}, "brain_problems"},
                {nil, {}, "silence"}
            }
        },

        {
            pos = {phase=2},
            text = "Uh... what?",
            pose = {"right_of_rose", "facing_left"},
            responses = {
                {"You heard me.", {}},
                {"Who are you?", {}, "brain_problems"},
                {"What are you doing in my house?", {}}
            }
        },

        {
            pos = {phase=3},
            text = "What the hell is wrong with you today?!",
            pose = {"bottom_of_stairs", "facing_left"},
            rose = "normal",
            responses = {
                {"What do you mean?", {}},
                {"I don't like strangers in my house.", {}, "brain_problems"},
                {"Do you belong here?", {}, "alienated"}
            }
        },
        {
            pos = {phase=4},
            text = "Why are you being like this?",
            pose = {"bottom_of_stairs", "facing_left"},
            rose = "normal",
            responses = {
                {"Like what?", {}},
                {"You're intruding!", {}, "alienated"},
                {"Who are you?", {bp_dontknowwho=500}, "brain_problems"}
            }
        },
        {
            pos = {phase=5},
            text = "Oh, come on. We have one little fight after,% what,% 15 years of marriage and now " ..
                "suddenly%.%.%. What the hell.",
            pose = "facing_right",
            setPos = {angry=1},
            responses = {
                {"I don't know what you're talking about.", {}},
                {"Marriage?", {wtf_marriage=100}},
                {"Who are you?!", {bp_dontknowwho=500}, "brain_problems"}
            }
        },

        {
            pos = {wtf_marriage=100},
            text = "Yes, marriage.%% You know,% that thing we did?% With the rabbi?% And the wine glass?",
            pose = "facing_left",
            responses = {
                {"I know what marriage is.", {wtf_marriage=100}},
                {"I don't remember it.", {}, "brain_problems"},
                {"Clearly a mistake.", {}}
            }
        },
        {
            pos = {wtf_marriage=200},
            text = "Well, CONGRATULATIONS.",
            pose = "facing_right",
            responses = {
                {"I don't know who YOU are.", {}, "brain_problems"},
                {"How can we be married?", {wtf_marriage=100}},
                {"Thanks, what do I win?", {wtf_sweepstakes=100}}
            }
        },
        {
            pos = {wtf_marriage=300},
            text = "Right now I'm wondering the same thing.",
            pose = "facing_up",
            responses = {
                {"I don't even know who you are.", {}, "brain_problems"},
                {"Ouch.", {}, "alienated"},
                {"I just want you to leave.", {}, "gave_up"}
            }
        },

        {
            pos = {wtf_sweepstakes=100},
            text = "What.%% The HELL.%% Has gotten% into% you.",
            responses = {
                {"I'm sorry.", {}, "alienated"},
                {"I don't know.", {}},
                {"You must be losing it.", {wtf_losing_it=300}}
            }
        },

        {
            pos = {wtf_losing_it=300},
            text = "Seriously?%% One of us is losing it and I don't think it's me.",
            pose = {"right_of_rose", "couch_sitting"},
            responses = {
                {"Please, go away.", {}, "alienated"},
                {"I don't even know who you are.", {}, "brain_problems"},
                {"Maybe this is fun for me.", {}}
            }
        },

        {
            pos = {phase=6},
            text = "This is so out of character for you...%% Are you having a migraine or something? " ..
                "%...% Do you need a nap?",
            pose = "facing_right",
            responses = {
                {"Please, go away.", {}, "alienated"},
                {"Who ARE you?", {}, "brain_problems"},
                {"Yeah, and a juice box and a cookie.", {}}
            }
        },

        {
            pos = {phase=7},
            text = "Look,% I don't know what's going on here,% but clearly something has upset you.%% " ..
                "Mind telling me what the hell is going on?",
            pose = {"facing_down", "pause", "left_of_couch", "facing_left"},
            responses = {
                {"You aren't my spouse.", {}, "alienated"},
                {"I don't know who you are.", {}, "brain_problems"},
                {"Who ARE you?!", {}},
            }
        },

        {
            pos = {phase=8},
            text = "The past 15 years.% No, 17.%% They were great, until last night%.%.%. What the hell happened?",
            pose = {"right_of_rose", "bottom_of_stairs", "facing_right"},
            responses = {
                {"I don't know.", {}, "gave_up"},
                {"This is all new to me.", {}},
                {"I still don't know who you are.", {}, "brain_problems"}
            }
        },

        {
            pos = {phase=9},
            text = "I thought we had such a happy home together...%% Was that the dream,% or is this the nightmare?",
            pose = "facing_down",
            rose = "closed",
            responses = {
                {"I don't know.", {}, "alienated"},
                {"You're dreaming.", {}},
                {"I'd like to wake up.", {}, "brain_problems"}
            }
        },

        {
            pos = {phase=10},
            text = "Heh...%% Look at us, one little argument% and we're just% falling apart.%% How does anyone " ..
                "make anything work?",
            pose = "facing_left",
            rose = "normal",
            responses = {
                {"Maybe we start from the beginning.", {}},
                {"I really don't know.", {}},
                {"I have to tell you something.", {wtf_tellyousomething=100}}
            }
        },

        {
            pos = {phase=11,wtf_tellyousomething=100},
            text = "What is it?",
            pose = {"right_of_rose", "facing_left"},
            responses = {
                {"I don't know who you are.", {}},
                {"I don't know who I am.", {}},
                {"Nothing makes sense.", {}}
            }
        },

        {
            pos = {phase=11,wtf_tellyousomething=0},
            text = "We've had so many good times together.%% Can we just...% I dunno,% go back to how things were?",
            pose = {"right_of_rose", "facing_right"},
            rose = "closed",
            responses = {
                {"How were they?", {}},
                {"I want to...", {}},
                {"I don't know.", {}}
            }
        },

        {
            pos = {phase=12},
            text = "I'm just so worried...%% But we can make things work, right?",
            pose = {"next_to_rose", "facing_left"},
            rose = "crying",
            responses = {
                {"I hope so...", {}},
                {"I doubt it...", {}},
                {"Let's try...", {}}
            }
        },

        {
            pos = {phase=13},
            text = "I think I know someone we can talk to.",
        },
        {
            pos = {phase=13},
            text = "We just need to keep an open mind.",
        },
        {
            pos = {phase=14},
            text = "",
            ended = true
        }

    },

    -- path where Greg thinks "who are you?" is metaphorically, about his behavior last night
    last_night = {
        {
            pos = {phase=2, what_doing=0, ln_whatcameover=0, mention_lastnight=0},
            text = "I'm sorry, hon. I really don't know what came over me last night.",
            pose = "facing_left",
            setPos = {ln_whatcameover=100,mention_lastnight=100},
            responses = {
                {"It's okay.", {}, "normal"},
                {"What happened?", {}},
                {"... All right.", {}, "alienated"},
            }
        },
        {
            pos = {phase=2, what_doing=0, ln_whatcameover=0, mention_lastnight=100},
            text = "I'm sorry, hon. I really don't know what came over me.",
            pose = {"right_of_rose", "facing_left"},
            setPos = {ln_whatcameover=100,mention_lastnight=100},
            responses = {
                {"It's okay.", {}, "normal"},
                {"What happened?", {}},
                {"... All right.", {}, "alienated"},
            }
        },

        {
            pos = {phase=3, what_doing=0, ln_whatcameover=100},
            text = "Just... something you said set me off a little bit...% and...% you know how I get sometimes.",
            pose = {"left_of_couch", "facing_right"},
            responses = {
                {"I do?", {lastnight_ignorance=200}},
                {"I'm sure it was okay.", {}},
                {"I don't remember.", {lastnight_ignorance=100}},
            }
        },

        {
            pos = {phase=3.5, what_doing=0},
            text = "But, we made it home safely... That taxi driver sure seemed uncomfortable though.",
            responses = {
                {"Taxi driver?", {lastnight_taxi=10}},
                {"Ha ha, yeah...", {}},
                {"I'm not sure what's going on.", {lastnight_blackout=100}}
            }
        },

        {
            pos = {lastnight_taxi=10},
            text = "Sure,% I mean,% that SILENCE between us must have been%.%.%. weird?% I guess?",
            responses = {
                {"Sure...", {}},
                {"Yeah... Weird...", {}},
                {"I don't remember.", {lastnight_blackout=100}},
            }
        },

        {
            pos = {lastnight_blackout=100},
            text = "I guess you had a bit too much to drink after all.%% You know that isn't good for you...",
            pose = {"right_of_rose", "facing_left"}
        },

        {
            pos = {lastnight_ignorance=100},
            text = ".%.%.% Well, you should?",
            pose = "facing_left",
            responses = {
                {"Why?", {lastnight_why_remember=100}},
                {"I don't understand.", {}, "brain_problems"},
                {"Yeah, I guess so.", {lastnight_joking=10}}
            }
        },
        {
            pos = {lastnight_ignorance=200},
            text = "Seriously, is everything okay?",
            pose = {"left_of_stairs", "facing_left"},
            responses = {
                {"Yeah.", {lastnight_joking=-10}},
                {"No.", {}, "alienated"},
                {"I have no idea who you are.", {}, "brain_problems"},
                {nil, {}, "silence"}
            }
        },

        {
            pos = {lastnight_why_remember=100},
            text = "Well,% I mean,% you made kind of a big deal about it last night, so...%% I kinda figured you'd " ..
                "want to talk about it...?",
            responses = {
                {"Not really...", {}, "alienated"},
                {"What are you talking about?", {}, "brain_problems"},
                {"I guess we should.", {}}
            }
        },

        {
            pos = {phase=4, asked_about_breakfast=0},
            text = "Say, have you eaten breakfast yet?",
            setPos = {asked_about_breakfast=500},
            pose = "kitchen",
            rose = "eyes_left",
            responses = {
                {"Yeah.", {lastnight_breakfast=100}},
                {"No.", {lastnight_breakfast=-100}},
                {"I'm not sure.", {lastnight_unsure_breakfast=100}},
            }
        },

        {
            pos = {lastnight_breakfast=100},
            pose = {"behind_rose", "facing_left"},
            text = "Really? Oh, you must have done the dishes already. Okay.",
            rose = "normal",
        },
        {
            pos = {lastnight_breakfast=-100},
            pose = {"behind_rose", "facing_down"},
            rose = "normal",
            text = "Oh...% you really should eat something.% You know what the doctor said about that.%% " ..
                "Um, sorry to nag you about it...% Again..."
        },

        {
            pos = {lastnight_unsure_breakfast=100},
            text = "You%.%.%. aren't sure if you've had breakfast.%% Are you feeling okay?",
            pose = {"right_of_rose", "facing_left"},
            rose = "eyes_left",
            responses = {
                {"I don't know.", {}, "brain_problems"},
                {"Yeah, I guess.", {lastnight_blackout=100,lastnight_feeling_okay=100}},
                {"No... I'm not...", {}, "brain_problems"}
            }
        },

        {
            pos = {phase=5},
            text = "But anyway...%% We've been married a while, I guess this was inevitable, right?",
            rose = "eyes_right",
            responses = {
                {"We're married?", {}, "brain_problems"},
                {"Yeah, I guess so.", {lastnight_ignorance=-50}},
                {"Who are you, again?", {}, "alienated"}
            }
        },

        {
            pos = {phase=6},
            text = "I guess I'm just nervous that we're sort of drifting apart lately.% " ..
                "And you know how I worry about that.",
            rose = "eyes_right",
            pose = "couch_sitting_thinking",
            responses = {
                {"Who are you?", {lastnight_joking_sardonic=150}},
                {"Only lately?", {}, "wtf"},
                {"I've been feeling strange.", {}, "normal"}
            }
        },

        {
            pos = {phase=7, lastnight_joking_sardonic=150},
            text = "Ha ha, very funny.",
            pose = "couch_sitting",
            rose = "eyes_left",
            responses = {
                {"I'm not kidding.", {lastnight_joking=-10}},
                {"Sorry...", {}, "normal"},
                {"Yeah, I'm a comedy genius.", {}}
            }
        },
        {
            pos = {phase=8, lastnight_joking=0},
            text = "Wait...% you...% actually don't know who I am?",
            pose = "right_of_rose",
            rose = "eyes_right",
            responses = {
                {"No.", {bp_prerequisite=100}, "brain_problems"},
                {"You're my husband...right?", {lastnight_yeah_husband=100}},
                {"Of course I do.", {}, "wtf"},
                {nil, {}, "silence"}
            }
        },

        {
            pos = {phase=9, lastnight_yeah_husband=0},
            text = "Heh... Come on, you know I don't like when you joke about this stuff.",
            rose = "eyes_left",
            responses = {
                {"Good thing I'm not joking, then.", {lastnight_joking=-10}},
                {"I don't know that.", {lastnight_ignorance=100,lastnight_joking=-10}},
                {"I don't even know who you are.", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=9, lastnight_yeah_husband=100, lastnight_feeling_okay=100},
            text = "Um, yeah...%% I am...%% Are you% sure% you're feeling okay?",
            setPos = {told_was_husband=500},
            responses = {
                {"No, I'm not.", {}, "brain_problems"},
                {"Yeah, I think so?", {}},
                {"Everything seems weird.", {lastnight_feeling_weird=100}}
            }
        },
        {
            pos = {phase=9, lastnight_yeah_husband=100, lastnight_feeling_okay=0},
            text = "Um, yeah...%% I am...%% Are you feeling okay?",
            responses = {
                {"No, I'm not.", {}, "brain_problems"},
                {"Yeah, I think so?", {}},
                {"Everything seems weird.", {lastnight_feeling_weird=100}}
            }
        },

        {
            pos = {phase=9, lastnight_feeling_weird=100},
            text = "Yeah,% I guess we have a lot of things to work through.",
            rose = "normal",
            responses = {
                {"Maybe you could tell me about yourself.", {}},
                {"I'm not sure what's going on.", {}},
                {"But... who are you?", {}, "brain_problems"}
            }
        },

        {
            pos = {phase=10, fun=0, lastnight_samething=0},
            text = "Ha ha ha, oh gosh, are we even talking about the same thing?",
            responses = {
                {"What are we talking about?", {lastnight_what_talking=200}},
                {"I think so...?", {lastnight_samething=1000}},
                {"I don't even know.", {lastnight_ignorance=1}},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {phase=10, fun=50, lastnight_samething=0},
            text = "Ha ha, what? Are we even talking about the same thing?",
            responses = {
                {"What are we talking about?", {lastnight_what_talking=1000}},
                {"I think so...?", {lastnight_samething=1000}},
                {"Probably not.", {}, "wtf"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {phase=10.5, lastnight_samething=1000},
            text = "I'm just not sure what's going on here.",
            pose = "on_phone",
            setPos = {lastnight_samething=0},
            responses = {
                {"I'm sorry... I'm just in a strange mood.", {}},
                {"Neither do I.", {}, "brain_problems"},
                {"What's real anymore?", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=10.5, lastnight_samething=0},
            text = "I just don't know what we should do next...%% I know, let's go on a vacation.",
            pose = {"right_of_rose", "facing_left"},
            rose = "closed",
            responses = {
                {"Yeah... take some more pictures...", {}, "vacation"},
                {"Yeah... make some new memories...", {}, "vacation"},
                {"But I don't even know you...", {}, "brain_problems"},
                {nil, {}, "brain_problems"}
            }
        },

        {
            pos = {lastnight_what_talking=1000},
            text = "I'm not even sure now. I thought about our fight last night...?",
            setState = "brain_problems",
            setPos = {lastnight_what_talking=0},
            responses = {
                {"What fight?", {}},
                {"I'm talking about a stranger in my home.", {}},
                {"Who won?", {}, "alienated"}
            }
        }

    },

    -- path where Greg has determined Rose is having brain problems
    brain_problems = {
        {
            pos = {phase=2.5},
            setPos = {bp_prerequisite=100},
            text = "Hon, are you feeling okay?",
            pose = "right_of_rose",
            rose = "normal",
            responses = {
                {"Yeah.", {}},
                {"No.", {bp_not_okay=100}},
                {"Who are you?", {}}
            }
        },

        {
            pos = {bp_not_okay=100},
            text = "What's the matter?",
            rose = "eyes_left",
            setPos = {bp_prerequisite=100},
            responses = {
                {"I don't know who you are.", {}},
                {"I don't know what any of this is.", {}},
                {"Everything looks pixelated...", {bp_pixelated=1000,bp_prerequisite=-100}},
                {nil, {}, "silence"}
            }
        },

        {
            pos = {bp_pixelated=1000},
            text = ".%.%.%Pixelated?%% What...% do you mean by that,% exactly?",
            pose = "facing_left",
            rose = "closed",
            responses = {
                {"Everything's made of rectangles.", {bp_pixelated=500}}, -- outval=1500
                {"It's all blurry and 240p.", {bp_pixelated=1000}}, -- outval=2000
                {"I'm seeing our words.", {bp_pixelated=1500}}, -- outval=2500
            }
        },

        {
            pos = {bp_pixelated=1500},
            text = "I%.%.%. have no idea what you mean by that.",
            pose = {"right_of_rose", "facing_left"},
            rose = "normal",
            responses = {
                {"And everything's so blurry.", {bp_pixelated=500}}, -- outval=2000
                {"The song is about us.", {}, "stroke"},
                {"I can see your ellipsis.", {bp_pixelated=1000}}, -- outval=2500
            }
        },

        {
            pos = {bp_pixelated=2000},
            text = ".%.%.%Maybe we should go to the eye doctor, then?",
            pose = {"next_to_rose", "facing_down"},
            rose = "eyes_left",
            responses = {
                {"I don't want to go.", {}},
                {"My sprite isn't big enough for glasses.", {}, "stroke"},
                {"Third dialog choice.", {bp_pixelated=500}}, -- outval=2500
            }
        },

        {
            pos = {bp_pixelated=2500},
            text = "What the%.%.%. Are you messing with me?% What's all this about?",
            pose = {"below_doors", "facing_left"},
            responses = {
                {"The player is in control.", {}, "stroke"},
                {"We are just shapes.", {}, "stroke"},
                {"Who are you?", {}}
            }
        },

        {
            pos = {phase=3, bp_prerequisite=100},
            text = "Lately you've been forgetting a lot of stuff...%% I wonder...",
            setPos = {bp_prerequisite=100},
            pose = {"facing_right", "pause", "pause", "facing_left"},
            rose = "eyes_right",
            responses = {
                {"Like what?", {bp_stranger=0,bp_likewhat=100}},
                {"No I haven't...", {bp_stranger=10,bp_yes_you_have=50}},
                {"Who are you?", {bp_stranger=20}}
            }
        },

        {
            pos = {bp_likewhat=100},
            text = "Well, like who I am, to start with.",
            rose = "normal"
        },

        {
            pos = {bp_yes_you_have=50, bp_prerequisite=100},
            text = "Yes you have.% You just don't remember forgetting...% of course%.%.%.",
            rose = "eyes_left"
        },

        {
            pos = {phase=4, bp_stranger=0, asked_about_breakfast=0},
            text = "Please stop looking at me like that. Like I'm a stranger...",
            pose = "right_of_rose",
            responses = {
                {"But you are.", {bp_stranger=1000}},
                {"Sorry.", {bp_stranger=1000}},
                {"I don't know who you are.", {bp_stranger=1000, bp_dontknowwho=1000}}
            }
        },
        {
            pos = {phase=4, bp_stranger=10, asked_about_breakfast=0},
            setPos = {bp_prerequisite=100},
            pose = {"right_of_rose", "facing_left"},
            text = "Please stop looking at me like that. I'm not a stranger.",
            rose = "eyes_left",
            responses = {
                {"But you are.", {bp_stranger=1000}},
                {"Sorry.", {bp_stranger=1000}},
                {"I don't know who you are.", {bp_stranger=1, bp_dontknowwho=1000}}
            }
        },
        {
            pos = {phase=4, bp_stranger=20, asked_about_breakfast=0},
            text = "Stop looking at me like that. I'm not a stranger...% Am I?",
            pose = {"right_of_rose", "left_of_couch", "facing_left"},
            responses = {
                {"You are to me.", {bp_stranger=1000}},
                {"Yes?", {bp_stranger=1000}},
                {"I don't know who you are.", {bp_stranger=1000, bp_dontknowwho=1000}}
            }
        },
        {
            pos = {bp_that_look=100},
            text = "That look, like I'm some kind of stranger.",
            pose = {"right_of_rose", "facing_left"},
            responses = {
                {"You are to me.", {bp_stranger=1000}},
                {"Sorry...", {bp_stranger=1000}},
                {"I don't know who you are.", {bp_stranger=1000, bp_dontknowwho=1000}}
            }
        },

        {
            pos = {phase=4, bp_stranger=0, asked_about_breakfast=500},
            text = "...%% What's with that look?",
            pose = {"right_of_rose", "facing_left"},
            rose = "eyes_left",
            responses = {
                {"What look?", {bp_that_look=100}},
                {"Who are you?", {}},
                {"Meh.", {}, "alienated"}
            }
        },

        {
            pos = {phase=5, bp_prerequisite=100},
            text = "We've been married so long...% I never thought your memories of ME would be the first to go.",
            pose = {"right_of_rose", "facing_right"},
            rose = "eyes_right",
            setPos = {told_was_husband=500, bp_guess_husband=0},
            responses = {
                {"We're married?", {}},
                {"How long, exactly?", {bp_howlong=100}},
                {"You're trying to trick me.", {}}
            }
        },

        {
            pos = {bp_howlong=100, bp_already_said_when=0},
            setPos = {bp_howlong=0, bp_already_said_when=500},
            text = "How long?%% Gosh, 15...?% no,% 17 years.",
            pose = "facing_left",
            responses = {
                {"So we're married, then.", {}},
                {"Which one is it?", {bp_howlong=1000}},
                {"That's a long time.", {bp_longtime=500}}
            }
        },
        {
            pos = {bp_howlong=1000},
            text = "17.%% You know I can't do math under pressure.",
            rose = "normal"
        },
        {
            pos = {bp_longtime=500},
            text = "Yes.%% Yes, it is."
        },
        {
            pos = {bp_howlong=100, bp_already_said_when=500},
            setPos = {bp_howlong=0},
            text = "17 years ago. Did you forget already?",
            rose = "eyes_right"
        },

        {
            pos = {phase=6, bp_family_history=0, fun=0, bp_prerequisite=100},

            text = "But you have a family history of this.%.%.%",
            setPos = {bp_family_history=100},
            rose = "eyes_right",
            responses = {
                {"Of what?", {bp_ofwhat=100}},
                {"No I don't...", {bp_denial=100}},
                {"How do you know that?", {bp_howknow=100}},
            }
        },
        {
            pos = {phase=6, bp_family_history=0, fun=50, bp_prerequisite=100},
            text = "But you DO have a family history of this.%.%.%",
            setPos = {bp_family_history=100},
            pose = "facing_down",
            rose = "normal",
            responses = {
                {"Of what?", {bp_ofwhat=100}},
                {"No I don't...", {bp_no_history=100}},
                {"How do you know that?", {bp_howknow=100}},
            }
        },
        {
            pos = {phase=6, bp_family_history=0, bp_prerequisite=0, wtf_marriage=0},
            text = "You do have a family history of.%.%.% Oh.%%%\n\nOH.",
            pose = {"facing_right", "pause", "pause", "facing_down"},
            rose = "eyes_right",
            setPos = {bp_family_history=100, bp_prerequisite=100},
            responses = {
                {"Of what?", {bp_ofwhat=100}},
                {"No I don't...", {bp_denying_what=100}},
                {"How do you know that?", {bp_howknow=100}},
            }
        },

        {
            pos = {bp_denying_what=100},
            text = "What are you denying, exactly?",
            pose = "facing_left",
            rose = "eyes_right",
            responses = {
                {"I don't know, but I don't have it.", {bp_no_history=100}},
                {"I'm not sure.", {bp_ofwhat=100}},
                {"That thing you said.", {}}
            }
        },

        {
            pos = {bp_prerequisite=0, wtf_marriage=100},
            text = "You don't rememb.%.%.% Oh.%%\n\nThis is it...% Your family history...",
            pose = "facing_down",
            rose = "normal",
            setPos = {bp_family_history=100, bp_prerequisite=100},
            responses = {
                {"Of what?", {bp_ofwhat=100}},
                {"I don't know what you're talking about.", {bp_no_history=100}},
                {"Why bring that up?", {bp_howknow=100}},
            }
        },

        {
            pos = {bp_prerequisite=0, wtf_marriage=200},
            text = "You don't know who.%.%.% Oh.%%\n\nThis is it...% Your family history...",
            pose = "facing_down",
            setPos = {bp_family_history=100, bp_prerequisite=100},
            responses = {
                {"Of what?", {bp_ofwhat=100}},
                {"I don't know what you're talking about.", {bp_no_history=100}},
                {"Why bring that up?", {bp_howknow=100}},
            }
        },

        {
            pos = {bp_ofwhat=100},
            pose = "left_of_couch",
            text = ".%.%.%Of senile dementia.%% Of...% forgetting everything.",
            rose = "normal",
            responses = {
                {"No I don't...", {bp_denial=100}},
                {"How do you know that?", {bp_howknow=100}},
                {"Oh.", {}}
            }
        },

        {
            pos = {bp_howknow=100},
            text = "Because...% You told me about this?%% It's your biggest fear...?",
            rose = "closed",
        },
        {
            pos = {bp_no_history=100},
            text = "What about your mom?%% And your grandma,% and great-aunt?%%\n.%.%.%Have you forgotten them too?",
            rose = "eyes_left",
        },

        {
            pos = {bp_denial=100},
            setPos = {bp_denial=200},
            text = "When this happened to your mom% she insisted% it wasn't happening,% " ..
                "that your grandma was a fluke.%% \"Strong genes.\"",
            rose = "closed",
        },
        {
            pos = {bp_denial=200},
            text = "You told me not to let you just deny it if it ever happened...%% happened% to you.%% " ..
                "So.%% Please,% don't deny it.",
            rose = "closed",
        },

        {
            pos = {phase=7, bp_anything=0, bp_guess_husband=0},
            text = "Can you remember anything about me? Anything at all?",
            setPos = {bp_anything=100},
            pose = "facing_left",
            rose = "normal",
            responses = {
                {"You do seem familiar...", {}},
                {"No, sorry...", {}},
                {"I guess you're my husband?", {bp_guess_husband=100}}
            }
        },
        {
            pos = {phase=7, bp_anything=0},
            text = "Surely you must remember SOMETHING about me...",
            pose = "left_of_couch",
            setPos = {bp_anything=100},
            responses = {
                {"You do seem familiar...", {}},
                {"No, sorry...", {}},
                {"I guess you're my husband?", {bp_guess_husband=100}}
            }
        },

        {
            pos = {bp_guess_husband=100, bp_prerequisite=100, told_was_husband=0},
            text = "Do you actually know that, or are you just guessing?%% Be honest.",
            pose = {"next_to_rose", "facing_down"},
            rose = "normal",
            responses = {
                {"I'm just guessing.", {bp_just_guessing=100}},
                {"I do remember...", {gu_prereq=500}, "gave_up"},
                {"What do you want me to say?", {bp_guess_husband=30}}
            }
        },
        {
            pos = {bp_guess_husband=130},
            pose = "right_of_rose",
            text = "I don't know...% That this is all just a weird joke?% That you took too far?% " ..
                "That the person I love is%.%.%. still here with me?"
        },
        {
            pos = {bp_guess_husband=200},
            pose = "facing_left",
            text = "Yeah, that's still true.%% But I mean, do you know anything else?",
            rose = "eyes_right"
        },
        {
            pos = {bp_guess_husband=100, told_was_husband=500},
            text = "Wellll%.%.%. yeah,% but I mean% I literally just told you that.",
            pose = "facing_left",
            rose = "eyes_left"
        },

        {
            pos = {phase=8,bp_just_guessing=0,bp_guess_husband=0},
            text = "Our wedding day was the happiest I'd ever seen you...",
            pose = {"facing_left", "pause", "bottom_of_stairs", "facing_right"},
            responses = {
                {"When was that, exactly?", {bp_when_married=1000}},
                {"How happy was I?", {bp_howhappy=100}},
                {"I don't remember it at all.", {}}
            }
        },
        {
            pos = {phase=8,bp_just_guessing=100,importance=3},
            text = "Yeah...%% That's what I thought...",
            pose = "bottom_of_stairs",
            rose = "closed",
            responses = {
                {"I'm sorry.", {}},
                {"It was worth a shot...", {}, "gave_up"},
                {"I don't have a choice.", {bp_havenochoice=100}}
            }
        },

        {
            pos = {bp_when_married=1000, bp_already_said_when=0},
            setPos = {bp_when_married=0,bp_already_said_when=500},
            text = "15 years ago? .%.%.% No, it was " .. os.date('%Y', os.time() - 27182818) .. ", in " ..
                os.date('%B', os.time() - 27182818) .. "...%% 17 years ago.",
            rose = "normal",
        },
        {
            pos = {bp_when_married=1000, bp_already_said_when=500},
            setPos = {bp_when_married=0},
            text = "17 years ago, in " .. os.date('%Y', os.time() - 27182818) .. ".%% I just told you that...%%" ..
                "Did you forget already?",
            rose = "normal",
        },

        {
            pos = {bp_howhappy=100},
            text = "You were ecstatic.%% Over the moon.%% We both were%.%.%. and we didn't want it to ever end.",
            pose = "facing_left",
            rose = "crying",
        },

        {
            pos = {bp_havenochoice=100},
            text = "What do you mean by that?",
            pose = "facing_left",
            rose = "normal",
            responses = {
                {"I don't know our backstory.", {}},
                {"I didn't choose to forget you.", {bp_havenochoice=100}},
                {"This game didn't give me the option.", {bp_notagame=500}},
            }
        },
        {
            pos = {bp_havenochoice=200},
            pose = "facing_right",
            text = "Oh%.%.%. Right,% of course.",
            rose = "normal",
        },

        {
            pos = {bp_notagame=500},
            text = "What...?%% Is this...%% some sort of GAME to you?",
            rose = "eyes_left",
            responses = {
                {"That's not what I meant.", {bp_whatdidyoumean=100}},
                {"No, of course not.", {}},
                {"Yeah, I downloaded it.", {}, "stroke"}
            }
        },
        {
            pos = {bp_whatdidyoumean=100},
            text = "Then what DID you mean by that?",
            rose = "normal",
            responses = {
                {"I don't know what's going on.", {}},
                {"I'm not sure.", {}},
                {"Ignore me.", {}, "wtf"}
            }
        },

        {
            pos = {phase=5, bp_prerequisite=0, bp_dontknowwho=0},
            text = "Wait...%% Do you not...% know who I am?",
            setPos = {bp_prerequisite=100},
            pose = {"right_of_rose", "facing_left"},
            responses = {
                {"You do seem familiar...", {}},
                {"No, sorry...", {}},
                {"I guess you're my husband?", {bp_guess_husband=100}}
            }
        },
        {
            pos = {phase=5, bp_prerequisite=0, bp_dontknowwho=500},
            text = "You...%% don't know who I am?",
            setPos = {bp_prerequisite=100},
            pose = {"right_of_rose", "facing_left"},
            responses = {
                {"You do seem familiar...", {}},
                {"No, sorry...", {}},
                {"I guess you're my husband?", {bp_guess_husband=100}}
            }
        },
        {
            pos = {phase=5, bp_prerequisite=0, bp_dontknowwho=1000},
            text = "You really don't know...?",
            setPos = {bp_prerequisite=100},
            pose = {"right_of_rose", "facing_left"},
            responses = {
                {"You do seem familiar...", {}},
                {"No, sorry...", {}},
                {"I guess you're my husband?", {bp_guess_husband=100}}
            }
        },

        {
            pos = {phase=9, bp_prerequisite=100},
            text = "We've worked so hard on everything...%% Building this home together...%% I was hoping it " ..
                "wouldn't turn out this way.",
            pose = {"left_of_couch", "pause", "facing_right", "pause", "pause", "facing_left"},
            rose = "eyes_right",
            responses = {
                {"I think I love you.", {}},
                {"Please don't leave me.", {bp_dont_leave=100}},
                {"I'm scared.", {bp_so_scared=100}},
                {nil, {bp_left_hanging=100}}
            }
        },

        {
            pos = {bp_dont_leave=100},
            text = "No, of course I'm not going to just leave you...%% " ..
                "Don't you know me better than...%% ...Oh.",
            pose = {"next_to_rose", "facing_left"}
        },

        {
            pos = {bp_left_hanging=100},
            text = "Yeah, I dunno what to say either.",
            rose = "normal",
        },

        {
            pos = {bp_so_scared=100},
            text = "Yeah%.%.%. Me too.",
            pose = "facing_left",
            rose = "normal",
        },

        {
            pos = {phase=10, bp_explains_so_much=0, bp_prerequisite=0},
            text = "Ha ha ha, I just realized...%% This is what happened to your mom.%% Oh crap.",
            pose = "bottom_of_stairs",
            setPos = {bp_explains_so_much=100,bp_prerequisite=100},
            responses = {
                {"My mom?", {}},
                {"Please don't laugh...", {bp_dont_laugh=100}},
                {"Explains what?", {}},
                {nil, {bp_left_hanging=100}}
            }
        },
        {
            pos = {phase=10, fun=20, bp_explains_so_much=0, bp_prerequisite=100},
            text = "Ha ha ha, okay, this.%.%.% this explains so much...",
            pose = "bottom_of_stairs",
            setPos = {bp_explains_so_much=100,bp_prerequisite=100},
            responses = {
                {"What's so funny?", {}},
                {"Please don't laugh...", {bp_dont_laugh=100}},
                {"Explains what?", {}},
                {nil, {bp_left_hanging=100}}
            }
        },
        {
            pos = {phase=10, fun=50, bp_explains_so_much=0, bp_prerequisite=100},
            text = "Ha ha ha, oh god.%.%.% this explains so much...",
            pose = "bottom_of_stairs",
            setPos = {bp_explains_so_much=100,bp_prerequisite=100,gu_prereq=500},
            responses = {
                {"What's so funny?", {}},
                {"Please don't laugh...", {bp_dont_laugh=100}},
                {"Explains what?", {}},
                {nil, {bp_left_hanging=100}}
            }
        },

        {
            pos = {bp_dont_laugh=100},
            text = "Sorry, it's just...%% It's either that or cry, you know?",
            rose = "normal"
        },

        {
            pos = {phase=11, bp_prerequisite=100},
            text = "You don't... you don't remember anything, do you.",
            pose = "right_of_rose",
            responses = {
                {"I don't believe you.", {}},
                {"I have no idea who you are.", {}},
                {"Why are you trying to confuse me?", {}},
            }
        },

        {
            pos = {phase=12, bp_i_wonder=0, bp_prerequisite=100},
            text = "I wonder how long this has been going on... Is this why you've been so forgetful lately?",
            pose = "next_to_rose",
            setPos = {bp_i_wonder=100},
            responses = {
                {"What have I forgotten?", {bp_likewhat=100}},
                {"I'm so confused.", {}},
                {"What's going on?", {}}
            }
        },
        {
            pos = {phase=12, bp_i_wonder=0, bp_prerequisite=100},
            text = "I wonder how long this has been going on... Let's go to the doctor.",
            setPos = {bp_i_wonder=100},
            responses = {
                {"What have I forgotten?", {bp_likewhat=100}},
                {"I'm so confused.", {}},
                {"What's going on?", {}}
            }
        },

        {
            pos = {phase=13, bp_sullen=0, bp_prerequisite=100},
            text = "Let's go to a doctor, okay?",
            pose = "next_to_rose",
            maxCount = 20,
            responses = {
                {"A doctor? Why?", {}},
                {"I don't want to...", {bp_sullen=100}},
                {"You're trying to trick me.", {}},
                {nil, {bp_sullen=100}}
            }
        },
        {
            pos = {phase=13, bp_prerequisite=100},
            text = "Come on, let's see the doctor.",
            pose = "next_to_rose",
            maxCount = 20,
            responses = {
                {"A doctor? Why?", {}},
                {"I don't want to...", {bp_sullen=100}},
                {"You're trying to trick me.", {}},
                {nil, {bp_sullen=100}}
            }
        },
        {
            pos = {phase=13, bp_sullen=100, bp_prerequisite=100},
            text = "Please don't be like this...%% Let's go to the doctor,% okay hon?",
            setPos = {bp_sullen=0},
            pose = "below_doors",
            maxCount = 20,
            responses = {
                {"A doctor? Why?", {}},
                {"I don't want to...", {}},
                {"What have I forgotten?", {bp_likewhat=100}},
                {nil, {bp_sullen=100}}
            }
        },

        {
            pos = {bp_likewhat=200},
            setPos = {bp_likewhat=100},
            text = "You've forgotten who I am..."
        },
        {
            pos = {bp_likewhat=200},
            setPos = {bp_likewhat=100},
            text = "You've forgotten what we're married..."
        },
        {
            pos = {bp_likewhat=200},
            setPos = {bp_likewhat=100},
            text = "You've forgotten that I love you..."
        },
    },

    -- path where Greg is feeling alienated
    alienated = {
        {
            pos = {silence_total=3, silence_cur=1},
            text = "What's with the cold shoulder?",
            pose = "facing_left",
            responses = {
                {"What should I say?", {}},
                {"Are you in the right home?", {}},
                {"Who do you think you are?", {}, "wtf"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {silence_total=6, silence_cur=1},
            text = "So you're back on that now, huh?",
            pose = "facing_right",
            responses = {
                {"Back to what?", {}},
                {"I think you're confused.", {}},
                {"Who are you and why are you in my home?", {}, "brain_problems"},
                {nil, {}, "silence"}
            }
        },

        {
            pos = {interrupted=2},
            text = "Could you let me finish?"
        },
        {
            pos = {interrupted=4},
            text = "Could you please let me finish?"
        },
        {
            pos = {interrupted=7},
            text = "Could you PLEASE let me finish?",
            pose = "clench",
        },
        {
            pos = {interrupted=9},
            text = "I don't really like being talked over, you know."
        },
        {
            pos = {interrupted=12},
            text = "I don't like being talked over.%%\nStop it.%%",
            cantInterrupt=true
        },

        {
            pos = {alien_nonanswer=100},
            text = "...%% I guess, but that's not really what I asked.",
        },
        {
            pos = {alien_nonanswer=200},
            text = "Hmm... technically true, but... what?",
            pose = {"right_of_rose", "facing_left"}
        },
        {
            pos = {alien_nonanswer=300},
            text = "I feel like you're playing a game here.",
            pose = {"left_of_stairs", "facing_left"},
            responses = {
                {"Not a game...", {}},
                {"Yeah, it's called 'Refactor'", {}, "brain_problems"},
                {"I want the " .. playlist.lastDesc .. " back.", {}, "brain_problems"}
            }
        },

        {
            pos = {phase=1},
            text = "Why are you down here by yourself?",
            pose = {"right_of_rose", "facing_left"},
            responses = {
                {"Aren't I normally here by myself?", {}, "wtf"},
                {"Oh... I forgot I had company.", {alien_company=100}},
                {"It's morning.", {alien_nonanswer=100}}
            },
        },

        {
            pos = {alien_company=100},
            text = "... Company?",
            setState = "brain_problems",
            pose = {"left_of_stairs", "facing_left"},
            responses = {
                {"Yeah, you.", {}},
                {"Do I know you?", {}},
                {"Who are you?", {}, "last_night"}
            }
        },

        {
            pos = {phase=2, mention_lastnight=0, alien_asked_stillmad=0},
            text = "Still mad at me about last night, huh?",
            pose = "couch_sitting",
            setPos = {mention_lastnight=100, alien_asked_stillmad=100},
            responses = {
                {"I guess.", {}},
                {"Last night?", {}, "last_night"},
                {"No...", {}, "normal"}
            }
        },
        {
            pos = {phase=2, mention_lastnight=100, alien_asked_stillmad=0},
            text = "Still mad at me about it, huh?",
            setPos = {alien_asked_stillmad=100},
            responses = {
                {"I guess.", {}},
                {"What happened?", {}, "last_night"},
                {"No...", {}, "normal"}
            }
        },
        {
            pos = {phase=3},
            text = "Well, you're just a bundle of sunshine this morning.",
            rose = "eyes_left",
            responses = {
                {"Yeah... You know me...", {}, "normal"},
                {"Get out.", {}, "wtf"},
                {"Would you rather an icy stare?", {}}
            }
        },
        {
            pos = {phase=4},
            text = "You're awfully upset at me. What the heck is going on lately?",
            pose = "couch_sitting",
            responses = {
                {"Time keeps on passing.", {alien_nonanswer=100}},
                {"Lately...?", {}, "normal"},
                {"Trying to figure something out.", {}}
            }
        },
        {
            pos = {phase=5},
            text = "C'mon, spouses are supposed to be open with each other.%% Could you please just " ..
                "tell me what's going on?",
            pose = "couch_sitting",
            rose = "normal",
            responses = {
                {"Spouses?", {}, "brain_problems"},
                {"You're getting ahead of yourself.", {}},
                {"I don't know what's going on.", {alien_dont_leave=-50}}
            }
        },
        {
            pos = {phase=6},
            text = "Look, I get it, you're stressed out about things lately...%% But why can't you just open up to me?",
            rose = "eyes_left",
            pose = "left_of_couch",
            responses = {
                {"Why should I?", {}},
                {"But I don't know you.", {}, "brain_problems"},
                {"It's a secret to everyone.", {}, "wtf"}
            }
        },
        {
            pos = {phase=7},
            text = "I...%% uh...%% What?",
            rose = "eyes_right",
            responses = {
                {"I don't even know you.", {}, "wtf"},
                {"... Never mind.", {}},
                {"Yes, that.", {alien_nonanswer=100}}
            },
        },
        {
            pos = {phase=8},
            text = "Do you think us marrying was a mistake?",
            pose = {"right_of_rose", "facing_left"},
            responses = {
                {"No...", {alien_dont_leave=100}},
                {"Maybe?", {}},
                {"Only if it was a mistake.", {alien_nonanswer=100}}
            }
        },
        {
            pos = {phase=9},
            text = "Lately things have been so strained between us, and I'm feeling like you're pushing me away for " ..
                "some reason. Why?",
            rose = "normal",
            pose = {"right_of_rose", "facing_right"},
            responses = {
                {"I have no idea what you're talking about.", {}, "wtf"},
                {"I don't even know who you are.", {}, "brain_problems"},
                {"I'm not sure.", {}}
            }
        },
        {
            pos = {phase=10},
            text = "Ha ha, okay, this is just...%% Sad. I don't want things to end this way.",
            rose = "eyes_right",
            setState = "alien_endgame",
            responses = {
                {"They're ending?", {}},
                {"Wait. Don't leave.", {alien_dont_leave=100}},
                {"Who are you? Am I on a prank show?", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=10.1},
            text = "Ha ha, wow, this is just...% what the hell is going on here.",
            pose = {"bottom_of_stairs", "facing_left"},
            setState = "alien_endgame",
            responses = {
                {"I don't know.", {}},
                {"Who the hell are you?", {}, "gave_up"},
                {"Who are you?", {}, "brain_problems"}
            }
        },
    },

    alien_endgame = {
        {
            pos = {phase=11},
            text = "When we met, you said you couldn't be in love for very long. I thought I proved you wrong. " ..
                " %.%.%. Maybe you were right.",
            pose = "facing_right",
            rose = "eyes_left",
            responses = {
                {"Maybe so.", {}},
                {"I'm sorry.", {alien_dont_leave=100}},
                {"Ugh, melodrama.", {}, "gave_up"}
            }
        },
        {
            pos = {phase=11.5},
            text = "I worry about you. But... is the feeling even mutual?",
            pose = "facing_left",
            rose = "eyes_left",
            responses = {
                {"How can I?", {}},
                {"I'm sorry.", {alien_dont_leave=100}},
                {"No.", {alien_dont_leave=-100}}
            }
        },

        {
            pos = {phase=12, alien_dont_leave=0},
            text = "I'm sorry, but I just can't do this anymore.",
            pose = "below_doors",
            rose = "eyes_right",
            setState = "gave_up",
            responses = {
                {"Can't do what?", {}},
                {"Please don't leave me.", {alien_abort_leave=150}, "alien_endgame"},
                {"I'm sorry.", {}},
            }
        },

        {
            pos = {phase=12, alien_dont_leave=150},
            text = "Look, I% kinda% want to leave you, but that's not the adult thing to do.%% " ..
                " Let's work on this,% together,% okay?",
            pose = {"right_of_rose", "facing_left"},
            rose = "eyes_right",
            responses = {
                {"Okay...", {}},
                {"I guess...", {}},
                {"But who are you?", {}, "brain_problems"}
            },
        },

        {
            pos = {phase=12, alien_abort_leave=150},
            text = "You're right...% Let's work on this together, okay?",
            rose = "closed",
            pose = {"right_of_rose", "facing_left"},
        },

        {
            pos = {phase=13},
            text = "I think I know someone we can talk to.",
            rose = "closed",
        },
        {
            pos = {phase=13.1},
            text = "We just need to keep an open mind.",
        },
        {
            pos = {phase=13.2},
            text = "But%.%.%. we %really% shouldn't rush through everything,% you know?",
            cantInterrupt = true,
            rose = "closed",
            responses = {
                {"Yeah, I guess not.", {}},
                {"I'm sorry...", {}},
                {"I'll try harder.", {}}
            }
        },
        {
            pos = {phase=14},
            text = "",
            ended = true
        }

    },

    -- path where Greg has given up on helping Rose due to brain problems
    gave_up = {
        {
            pos = {interrupted=4},
            text = "Please, I...%% I know you want to say something but..."
        },
        {
            pos = {interrupted=7},
            text = "This is hard for me to talk about, and I really want to get through it, okay?",
        },
        {
            pos = {interrupted=10},
            text = "I%.%.%. understand you're confused.%% This is really hard for me too.",
        },

        {
            pos = {gu_prereq=0},
            setPos = {gu_prereq=500},
            text = "Oh%.%.%. oh god, I know exactly what's going on here."
        },

        {
            pos = {phase=1,gu_prereq=500},
            text = "Hi, hon...",
            pose = "right_of_rose",
            rose = "eyes_right",
            responses = {
                {"Hello... you...", {}},
                {"Good morning.", {}},
                {"Who are you?", {}},
            }
        },

        {
            pos = {phase=2,gu_prereq=500},
            text = "Our memories are what define us as a person.",
            pose = "facing_right",
            rose = "eyes_right",
            responses = {
                {"...Okay?", {}},
                {"Sure.", {}},
                {"I don't understand.", {}}
            }
        },

        {
            pos = {phase=3,gu_prereq=500},
            -- ATTN data-miners: This is metatextual.
            text = "If you don't have a memory of an experience, can you really say that you've experienced it?",
            pose = "facing_down",
            rose = "eyes_right",
            responses = {
                {"What are you getting at?", {}},
                {"I'm not sure where this is going.", {}},
                {"Why are you talking about this?", {}},
            }
        },

        {
            pos = {phase=4,gu_prereq=500},
            text = "One's memories are% perhaps% " ..
                "the most obvious defining characteristic of one's self. To lose that is to find oblivion.",
            pose = "facing_left",
            rose = "eyes_left",
            responses = {
                {"Who are you?", {}},
                {"What are you doing here?", {}},
                {"This is all fascinating but...", {}},
            }
        },

        {
            pos = {phase=5,gu_prereq=500},
            text = "We've been married for so long...%% I worry about us drifting apart.%% I'm afraid of losing "..
                "you%.%.%.",
            pose = {"below_doors", "facing_up"},
            rose = "closed",
            setPos = {gu_already_lost=500},
            responses = {
                {"We're married?", {}},
                {"What's going on?", {}},
                {"Who ARE you?", {}}
            }
        },
        {
            pos = {gu_already_lost=500},
            text = "...but maybe you're already lost."
        },

        {
            pos = {phase=6,gu_prereq=500},
            text = "You were always afraid of this...%% and I always brushed it off.%% " ..
                "Now I realize that this IS going to be difficult...%% for me.",
            pose = {"right_of_rose", "facing_right"},
            rose = "eyes_right",
            responses = {
                {"What are you talking about?", {}},
                {"What is difficult?", {}},
                {"I don't...", {}}
            }
        },

        {
            pos = {phase=7,gu_prereq=500},
            text = "I love you.%% These past 17 years have been %so% wonderful for me.%% For both of us.",
            pose = "facing_left",
            responses = {
                {"Are you breaking up with me?", {}},
                {"I really don't know.", {}},
                {"Who are you?", {}}
            }
        },

        {
            pos = {phase=8,gu_prereq=500},
            text = "What do you remember?%% How long have we lived here together?%% How long have you lived here " ..
                "at all?",
            pose = "facing_right",
            responses = {
                {"How long?", {}},
                {"Who are you?", {}},
                {"Seems like forever.", {}}
            }
        },

        {
            pos = {phase=9,gu_prereq=500},
            text = "You look at me like I'm a stranger,% like I don't belong here,% like I'm just someone you " ..
                "picked up last night,% like...",
            pose = "facing_down",
            rose = "eyes_left",
            responses = {
                {"Who are you?", {}},
                {"But we did just meet.", {}},
                {"I'm sorry.", {gu_sorry=100}}
            }
        },

        {
            pos = {gu_sorry=100},
            text = "Are you, though? %.%.%.CAN you be?",
            pose = {"right_of_rose", "facing_left"},
            rose = "normal",
            responses = {
                {"No.", {}},
                {"I can try.", {}},
                {"Of course.", {gu_sorry=100}}
            }
        },

        {
            pos = {gu_sorry=200},
            text = "You don't even KNOW me.",
            pose = "facing_right",
            responses = {
                {"I don't...", {}},
                {"But you know me...", {gu_youknowme=100}},
                {"I want to.", {}}
            }
        },

        {
            pos = {gu_youknowme=100},
            text = "Is that even enough, though?%% For me to love someone who won't...% can't...% " ..
                " even remember who I am?"
        },

        {
            pos = {phase=10,gu_prereq=500},
            text = "Ha ha.%.%.% everything we've been through...%% it's just meaningless now, isn't it?",
            pose = "left_of_couch",
            cantInterrupt=true
        },

        {
            pos = {phase=10.5,gu_prereq=500},
            pose = "right_of_rose",
            text = "What does it matter? You won't even remember this anyway.",
            cantInterrupt=true
        },

        {
            pos = {phase=11,gu_prereq=500},
            pose = "below_doors",
            text = "% .%.%.% %%You don't even...% remember...%% me.",
            rose = "normal",
            cantInterrupt=true
        },

        {
            pos = {phase=11.5,gu_prereq=500},
            text = "I just can't do this anymore.",
            pose = {"below_doors", "facing_up"},
            setPos = {leaving=1000},
            cantInterrupt=true,
        },

        {
            pos = {phase=12,gu_prereq=500,leaving=1000},
            text = "I hope you get the help you need.",
            pose = {"below_doors","leaving","pause","gone"},
            setPos = {gone=1000},
            cantInterrupt=true
        },

        {
            pos = {gone=1000},
            text = "",
            ended = true
        }

    },

    -- state where Greg believes Rose is having a stroke
    stroke = {
        {
            pos = {phase=5, stroke_state=0},
            text = "Hon? %.%.%. Are you feeling okay?",
            pose = {"next_to_rose", "facing_left"},
            rose = "closed",
            responses = {
                {"I'm not sure...", {}},
                {"I'm FINE.", {}, "wtf"},
                {"Who are you?", {}, "brain_problems"}
            }
        },

        {
            pos = {phase=6, stroke_state=0},
            text = "What's going on?% Are you feeling% okay?",
            pose = {"next_to_rose", "facing_left"},
            responses = {
                {"I'm not sure...", {}},
                {"I'm kinda dizzy?", {}},
                {"I don't know who you are?", {}}
            }
        },

        {
            pos = {phase=7, stroke_state=0},
            text = "Can you feel your face? Try to wiggle your fingers.",
            pose = {"next_to_rose", "facing_left"},
            responses = {
                {"I can't move my hands.", {stroke_nomovehands=100}},
                {"Numb...", {}},
                {"What?", {}}
            }
        },

        {
            pos = {stroke_nomovehands=100},
            text = "You can't? Not even a little?",
            pose = {"next_to_rose", "facing_left"},
            responses = {
                {"Nobody drew the frames for that.", {}},
                {"They're like little squares.", {}},
                {"No...", {}}
            }
        },

        {
            pos = {phase=8},
            text = "Could you try repeating this sentence? \"Everything is going to be fine, and I'm doing okay.\"",
            rose = "eyes_right",
            pose = {"next_to_rose", "facing_left"},
            responses = {
                {"But I'm not...", {}},
                {"I don't think I have enough characters.", {}},
                {"Why?", {}}
            }
        },

        {
            pos = {phase=9},
            text = "Your speech is pretty slurred, and I think you might be having a stroke. Let's get you to " ..
                "the hospital, okay?",
            pose = {"next_to_rose", "facing_left"},
            responses = {
                {"What do you mean?", {}},
                {"I feel fine...", {}},
                {"Who ARE you?!", {}}
            }
        },

        {
            pos = {phase=10.5},
            text = "Emergency services? It's my spouse, something's very wrong with them.",
            pose = {"right_of_rose", "on_phone"},
            setPos = {stroke_state=1000}
        },

        {
            pos = {phase=13, stroke_state=1000},
            text = "Someone is coming.... everything will be okay.",
            pose = {"kneeling_by_rose"},
            rose = "crying",
            maxCount=5
        },
        {
            pos = {phase=13, stroke_state=1000},
            text = "Shh, shh, it's okay...%% Everything will be fine...%#%#%#",
            pose = {"kneeling_by_rose"},
            maxCount=5
        },
        {
            pos = {phase=13, stroke_state=1000},
            text = "They'll be here soon.",
            pose = {"kneeling_by_rose"},
            maxCount=5
        },
        {
            pos = {phase=13, stroke_state=1000},
            text = "I love you.%#%\n\nWe'll get through this.",
            pose = {"kneeling_by_rose"},
            maxCount=5
        },
        {
            pos = {phase=13, stroke_state=1000},
            text = "It's okay, I'm here for you.",
            pose = {"kneeling_by_rose"},
            maxCount=5
        },
    },

    -- vacation time!
    vacation = {
        {
            pos = {phase=11},
            text = "Yeah%.%.%. This is just what we need.",
            pose = {"next_to_rose", "facing_down"},
            rose = "eyes_right",
        },
        {
            pos = {phase=12},
            text = "I love you so much. #",
            pose = "kneeling_by_rose",
            rose = "eyes_closed",
        },
        {
            pos = {phase=13},
            text = "I know just where we should go.",
            pose = "below_doors",
            rose ="eyes_left",
            responses = {
                {"Where?", {vac_where=1000}},
                {"When?", {vac_when=1000}},
                {"Why?", {vac_why=1000}},
            }
        },
        {
            pos = {phase=13.1},
            text = "Yeah, it'll be nice and relaxing...",
            pose = "below_doors",
            rose = "eyes_right",
        },
        {
            pos = {phase=13.2},
            text = "We'll have so much fun...",
            pose = "below_doors",
        },
        {
            pos = {phase=13.3},
            text = "Something we'll remember...%% for%ev%er.%.%.",
            pose = "below_doors",
            rose = "eyes_closed",
        },
        {
            pos = {phase=14},
            pose = "below_doors",
            rose = "crying",
            text = "",
            ended = true
        },

        {
            pos = {vac_where=1000},
            text = "You'll see.%% I know you'll enjoy it.",
            pose = {"right_of_rose", "facing_left"},
        },
        {
            pos = {vac_when=1000},
            text = "Let's go as soon as we can.%% We can take the train there.%% Pack light.",
            pose = {"right_of_rose", "facing_up"},
        },
        {
            pos = {vac_why=1000},
            text = "It's been way too long since we've gotten out of the city.%% We could use some...% fresh air.",
            pose = {"right_of_rose", "facing_right"},
        },
    }

 }

return dialog
