--We need check if all the same name events in differens automatons are equals (eg: all are controlable or all are not controlabled)

CodeGen    = {}
CodeGen_MT = { __index = CodeGen }

require'class.code_gen.template_c'

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

function CodeGen.new( options )
    self = {}
    setmetatable( self, CodeGen_MT )

    options = table.complete( options, {
        automatons = letk.List.new(),
        random_fn  = CodeGen.RANDOM_PSEUDOFIX,
        choice_fn  = CodeGen.CHOICE_RANDOM,
        input_fn   = CodeGen.INPUT_TIMER,
        file_name  = 'code',
    })

    local num_automatons = options.automatons:len()
    if num_automatons == 0 then return end
    if num_automatons == 1 then
        options.type = CodeGen.SUPTYPE_MONOLITIC
    else
        options.type = CodeGen.SUPTYPE_MODULAR
    end

    self.options = options

    return self
end

function CodeGen:execute()
    local context = {
        automatons  = self.options.automatons,
        events_map  = {},
        events      = {},
        sup_events  = {},
        random_fn   = self.options.random_fn,
        choice_fn   = self.options.choice_fn,
        input_fn    = self.options.input_fn,
        interruption   = 'INT_EXT',
        timer_interval = 65416,
    }

    for k_automaton, automaton in context.automatons:ipairs() do
        for k_event, event in automaton.events:ipairs() do
            if not context.events_map[ event.name ] then
                context.events[ #context.events + 1 ] = event
                context.events_map[ event.name ]      = #context.events
            end
        end
    end

    for k_automaton, automaton in context.automatons:ipairs() do
        context.sup_events[#context.sup_events + 1] = {}
        for k_event, event in automaton.events:ipairs() do
            context.sup_events[#context.sup_events][ context.events_map[ event.name ] ] = true
        end
    end

    local code = Template.get( 'main', context )

    local file = io.open( self.options.file_name .. '.c', "w")
    file:write( code )
    file:close()

    return self
end
