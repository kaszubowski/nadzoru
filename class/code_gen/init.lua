--We need check if all the same name events in differens automatons are equals (eg: all are controlable or all are not controlabled)

CodeGen    = {}
CodeGen_MT = { __index = CodeGen }

--~ require'class.code_gen.template_c'

CodeGen.RANDOM_PSEUDOFIX    = 1
CodeGen.RANDOM_PSEUDOAD     = 2
CodeGen.RANDOM_AD           = 3
CodeGen.CHOICE_RANDOM       = 1
CodeGen.CHOICE_GLOBAL       = 2
CodeGen.CHOICE_GLOBALRANDOM = 3
CodeGen.CHOICE_LOCAL        = 4
CodeGen.CHOICE_LOCALRANDOM  = 5
CodeGen.INPUT_TIMER         = 1
CodeGen.INPUT_MULTIPLEXED   = 2
--CodeGen.INPUT_EXTERNAL      = 3
CodeGen.SUPTYPE_MONOLITIC   = 1
CodeGen.SUPTYPE_MODULAR     = 2
CodeGen.PICC                = 1
CodeGen.SDCC                = 2

CodeGen.devices = require 'res.codegen.devices.main'

function CodeGen.new( self )
    assert(self.automatons,'ERRO automat(on/a) expeted')
    assert(self.device,    'ERRO device expeted')

    table.complete( self, {
        random_fn  = CodeGen.RANDOM_PSEUDOFIX,
        choice_fn  = CodeGen.CHOICE_RANDOM,
        input_fn   = CodeGen.INPUT_TIMER,
        compiler   = CodeGen.PICC,
        file_name  = 'code',
        ad_port    = 'AN0',
        use_lcd    = true,
    })

    setmetatable( self, CodeGen_MT )

    local num_automatons = self.automatons:len()
    if num_automatons == 0 then return end
    if num_automatons == 1 then
        self.type = CodeGen.SUPTYPE_MONOLITIC
    else
        self.type = CodeGen.SUPTYPE_MODULAR
    end

    return self
end

function CodeGen:execute()
        self.events_map     = {}
        self.events         = {}
        self.sup_events     = {}
        self.interruption   = 'INT_EXT'
        self.timer_interval = 65416

    for k_automaton, automaton in self.automatons:ipairs() do
        for k_event, event in automaton.events:ipairs() do
            if not self.events_map[ event.name ] then
                self.events[ #self.events + 1 ] = event
                self.events_map[ event.name ]   = #self.events
            end
        end
    end

    for k_automaton, automaton in self.automatons:ipairs() do
        self.sup_events[#self.sup_events + 1] = {}
        for k_event, event in automaton.events:ipairs() do
            self.sup_events[#self.sup_events][ self.events_map[ event.name ] ] = true
        end
    end

    local Context = letk.Context.new()
    Context:push( self )
    local Template = letk.Template.new( './res/codegen/' .. CodeGen.devices[ self.device ].file )
    local code = Template( Context )

    local file = io.open( self.file_name .. '.c', "w")
    file:write( code )
    file:close()

    return self
end
