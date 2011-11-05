--We need check if all the same name events in differens automata are equals (eg: all are controlable or all are not controlabled)

Devices = require 'res.codegen.devices.main'

CodeGen = letk.Class( function( self, automata, device_id, file_name )
    self.automata  = automata
    self.device_id = device_id
    self.file_name = file_name
    self.device    = Devices[ device_id ].new()

    local num_automata = self.automata:len()
    if num_automata == 0 then return end
    if num_automata == 1 then
        self.type = CodeGen.SUPTYPE_MONOLITIC
    else
        self.type = CodeGen.SUPTYPE_MODULAR
    end
end, Object )

CodeGen.SUPTYPE_MONOLITIC   = 1
CodeGen.SUPTYPE_MODULAR     = 2

function CodeGen:execute( gui )
    local function generate( results, numresults )
        for i, opt in ipairs( Devices[ self.device_id ] ) do
            if opt.type == 'choice' then
                self[ opt.var ] = results[ i ][ 1 ]
            end
        end
        self.events_map     = {}
        self.events         = {}
        self.sup_events     = {}

        for k_automaton, automaton in self.automata:ipairs() do
            for k_event, event in automaton.events:ipairs() do
                if not self.events_map[ event.name ] then
                    self.events[ #self.events + 1 ] = event
                    self.events_map[ event.name ]   = #self.events
                end
            end
        end

        for k_automaton, automaton in self.automata:ipairs() do
            self.sup_events[#self.sup_events + 1] = {}
            for k_event, event in automaton.events:ipairs() do
                self.sup_events[#self.sup_events][ self.events_map[ event.name ] ] = true
            end
        end

        local Context = letk.Context.new()
        Context:push( self )
        Context:push( self.device )
        local Template = letk.Template.new( './res/codegen/' .. self.device.template_file )
        local code = Template( Context )

        local file = io.open( self.file_name .. '.c', "w")
        file:write( code )
        file:close()
    end

    self.gui = {}
    self.gui.selector, self.gui.vbox = Selector.new({
        success_fn = generate,
    }, true)

    for _, opt in ipairs( Devices[ self.device_id ] ) do
        if opt.type == 'choice' then
            self.gui.selector:add_combobox{
                list = letk.List.new_from_table( opt ),
                text_fn  = function( a )
                    return a[2]
                end,
                text = opt.caption,
            }
        elseif opt.type == 'spin' then

        end
    end

    gui:add_tab( self.gui.vbox, 'Code Gen: ' .. self.device.name )
end
