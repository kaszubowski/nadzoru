local Devices = {}

Devices['base'] = letk.Class( Object )

local function init_options( self, t )
    --for _, parent in ipairs( t.__parents ) do
    for i = #t.__parents, 1, -1 do
        local parent = t.__parents[i]
        init_options( self, parent )
        if parent.options then
            for i, option in ipairs( parent.options ) do
                self:set_option( option.var, option )
            end
        end
    end
end

Devices['base'].init_options = function ( self )
    self.options = self.options or {}
    init_options( self, self )

    return self
end

Devices['base'].set_option = function( self, name, option )
    self.options                      = self.options or {}
    if not self.options[ name ] then
        self.options[ #self.options + 1 ]    = option
        self.options[ name ]                 = #self.options
    else
        self.options[ self.options[ name ] ] = option
    end
    option.var = name

    return self
end

--********************************************************************--
--**                             PIC18F                             **--
--********************************************************************--
Devices['pic18f'] = letk.Class( Devices['base'] )

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
Devices['pic18f'].CCS                 = 1
Devices['pic18f'].SDCC                = 2

Devices['pic18f'].sdcc_1H    = '0x06'
Devices['pic18f'].sdcc_2L    = '0x1e'
Devices['pic18f'].sdcc_2H    = '0x1e'
Devices['pic18f'].sdcc_3H    = '0x01'
Devices['pic18f'].sdcc_4L    = '0x81'
Devices['pic18f'].sdcc_5L    = '0x0f'
Devices['pic18f'].sdcc_5H    = '0xc0'
Devices['pic18f'].sdcc_6L    = '0x0f'
Devices['pic18f'].sdcc_6H    = '0xe0'
Devices['pic18f'].sdcc_7L    = '0x0f'
Devices['pic18f'].sdcc_7H    = '0x40'
Devices['pic18f'].char       = 'unsigned char'
Devices['pic18f'].int        = 'unsigned long int'
Devices['pic18f'].int_cast   = '(unsigned long int)'
Devices['pic18f'].ns         = '' --number suffix

Devices['pic18f']:set_option('random_fn', {
    caption = "Random Type",
    type    = 'choice',
    { Devices['pic18f'].RANDOM_PSEUDOFIX , "Pseudo Random Seed Fixed"    },
    { Devices['pic18f'].RANDOM_PSEUDOAD  , "Pseudo Random Seed AD input" },
    { Devices['pic18f'].RANDOM_AD        , "AD input"                    },
})
Devices['pic18f']:set_option('choice_fn', {
    caption = "Choice",
    type    = 'choice',
    { Devices['pic18f'].CHOICE_RANDOM       , "Random"                       },
    --{ Devices['pic18f'].CHOICE_GLOBAL       , "Sequential Global Event List" },
    --{ Devices['pic18f'].CHOICE_GLOBALRANDOM , "Random Global Event List"     },
    --{ Devices['pic18f'].CHOICE_LOCAL        , "Sequential Local Event List"  },
    --{ Devices['pic18f'].CHOICE_LOCALRANDOM  , "Random Local Event List"      },
})
Devices['pic18f']:set_option('input_fn', {
    caption = "Input (Delay Sensibility)",
    type    = 'choice',
    { Devices['pic18f'].INPUT_TIMER       , "Timer Interruption"                },
    { Devices['pic18f'].INPUT_MULTIPLEXED , "Multiplexed External Interruption" },
})
Devices['pic18f']:set_option('compiler', {
    caption = "Compiler",
    type    = 'choice',
    { Devices['pic18f'].SDCC , "SDCC"              },
    { Devices['pic18f'].CCS  , "CCS"               },
})
Devices['pic18f']:set_option('ad_port', {
    caption = "AD port",
    type    = 'choice',
    { '0', "AN0" },{ '1', "AN1" },{ '2', "AN2" },{ '3', "AN3" },
    { '4', "AN4" },{ '5', "AN5" },{ '6', "AN6" },{ '7', "AN7" },
    { '8', "AN8" },{ '9', "AN9" },{ '9', "AN9" },{ '10', "AN10" },
    { '11', "AN11" },{ '12', "AN12" },
})
Devices['pic18f']:set_option('use_lcd', {
    caption = "Include LCD Lib",
    type    = 'choice',
    { true  , "Yes" }, { false , "No"  },
})
Devices['pic18f']:set_option('external_edge', {
    caption = "External Interruption Edge",
    type    = 'choice',
    { 'H_TO_L'  , "High to Low" }, { 'L_TO_H'  , "Low to High" },
})
Devices['pic18f']:set_option('timer_interval', {
    caption = "Timer Interruption Interval",
    type    = 'spin',
    min     = 20,
    max     = 65535,
})

-- PIC18F4620
Devices['pic18f4620'] = letk.Class( Devices['pic18f'] ):init_options()
Devices['pic18f4620'].clock        = 20000000
Devices['pic18f4620'].display      = true
Devices['pic18f4620'].name         = 'PIC18F4620'
Devices['pic18f4620'].include_ccs  = '18F4620.h'
Devices['pic18f4620'].include_sdcc = {'delay.h','pic18f4620.h'}
Devices['pic18f4620'].fuses        = 'NOMCLR,EC_IO,H4,NOWDT,NOPROTECT,NOLVP,NODEBUG'

-- PIC18F4550
Devices['pic18f4550'] = letk.Class( Devices['pic18f'] ):init_options()
Devices['pic18f4550'].clock        = 20000000
Devices['pic18f4550'].display      = true
Devices['pic18f4550'].name         = 'PIC18F4550'
Devices['pic18f4550'].include_ccs  = '18F4550.h'
Devices['pic18f4550'].include_sdcc = {'delay.h','pic18f4550.h'}
Devices['pic18f4550'].fuses        = 'NOMCLR,EC_IO,H4,NOWDT,NOPROTECT,NOLVP,NODEBUG'

return Devices
