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

local dialog = {
    start_state = "intro",

    -- things that are always available
    always = {

    },

    -- starting point
    intro = {
        {
            pos = {fun=1},
            text = "# Good morning, dear! #",
            pose = "right_of_rose",
            responses = {
                {"Hi...", {}, "normal"},
                {"Who are you...?", {}, "last_night"},
                {"What are you doing here?", {}, "alienated"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {fun=37},
            text = "Good morning... how are you feeling today?",
            pose = {"left_of_couch", "facing_left"},
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
            pose = "right_of_rose",
            responses = {
                {"Um... hello.", {}, "normal"},
                {"Oh, sorry, I didn't hear you.", {}, "normal"},
                {"Mmhmm.", {}, "anger"}
            }
        },
        {
            pos = {phase=2},
            text = "Hello? I said good morning.",
            pose = "next_to_rose",
            responses = {
                {"Um... hello.", {}, "normal"},
                {"Oh, sorry, I didn't hear you.", {}, "normal"},
                {"Mmhmm.", {}, "anger"}
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
            pose = "facing_left",
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
            responses = {
                {"Who are you?", {}, "brain_problems"},
                {"You're intruding.", {}, "alienated"},
                {"I'm not sure what's going on.", {}, "normal"}
            }
        },

        {
            pos = {phase=6},
            text = "This isn't like you.",
            pose = "facing_left",
            responses = {
                {"Like who?", {}, "normal"},
                {"Who ARE you?", {}, "brain_problems"},
                {"How should I be?", {}, "normal"}
            }
        },
        {
            pos = {phase=6},
            text = "This is just like you.",
            pose = {"below_doors", "facing_right"},
            responses = {
                {"What is?", {}, "normal"},
                {"Sorry, do I know you?", {}, "brain_problems"},
                {"I'm sorry.", {}, "normal"}
            }
        },

        {
            pos = {phase=7},
            text = "Is this about what I said last night? It was only a joke.",
            pose = {"below_doors", "facing_right"},
            responses = {
                {"And I'm sure it was funny.", {}, "brain_problems"},
                {"Well it wasn't very funny.", {}, "last_night"},
                {"I don't remember what you said.", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=7},
            text = "Is this about what I said last night? I'm sorry, it was out of line.",
            pose = {"below_doors", "facing_left"},
            responses = {
                {"...What did you say?", {}, "brain_problems"},
                {"Yes, it was.", {}, "normal"},
                {"It isn't that...", {}, "normal"}
            }
        },
        {
            pos = {phase=7},
            text = "If this is about what I said last night, well%.%.%.%% you deserved it.",
            pose = {"below_doors", "facing_right"},
            responses = {
                {"...What did you say?", {}, "brain_problems"},
                {"I doubt it.", {}, "normal"},
                {"Yeah, I guess I did.", {}, "normal"}
            }
        },

        {
            pos = {phase=8},
            text = "I'm just not sure why you're giving me the silent treatment, here...",
            pose = {"below_doors", "facing_up"},
            responses = {
                {"I feel... numb...", {}, "stroke"},
                {"Who are you?", {}, "brain_problems"},
                {"Please just go away...", {}, "alienated"}
            }
        },
        {
            pos = {phase=8},
            text = "So you can cut it out with the silent treatment.",
            pose = {"below_doors", "facing_right"},
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
            pose = {
                "bottom_of_stairs", "left_of_stairs", "bottom_of_stairs", "left_of_stairs",
                "left_of_couch",
                "bottom_of_stairs", "left_of_stairs", "bottom_of_stairs", "left_of_stairs",
            },
            cantInterrupt=true
        },
    },

    -- path where Greg thinks everything is normal
    normal = {
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
            pos = {nrm_going_somewhere=500},
            text = "What? No, I was just wondering if you'd eaten.",
            pose = {"right_of_rose", "facing_left"},
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
                "Sorry to nag, I know you hate that."
        },

        {
            pos = {phase=2, normal_tired=0, asked_about_breakfast=0},
            text = "Have you had breakfast already?",
            pose = "kitchen",
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
            responses = {
                {"Who are you?", {}, "brain_problems"},
                {"What are you doing here?", {nrm_what_doing=100}, "last_night"},
                {"Why are you in my house?", {}, "wtf"}
            }
        },

        {
            pos = {phase=3, normal_solastnight=0},
            text = "It's a beautiful morning, isn't it?",
            responses = {
                {"Yeah...", {}},
                {"Why are you in my house?", {}, "wtf"},
                {"Who are you?", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=3, normal_camehome=0, normal_tired=0},
            text = "So, last night...",
            responses = {
                {"What about it?", {normal_solastnight=100}},
                {"I'm sorry, but who are you?", {}, "brain_problems"},
                {"What happened?", {}, "last_night"}
            }
        },

        {
            pos = {phase=4, normal_camehome=0, normal_tired=50},
            text = "When we got home last night I was worried about you.",
            setPos = {normal_camehome=100},
            responses = {
                {"We came home together?", {normal_whathuh=100}},
                {"This is my home...", {}, "brain_problems"},
                {"What happened last night?", {}, "last_night"}
            }
        },
        {
            pos = {phase=4, normal_camehome=0, normal_tired=100},
            text = "When we got home last night I was afraid I'd upset you.",
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
            pose = "facing_right",
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
            setPos = {normal_wemarried=100},
            responses = {
                {"We're... married?", {}, "brain_problems"},
                {"I... guess it just didn't come up.", {}},
                {"Who are you?", {}, "last_night"}
            }
        },

        {
            pos = {phase=6, normal_wemarried=100, normal_undercontrol=0, normal_sorry=100},
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
        {
            pos = {phase=2, nrm_what_doing=0, ln_whatcameover=0},
            text = "I'm sorry, hon. I really don't know what came over me last night.",
            setPos = {ln_whatcameover=100},
            responses = {
                {"It's okay.", {}, "normal"},
                {"What happened?", {}},
                {"... All right.", {}, "alienated"},
            }
        },

        {
            pos = {phase=3, nrm_what_doing=0, ln_whatcameover=100},
            text = "Just... something you said set me off a little bit...% and...% you know how I get sometimes.",
            pose = "left_of_couch",
            responses = {
                {"I do?", {lastnight_ignorance=200}},
                {"I'm sure it was okay.", {}},
                {"I don't remember.", {lastnight_ignorance=100}},
            }
        },

        {
            pos = {phase=3, nrm_what_doing=100},
            text = "I just took a walk after we got home,% to clear my head.% You were already asleep when I got back.",
        },

        {
            pos = {phase=3.5, nrm_what_doing=0},
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
            responses = {
                {"Why?", {}, "alienated"},
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
            pos = {phase=4, asked_about_breakfast=0},
            text = "Say, have you eaten breakfast yet?",
            setPos = {asked_about_breakfast=500},
            pose = "kitchen",
            responses = {
                {"Yeah.", {lastnight_breakfast=100}},
                {"No.", {lastnight_breakfast=-100}},
                {"I'm not sure.", {lastnight_unsure_breakfast=100}},
            }
        },

        {
            pos = {lastnight_breakfast=100},
            pose = "behind_rose",
            text = "Really? Oh, you must have done the dishes already. Okay.",
        },
        {
            pos = {lastnight_breakfast=-100},
            pose = "behind_rose",
            text = "Oh...% you really should eat something.% You know what the doctor said about that.%% " ..
                "Um, sorry to nag you about it...% Again..."
        },

        {
            pos = {lastnight_unsure_breakfast=100},
            text = "You%.%.%. aren't sure if you've had breakfast?%% Are you feeling okay?",
            pose = "right_of_rose",
            responses = {
                {"I don't know.", {}, "brain_problems"},
                {"Yeah, I guess.", {lastnight_blackout=100,lastnight_feeling_okay=100}},
                {"No... I'm not...", {}, "brain_problems"}
            }
        },

        {
            pos = {phase=5},
            text = "But anyway...%% We've been married a while, I guess this was inevitable, right?",
            responses = {
                {"We're married?", {}, "brain_problems"},
                {"Yeah, I guess so.", {lastnight_ignorance=-50}},
                {"Who are you, again?", {}, "brain_problems"}
            }
        },

        {
            pos = {phase=6},
            text = "I guess I'm just nervous that we're sort of drifting apart lately.% " ..
                "And you know how I worry about that.",
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
            setPos = {bp_prerequisite=100},
            responses = {
                {"No.", {}, "brain_problems"},
                {"You're my husband...right?", {lastnight_yeah_husband=100}},
                {"Of course I do.", {}, "wtf"},
                {nil, {}, "silence"}
            }
        },

        {
            pos = {phase=9, lastnight_yeah_husband=0},
            text = "Heh... Come on, you know I don't like when you joke about this stuff.",
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
                {"Yeah, I think so?", {}, "normal"},
                {"Everything seems weird.", {lastnight_feeling_weird=100}}
            }
        },
        {
            pos = {phase=9, lastnight_yeah_husband=100, lastnight_feeling_okay=0},
            text = "Um, yeah...%% I am...%% Are you feeling okay?",
            responses = {
                {"No, I'm not.", {}, "brain_problems"},
                {"Yeah, I think so?", {}, "normal"},
                {"Everything seems weird.", {lastnight_feeling_weird=100}}
            }
        },

        {
            pos = {phase=9, lastnight_feeling_weird=100},
            text = "Yeah,% I guess we have a lot of things to work through.",
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
                {"What are we talking about?", {}, "brain_problems"},
                {"I think so...?", {lastnight_samething=1000}},
                {"I don't even know.", {lastnight_ignorance=1}},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {phase=10, fun=50, lastnight_samething=0},
            text = "Ha ha, what? Are we even talking about the same thing?",
            responses = {
                {"What are we talking about?", {}, "brain_problems"},
                {"I think so...?", {lastnight_samething=1000}},
                {"Probably not.", {}, "normal"},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {phase=10.5, lastnight_samething=1000},
            text = "I'm just not sure what's going on here.",
            responses = {
                {"I'm sorry... I'm just in a strange mood.", {}},
                {"Neither do I.", {}, "brain_problems"},
                {"What's real anymore?", {}, "brain_problems"}
            }
        },
        {
            pos = {phase=10.5, lastnight_samething=0},
            text = "I just don't know what we should do next...%% I know, let's go on a vacation.",
            rose = "closed",
            responses = {
                {"Yeah... take some more pictures...", {}, "vacation"},
                {"Yeah... make some new memories...", {}, "vacation"},
                {"But I don't even know you...", {}, "brain_problems"},
                {nil, {}, "brain_problems"}
            }
        },

    },

    -- path where Greg has determined Rose is having brain problems
    brain_problems = {
        {
            pos = {phase=2.5},
            setPos = {bp_prerequisite=100},
            text = "Hon, are you feeling okay?",
            pose = "right_of_rose",
            responses = {
                {"Yeah.", {}},
                {"No.", {bp_not_okay=100}},
                {"Who are you?", {}}
            }
        },

        {
            pos = {bp_not_okay=100},
            text = "What's the matter?",
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
            pose = "facing_right",
            responses = {
                {"Like what?", {bp_stranger=0}},
                {"No I haven't...", {bp_stranger=10,bp_yes_you_have=50}},
                {"Who are you?", {bp_stranger=20}}
            }
        },

        {
            pos = {bp_yes_you_have=50, bp_prerequisite=100},
            text = "Yes you have.% You just don't remember forgetting...% of course%.%.%."
        },

        {
            pos = {phase=4, bp_stranger=0},
            text = "Please stop looking at me like that. Like I'm a stranger...",
            pose = "right_of_rose",
            responses = {
                {"But you are.", {bp_stranger=1000}},
                {"Sorry.", {bp_stranger=1000}},
                {"I don't know who you are.", {bp_stranger=1000}}
            }
        },
        {
            pos = {phase=4, bp_stranger=10},
            setPos = {bp_prerequisite=100},
            pose = {"right_of_rose", "facing_left"},
            text = "Please stop looking at me like that. I'm not a stranger.",
            responses = {
                {"But you are.", {bp_stranger=1000}},
                {"Sorry.", {bp_stranger=1000}},
                {"I don't know who you are.", {bp_stranger=1}}
            }
        },
        {
            pos = {phase=4, bp_stranger=20},
            text = "Stop looking at me like that. I'm not a stranger...% Am I?",
            pose = {"right_of_rose", "left_of_couch", "facing_left"},
            responses = {
                {"You are to me.", {bp_stranger=1000}},
                {"Yes?", {bp_stranger=1000}},
                {"I don't know who you are.", {bp_stranger=1000}}
            }
        },

        {
            pos = {phase=5, bp_prerequisite=100},
            text = "We've been married so long...% I never thought your memories of ME would be the first to go.",
            setPos = {told_was_husband=500},
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
        },
        {
            pos = {bp_howlong=100, bp_already_said_when=500},
            setPos = {bp_howlong=0},
            text = "17 years ago. Did you forget already?"
        },

        {
            pos = {phase=6, bp_family_history=0, fun=0, bp_prerequisite=100},

            text = "But you have a family history of this.%.%.%",
            setPos = {bp_family_history=100},
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
            responses = {
                {"Of what?", {}},
                {"No I don't...", {bp_no_history=100}},
                {"How do you know that?", {bp_howknow=100}},
            }
        },
        {
            pos = {phase=6, bp_family_history=0, bp_prerequisite=0},
            text = "You do have a family history of.%.%.% Oh.%%%\n\nOH.",
            pose = "facing_down",
            setPos = {bp_family_history=100, bp_prerequisite=100},
            responses = {
                {"Of what?", {}},
                {"No I don't...", {bp_no_history=100}},
                {"How do you know that?", {bp_howknow=100}},
            }
        },

        {
            pos = {bp_ofwhat=100},
            pose = {"left_of_couch", "facing_right"},
            text = ".%.%.%Of senile dementia.%% Of...% forgetting everything.",
            responses = {
                {"No I don't...", {bp_denial=100}},
                {"How do you know that?", {bp_howknow=100}},
                {"Oh.", {}}
            }
        },

        {
            pos = {bp_howknow=100},
            text = "Because...% You told me about this?%% It's your deepest fear...?"
        },
        {
            pos = {bp_no_history=100},
            text = "What about your mom?%% And your grandma,% and great-aunt?%%\n.%.%.%Have you forgotten them too?"
        },

        {
            pos = {bp_denial=100},
            setPos = {bp_denial=200},
            text = "When this happened to your mom% she insisted% it wasn't happening,% " ..
                "that your grandma was a fluke.%% \"Strong genes.\""
        },
        {
            pos = {bp_denial=200},
            text = "You told me not to let you just deny it if it ever happened...%% happened% to you.%% " ..
                "So.%% Please,% don't deny it."
        },

        {
            pos = {phase=7, bp_anything=0, bp_guessed_husband=0},
            text = "Can you remember anything about me? Anything at all?",
            setPos = {bp_anything=100,bp_prerequisite=100},
            responses = {
                {"You do seem familiar...", {}},
                {"No, sorry...", {}},
                {"I guess you're my husband?", {bp_guess_husband=10}}
            }
        },
        {
            pos = {phase=7, bp_anything=0, bp_prerequisite=100, bp_guessed_husband=0},
            text = "Surely you must remember SOMETHING about me...",
            pose = "left_of_couch",
            setPos = {bp_anything=100},
            responses = {
                {"You do seem familiar...", {}},
                {"No, sorry...", {}},
                {"I guess you're my husband?", {bp_guess_husband=10}}
            }
        },

        {
            pos = {bp_guess_husband=10, bp_prerequisite=100, told_was_husband=0},
            text = "Do you actually know that, or are you really just guessing?%% Be honest.",
            pose = {"next_to_rose", "facing_down"},
            responses = {
                {"I'm just guessing.", {bp_just_guessing=100}},
                {"I do remember...", {}, "gave_up"},
                {"What do you want me to say?", {bp_guess_husband=30}}
            }
        },
        {
            pos = {bp_guess_husband=40},
            pose = "right_of_rose",
            text = "I don't know...% That this is all just a weird joke?% That you took too far?% " ..
                "That the person I love is%.%.%. still here with me?"
        },
        {
            pos = {bp_guess_husband=50},
            pose = "facing_left",
            setPos = {bp_guessed_husband=200},
            text = "Yeah, that's still true.%% But I mean, do you know anything else?"
        },
        {
            pos = {bp_guess_husband=10, told_was_husband=500},
            text = "Welll%.%.%. yeah,% but I mean% I literally just told you that.",
        },

        {
            pos = {phase=8,bp_just_guessing=0},
            text = "Our wedding day was the happiest I'd ever seen you...",
            pose = "bottom_of_stairs",
            responses = {
                {"When was that, exactly?", {bp_when_married=1000}},
                {"How happy was I?", {bp_howhappy=100}},
                {"I don't remember it at all.", {}}
            }
        },
        {
            pos = {phase=8,bp_just_guessing=100},
            text = "Yeah...%% That's what I thought...",
            pose = "bottom_of_stairs",
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
                os.date('%B', os.time() - 27182818) .. "...%% 17 years ago."
        },
        {
            pos = {bp_when_married=1000, bp_already_said_when=500},
            setPos = {bp_when_married=0},
            text = "17 years ago, in " .. os.date('%Y', os.time() - 27182818) .. ".%% I just told you that...%%" ..
                "Did you forget already?"
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
            responses = {
                {"I don't know our backstory.", {}},
                {"I didn't choose to forget you.", {bp_havenochoice=100}},
                {"This game didn't give me the option.", {anger_notagame=500}, "anger"},
            }
        },
        {
            pos = {bp_havenochoice=200},
            pose = "facing_right",
            text = "Oh%.%.%. Right,% of course."
        },

        {
            pos = {phase=5, bp_prerequisite=0},
            text = "Wait...%% Do you not...% know who I am?",
            setPos = {bp_prerequisite=100},
            pose = {"right_of_rose", "facing_left"},
            responses = {
                {"You do seem familiar...", {}},
                {"No, sorry...", {}},
                {"I guess you're my husband?", {bp_guess_husband=10}}
            }
        },

        {
            pos = {phase=9, bp_prerequisite=100},
            text = "We've worked so hard on everything...%% Building this home together...%% I was hoping it " ..
                " wouldn't turn out this way.",
            pose = "left_of_couch",
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
                "Don't you know me better than--%% ...Oh.%% Right.%%",
        },

        {
            pos = {bp_left_hanging=100},
            text = "Yeah, I dunno what to say either.",
        },

        {
            pos = {bp_so_scared=100},
            text = "Yeah%.%.%. Me too."
        },

        {
            pos = {phase=10, fun=20, bp_explains_so_much=0, bp_prerequisite=100},
            text = "Ha ha ha, okay, this.%.%.% this explains so much...",
            pose = "bottom_of_stairs",
            setPos = {bp_explains_so_much=100,bp_prerequisite=100},
            responses = {
                {"What's so funny?", {}},
                {"Please don't laugh...", {}},
                {"Explains what?", {}},
                {nil, {}, "silence"}
            }
        },
        {
            pos = {phase=10, fun=50, bp_explains_so_much=0, bp_prerequisite=100},
            text = "Ha ha ha, oh god.%.%.% this explains so much...",
            pose = "bottom_of_stairs",
            setPos = {bp_explains_so_much=100,bp_prerequisite=100},
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
            pose = "right_of_rose",
            setPos = {bp_prerequisite=100},
            responses = {
                {"I have no idea who you are.", {}},
                {"Why are there pictures of us together?", {}},
                {"I'm feeling faint...", {}},
            }
        },

        {
            pos = {phase=12, bp_i_wonder=0},
            text = "I wonder how long this has been going on... Is this why you've been so forgetful lately?",
            pose = "next_to_rose",
            setPos = {bp_i_wonder=100},
            responses = {
                {"What have I forgotten?", {}},
                {"I'm so confused.", {}},
                {"What's going on?", {}}
            }
        },
        {
            pos = {phase=12, bp_i_wonder=0},
            text = "I wonder how long this has been going on... Let's go to the doctor.",
            setPos = {bp_i_wonder=100},
            responses = {
                {"What have I forgotten?", {}},
                {"I'm so confused.", {}},
                {"What's going on?", {}}
            }
        },

        {
            pos = {phase=13, bp_sullen=0},
            text = "Let's go to a doctor, okay?",
            pose = "next_to_rose",
            maxCount = 20,
            responses = {
                {"A doctor? Why?", {}},
                {"I don't want to...", {bp_sullen=10}},
                {"You're trying to trick me.", {}},
                {nil, {bp_sullen=10}}
            }
        },
        {
            pos = {phase=13},
            text = "Come on, let's see the doctor.",
            pose = "next_to_rose",
            maxCount = 20,
            responses = {
                {"A doctor? Why?", {}},
                {"I don't want to...", {bp_sullen=10}},
                {"You're trying to trick me.", {}},
                {nil, {bp_sullen=10}}
            }
        },
        {
            pos = {phase=13, bp_sullen=10},
            text = "Please don't be like this...%% Let's go to the doctor,% okay hon?",
            pose = "below_doors",
            maxCount = 20,
            responses = {
                {"A doctor? Why?", {}},
                {"I don't want to...", {}},
                {"You're trying to trick me.", {}},
                {nil, {bp_sullen=10}}
            }
        },
    },

    -- path where Greg is feeling alienated
    alienated = {
        { pos={}, text="DIALOG PATH INCOMPLETE: alienated"},

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

        {
            pos = {phase=10},
            text = "Ha ha, wow, this is just... what the hell is going on here.",
            responses = {
                {"I don't know.", {}},
                {"Who the hell are you?", {}, "gave_up"},
                {"Who are you?", {}, "brain_problems"}
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
            text = "Could you PLEASE let me finish?"
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
            pos = {phase=12},
            text = "I'm sorry, but I just can't do this anymore.",
            setState = "gave_up",
            responses = {
                {"Can't do what?", {}},
                {"Please don't leave me.", {}},
                {"I'm sorry.", {}},
            }
        }
    },

    -- path where Greg gets really angry at Rose
    anger = {
        { pos={}, text="DIALOG PATH INCOMPLETE: anger"},

        {
            pos = {anger_notagame=500},
            text = "What...?%% Is this...%% some sort of GAME to you?",
            responses = {
                {"That's not what I meant.", {anger_whatdidyoumean=100}},
                {"No, of course not.", {}},
                {"Yeah, I downloaded it.", {}, "stroke"}
            }
        },
        {
            pos = {anger_whatdidyoumean=100},
            text = "Then what DID you mean by that?",
            responses = {
                {"I don't know what's going on.", {}, "brain_problems"},
                {"I'm not sure.", {}},
                {"Ignore me.", {}, "wtf"}
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

        {
            pos = {phase=11},
            text = "I don't know who the hell you think you are but...%% " ..
                "this is all just too much for me to deal with.",
            pose={"below_doors","facing_down"}
        },

        {
            pos = {phase=12},
            text = "I worry about you a lot.%% But I have to worry about myself,% too%.%.%.",
            setState = "gave_up",
            setPos = {leaving=1000},
            pose={"below_doors","pause","facing_up"}
        },
    },

    -- path where Greg has given up on helping Rose due to brain problems
    gave_up = {
        { pos={}, text="DIALOG PATH INCOMPLETE: gave_up"},

        {
            pos = {phase=10},
            text = "Ha ha.%.%.% everything we've been through...%% it's just meaningless now, isn't it?",
            pose = "left_of_couch",
            cantInterrupt=true
        },

        {
            pos = {phase=10.5},
            pose = "right_of_rose",
            text = "What does it matter? You won't even remember this anyway.",
            cantInterrupt=true
        },

        {
            pos = {phase=11},
            pose = "below_doors",
            text = "% .%.%.% %%You don't even...% remember...%% me.",
            cantInterrupt=true
        },

        {
            pos = {phase=12},
            text = "I just can't do this anymore.",
            pose = {"below_doors", "facing_up"},
            setPos = {leaving=1000},
            cantInterrupt=true,
            maxCount=100,
        },

        {
            pos = {leaving=1000},
            text = "I hope you get the help you need.",
            pose = {"below_doors","leaving","pause","gone"},
            setPos = {gone=1000}
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
            pos = {},
            pose = "next_to_rose_worried",
            text = "Emergency services? It's my spouse, something's very wrong with them.",
            setPos = {stroke_state=1000}
        },

        {
            pos = {phase=-1, stroke_state=1000},
            text = "Someone is coming.... everything will be okay.",
            maxCount=5
        },
        {
            pos = {phase=-1, stroke_state=1000},
            text = "Shh, shh, it's okay...%% Everything will be fine...%#%#%#",
            maxCount=5
        },
        {
            pos = {phase=-1, stroke_state=1000},
            text = "They'll be here soon.",
            maxCount=5
        },
        {
            pos = {phase=-1, stroke_state=1000},
            text = "I love you.%#%\n\nWe'll get through this.",
            maxCount=5
        },
        {
            pos = {phase=-1, stroke_state=1000},
            text = "It's okay, I'm here for you.",
            maxCount=5
        },
    },

    -- vacation time!
    vacation = {
        { pos = {}, text = "DIALOG PATH INCOMPLETE: VACATION", maxCount=2000 }
    }

 }

return dialog
