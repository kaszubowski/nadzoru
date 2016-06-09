Devices = {}

Devices['base'] = letk.Class( Object )

--~ local function init_options( self, t )
    --~ for i = #t.__parents, 1, -1 do
        --~ local parent = t.__parents[i]
        --~ --init_options( self, parent ) --just copy parent
        --~ if parent.options then
            --~ for i, option in ipairs( parent.options ) do
                --~ self:set_option( option.var, option )
            --~ end
        --~ end
    --~ end
--~ end

Devices['base'].init_options = function ( self )
    self.options = {}
    for i = #self.__parents, 1, -1 do
        local parent = self.__parents[i]
        if parent.options then
            for i, option in ipairs( parent.options ) do
                self:set_option( option.var, option )
            end
        end
    end

    return self
end

Devices['base'].set_option = function( self, name, option )
    assert( rawget( self, 'options' ), "Device must have its own options table --> make sure that you called init_options()" )
    if not self.options[ name ] then
        self.options[ #self.options + 1 ]    = option
        self.options[ name ]                 = #self.options
    else
        self.options[ self.options[ name ] ] = option
    end
    option.var = name

    return self
end

Devices['base']:init_options()
Devices['base']:set_option('pathname', {
    caption = "Path",
    type    = 'file',
    method  = gtk.FILE_CHOOSER_ACTION_SELECT_FOLDER,
    title   = "Output path",
})

--*********************************++*********************************--
--**                             PIC18F                             **--
--********************************************************************--
Devices['pic18f'] = letk.Class( Devices['base'] ):init_options()

Devices['pic18f'].template_file       = 'pic18f.c'
Devices['pic18f'].file_extension      = 'c' --???
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
Devices['pic18f'].INPUT_RS232         = 3
Devices['pic18f'].OUTPUT_NORMAL       = 1 --User define functions
Devices['pic18f'].OUTPUT_RS232        = 2 --RS232 handler
Devices['pic18f'].OUTPUT_NORMAL_RS232 = 3 --User define functions and RS232
Devices['pic18f'].CCS                 = 1
Devices['pic18f'].SDCC                = 2

--~ Devices['pic18f'].sdcc_1H    = '0x06' -- HL + PLL
Devices['pic18f'].sdcc_1H    = '0x02'
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

Devices['pic18f'].models = { --???
    ['Supervisor'] = true,   --???
}                            --???

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
    { Devices['pic18f'].INPUT_RS232       , "RS232 with Interrupt" },
})
Devices['pic18f']:set_option('output_fn', {
    caption = "Output",
    type    = 'choice',
    { Devices['pic18f'].OUTPUT_NORMAL , "Normal (User Handler)" },
    { Devices['pic18f'].OUTPUT_RS232  , "RS232" },
    { Devices['pic18f'].OUTPUT_NORMAL_RS232  , "Normal and RS232" },
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
--Devices['pic18f4620'] = letk.Class( Devices['pic18f'] ):init_options()
--Devices['pic18f4620'].clock        = 20000000
--Devices['pic18f4620'].display      = true
--Devices['pic18f4620'].name         = 'PIC18F4620'
--Devices['pic18f4620'].include_ccs  = '18F4620.h'
--Devices['pic18f4620'].include_sdcc = {'pic18f4620.h'}
--Devices['pic18f4620'].fuses        = 'NOMCLR,EC_IO,H4,NOWDT,NOPROTECT,NOLVP,NODEBUG'

-- PIC18F4550
--Devices['pic18f4550'] = letk.Class( Devices['pic18f'] ):init_options()
--Devices['pic18f4550'].clock        = 20000000
--Devices['pic18f4550'].display      = true
--Devices['pic18f4550'].name         = 'PIC18F4550'
--Devices['pic18f4550'].include_ccs  = '18F4550.h'
--Devices['pic18f4550'].include_sdcc = {'pic18f4550.h'}
--Devices['pic18f4550'].fuses        = 'NOMCLR,EC_IO,H4,NOWDT,NOPROTECT,NOLVP,NODEBUG'

--*********************************++*********************************--
--**                         Kilobot Atmega                         **--
--********************************************************************--
Devices['kilobotAtmega328'] = letk.Class( Devices['base'] ):init_options()

Devices['kilobotAtmega328'].template_file        = 'kilobotAtmega328.c'
Devices['kilobotAtmega328'].RANDOM_PSEUDOFIX     = 1
Devices['kilobotAtmega328'].RANDOM_PSEUDOVOLTAGE = 2
Devices['kilobotAtmega328'].CHOICE_RANDOM        = 1
Devices['kilobotAtmega328'].INPUT_CYCLE          = 1
Devices['kilobotAtmega328'].INPUT_TIMER          = 2
Devices['kilobotAtmega328'].AMR                  = 1

Devices['kilobotAtmega328'].display      = true
Devices['kilobotAtmega328'].name         = "Kilobot (Atmega328)"
Devices['kilobotAtmega328'].custom_code  = {'code_global','code_init','code_message','code_clear','code_update'}

Devices['kilobotAtmega328']:set_option('random_fn', {
    caption = "Random Type",
    type    = 'choice',
    { Devices['kilobotAtmega328'].RANDOM_PSEUDOFIX      , "Seed Fixed"    },
    { Devices['kilobotAtmega328'].RANDOM_PSEUDOVOLTAGE  , "Seed Voltage" },
})
Devices['kilobotAtmega328']:set_option('extra_numNeighbor', {
    caption = "FW: Count Neighbors",
    type    = 'checkbox',
})
Devices['kilobotAtmega328']:set_option('extra_rgb', {
    caption = "FW: RGB",
    type    = 'checkbox',
})

--*********************************++*********************************--
--**                           GenericMic                           **--
--********************************************************************--
Devices['GenericMic'] = letk.Class( Devices['base'] ):init_options()

Devices['GenericMic'].template_file = { 'generic_mic.h', 'generic_mic.c'}

Devices['GenericMic'].display      = true
Devices['GenericMic'].name         = "Generic Mic."

--*********************************++*********************************--
--**                       GenericMicShared                         **--
--********************************************************************--
Devices['GenericMic'] = letk.Class( Devices['base'] ):init_options()

Devices['GenericMic'].template_file = { 'generic_mic_shared.h', 'generic_mic_shared.c'}

Devices['GenericMic'].display      = true
Devices['GenericMic'].name         = "Generic Mic. Shared"

--*********************************++*********************************--
--**                           atmega328p                          **--
--********************************************************************--
Devices['atmega328p'] = letk.Class( Devices['base'] ):init_options()

Devices['atmega328p'].template_file = { 'generic_mic.h', 'atmega328p.c'}

--~ Devices['atmega328p'].display      = true
Devices['atmega328p'].display      = false
Devices['atmega328p'].name         = "AtMega 328p"


--*********************************++*********************************--
--**                     GenericMic Distributed                     **--
--********************************************************************--
local function divElementsInGroups( e, g, range )
    local plusOne    = e%g
    local baseAmount = math.floor(e/g)
    local s          = {}

    for i=1,plusOne do
        s[i] = baseAmount+1
    end
    for i=plusOne+1,g do
        s[i]=baseAmount
    end

    if range then
        r = {}
        m = {}
        local start = 1
        for i = 1, g do
            r[i] = {
                first    = start,
                last     = start+s[i]-1,
                elements = s[i],
            }
            for j = r[i].first, r[i].last do
                m[j] = i
            end
            start = start + s[i]
        end
        return r, m
    else
        return s
    end
end

--~ Devices['GenericMicDistributed'].generate     = function( self, Context, tmpl, options ) --Files?
local function distGenerate ( self, Context, tmpl, options ) --Files?
    local types        = options[ 'types' ]
    local len_automata = self.automata:len()

    local automataSets = {}
    for t = 1, types do
        automataSets[t] = {}
    end
    --divide the automata into types automata sets.
    local ranges, mapAutomataType = divElementsInGroups( len_automata, types, true )
    for k_automaton, automaton in self.automata:ipairs() do
        table.insert( automataSets[ mapAutomataType[k_automaton] ], automaton )
    end
    Context:push{
        automata_sets = automataSets,
        types         = types,
    }
    for t = 1, types do
        local mySupervisorsCheck = {} --A set that specify which supervisors I have
        for i=1,len_automata do
            if i >= ranges[t].first and i <= ranges[t].last then
                mySupervisorsCheck[i] = 1
            else
                mySupervisorsCheck[i] = 0
            end
        end
        Context:push{
            my_type           = t,
            my_automata_check = mySupervisorsCheck,
            my_automata_set   = automataSets[t],
            my_first_automata = ranges[t].first,
            header_file       = t .. '_' .. (self.device.basicHeadfileName or 'generic_mic_distributed.h'),
        }
        local templateFileName = './res/codegen/templates/' .. tmpl
        local Template = letk.Template.new( templateFileName )
        local code     = Template( Context )
        local file = io.open( options.pathname .. '/'  .. t .. '_' .. tmpl, "w")
        file:write( code )
        file:close()
        Context:pop()
    end
    Context:pop()
end

Devices['GenericMicDistributed'] = letk.Class( Devices['base'] ):init_options()

Devices['GenericMicDistributed'].template_file = { 'generic_mic_distributed.h', 'generic_mic_distributed.c'}

--~ Devices['GenericMicDistributed'].display      = true
Devices['GenericMicDistributed'].display      = false
Devices['GenericMicDistributed'].name         = "Generic Mic. Distributed (OLD)"

Devices['GenericMicDistributed']:set_option('types', {
    caption   = "Types",
    type      = 'spin',
    min_value = 1,
    max_value = function( codeGen ) return codeGen.automata:len() end,
})

Devices['GenericMicDistributed'].basicHeadfileName = 'generic_mic_distributed.h'
Devices['GenericMicDistributed'].generate          = distGenerate

--------------------------------------------------------------------------------

Devices['GenericMicDistributed2'] = letk.Class( Devices['base'] ):init_options()

Devices['GenericMicDistributed2'].template_file = { 'generic_mic_distributed2.h', 'generic_mic_distributed2.c'}

--~ Devices['GenericMicDistributed2'].display      = true
Devices['GenericMicDistributed2'].display      = false
Devices['GenericMicDistributed2'].name         = "Generic Mic. Distributed (transparent)"

Devices['GenericMicDistributed2']:set_option('types', {
    caption   = "Types",
    type      = 'spin',
    min_value = 1,
    max_value = function( codeGen ) return codeGen.automata:len() end,
})

Devices['GenericMicDistributed2'].basicHeadfileName = 'generic_mic_distributed2.h'
Devices['GenericMicDistributed2'].generate         = distGenerate

--------------------------------------------------------------------------------

--require 'res.codegen.devices.schneider'
--require 'res.codegen.devices.schneider_distinguisher'

return Devices
