local Devices = {}

Devices['pic18f'] = letk.Class( Object )

Devices['pic18f'].template_file       = 'pic18f.c'
Devices['pic18f'].RANDOM_PSEUDOFIX    = 1
Devices['pic18f'].RANDOM_PSEUDOAD     = 2
Devices['pic18f'].RANDOM_AD           = 3
Devices['pic18f'].CHOICE_RANDOM       = 1
Devices['pic18f'].CHOICE_GLOBAL       = 2
Devices['pic18f'].CHOICE_GLOBALRANDOM = 3
Devices['pic18f'].CHOICE_LOCAL        = 4
Devices['pic18f'].CHOICE_LOCALRANDOM  = 5
Devices['pic18f'].INPUT_TIMER         = 1
Devices['pic18f'].INPUT_MULTIPLEXED   = 2
--~ Devices['pic18f'].INPUT_EXTERNAL      = 3
Devices['pic18f'].PICC                = 1
Devices['pic18f'].SDCC                = 2

Devices['pic18f4620'] = letk.Class( Devices['pic18f'] )
Devices['pic18f4620'].clock   = 20000000
Devices['pic18f4620'].name    = 'PIC18F4620'
Devices['pic18f4620'].include = '18F4620.h'
Devices['pic18f4620'].fuses   = 'NOMCLR,EC_IO,H4,NOWDT,NOPROTECT,NOLVP,NODEBUG'
Devices['pic18f4620'][1]      = {
    var     = 'random_fn',
    caption = "Random Type",
    type    = 'choice',
    { Devices['pic18f'].RANDOM_PSEUDOFIX , "Pseudo Random Seed Fixed"    },
    { Devices['pic18f'].RANDOM_PSEUDOAD  , "Pseudo Random Seed AD input" },
    { Devices['pic18f'].RANDOM_AD        , "AD input"                    },
}
Devices['pic18f4620'][2]      = {
    var     = 'choice_fn',
    caption = "Choice",
    type    = 'choice',
    { Devices['pic18f'].CHOICE_RANDOM       , "Random"                       },
    --{ Devices['pic18f'].CHOICE_GLOBAL       , "Sequential Global Event List" },
    --{ Devices['pic18f'].CHOICE_GLOBALRANDOM , "Random Global Event List"     },
    --{ Devices['pic18f'].CHOICE_LOCAL        , "Sequential Local Event List"  },
    --{ Devices['pic18f'].CHOICE_LOCALRANDOM  , "Random Local Event List"      },
}
Devices['pic18f4620'][3]      = {
    var     = 'input_fn',
    caption = "Input (Delay Sensibility)",
    type    = 'choice',
    { Devices['pic18f'].INPUT_TIMER       , "Timer Interruption"                },
    { Devices['pic18f'].INPUT_MULTIPLEXED , "Multiplexed External Interruption" },
    --{ CodeGen.INPUT_EXTERNAL    , "External Interruption"             },
}
Devices['pic18f4620'][4]      = {
    var     = 'compiler',
    caption = "Compiler",
    type    = 'choice',
    { Devices['pic18f'].PICC , "PIC C"                },
    { Devices['pic18f'].SDCC , "SDCC"                 },
}
Devices['pic18f4620'][5]      = {
    var     = 'ad_port',
    caption = "AD port",
    type    = 'choice',
    { 'AN0', "AN0" },{ 'AN1', "AN1" },{ 'AN2', "AN2" },{ 'AN3', "AN3" },
    { 'AN4', "AN4" },{ 'AN5', "AN5" },{ 'AN6', "AN6" },{ 'AN7', "AN7" },
    { 'AN8', "AN8" },{ 'AN9', "AN9" },{ 'AN9', "AN9" },{ 'AN10', "AN10" },
    { 'AN11', "AN11" },{ 'AN12', "AN12" },
}
Devices['pic18f4620'][6]      = {
    var     = 'use_lcd',
    caption = "Include LCD Lib",
    type    = 'choice',
    { true  , "Yes" }, { false , "No"  },
}
Devices['pic18f4620'][7] = {
    var     = 'external_edge',
    caption = "External Interruption Edge",
    type    = 'choice',
    { 'H_TO_L'  , "High to Low" }, { 'L_TO_H'  , "Low to High" },
}
Devices['pic18f4620'][8] = {
    var     = 'timer_interval',
    caption = "Timer Interruption Interval",
    type    = 'spin',
    min     = 20,
    max     = 65535,
}

return Devices
