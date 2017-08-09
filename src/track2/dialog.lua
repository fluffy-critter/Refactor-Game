--[[
Refactor: 2 - Strangers

(c)2017 fluffy @ beesbuzz.biz. Please see the LICENSE file for license information.

]]

dialog = {
    -- In my house
    1 = {
        "default" = {
            text = "Good morning, dear!",
            responses = {
                "Uh... hi?",
                "Who are you?",
                "Who the hell are you"
            }
        },
    },

    -- What's this person that I do not think I know doing in my house
    2 = {
        "cold shoulder" = {
            text = "Hon? You okay?",
            responses = {
                "No, I... I'm not sure.",
                "I'm fine...",
                "How did you get in here?"
            }
        }
    },


    -- In my house
    3 = {},

    -- He must have snuck in through the bedroom door
    4 = {},

    -- He says he is my husband
    5 = {
        "default" = {
            text = "It's... it's me, your husband?"
        },
        "cold shoulder" = {
            text = "Is everything really this bad? We've been married too long for this."
        }
    },

    -- He knows everything about me
    6 = {},

    -- Not my spouse
    7 = {},

    -- I think I would remember having brought him into my house
    8 = {},

    -- It's my house
    9 = {},

    -- Why is this person laughing right at me
    10 = {
        "cold shoulder" = {
            text = "Ha ha, okay, what did I do to make you so angry at me?"
        },
        "frustrated" = {
            text = "Ha ha ha, jeeze, I just... I don't think I can do this anymore."
        }
    },

    -- So many pictures of us together
    11 = {},

    -- He says he's beginning to worry about me
    12 = {},

    -- In my house
    15 = {},

    -- What's this person that I do not know doing in my house
    16 = {},


}

return dialog