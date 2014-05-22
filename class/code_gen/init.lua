--We need check if all the same name events in differens automata are equals (eg: all are controlable or all are not controlabled)

Devices = require 'res.codegen.devices.main'

CodeGen = letk.Class( function( self, options )
    options             = options or {}
    self.automata       = options.automata
    self.device_id      = options.device_id
    self.path_name      = options.path_name
    self.event_map      = options.event_map
    self.event_map_file = options.event_map_file
    self.device         = Devices[ self.device_id ].new()
    self.custom_code    = {}

    local num_automata = self.automata:len()
    if num_automata == 0 then return end
    if num_automata == 1 then
        self.supervisor_type = CodeGen.SUPTYPE_MONOLITIC
    else
        self.supervisor_type = CodeGen.SUPTYPE_MODULAR
    end
end, Object )

CodeGen.SUPTYPE_MONOLITIC   = 1
CodeGen.SUPTYPE_MODULAR     = 2

function CodeGen:execute( gui )
    self:read_automata( )
    self:build_gui( gui )
end

------------------------------------------------------------------------
--                         Read Automata                              --
------------------------------------------------------------------------
function CodeGen:read_automata()
    self.event_code      = {}
    self.events_map      = {}
    self.events          = {}
    self.sup_events      = {}

    for k_automaton, automaton in self.automata:ipairs() do
        for k_event, event in automaton.events:ipairs() do
            if not self.events_map[ event.name ] then
                self.events[ #self.events + 1 ] = event
                self.events_map[ event.name ]   = #self.events
                self.event_code[ event.name ]   = {
                    id           = #self.events,
                    input        = '',
                    output       = '',
                    automaton    = {},
                    controllable = event.controllable,
                    source       = "Automaton",
                }
            end
            self.event_code[ event.name ].automaton[ k_automaton ] = event.controllable and 'c' or 'n'
        end
    end

    for k_automaton, automaton in self.automata:ipairs() do
        self.sup_events[#self.sup_events + 1] = {}
        for k_event, event in automaton.events:ipairs() do
            self.sup_events[#self.sup_events][ self.events_map[ event.name ] ] = true
        end
    end
end

------------------------------------------------------------------------
--                               GUI                                  --
------------------------------------------------------------------------
local function eval_option( opt, self )
    if type( opt ) == 'function' then
        return opt( self )
    else
        return opt
    end
end

function CodeGen:build_gui( gui )
    self.gui              = {}
    self.gui.vbox         = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.gui.hbox         = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
        self.gui.hbox_footer  = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.gui.btn_load     = gtk.Button.new_with_label("Load Project")
            self.gui.btn_save     = gtk.Button.new_with_label("Save Project")
            self.gui.btn_execute  = gtk.Button.new_with_label("Generate")

    self.gui.vbox:pack_start( self.gui.hbox, true, true, 0 )
    self.gui.vbox:pack_start( self.gui.hbox_footer, false, false, 0 )
    self.gui.hbox_footer:pack_start( self.gui.btn_load, true, true, 0 )
    self.gui.hbox_footer:pack_start( self.gui.btn_save, true, true, 0 )
    self.gui.hbox_footer:pack_start( self.gui.btn_execute, true, true, 0 )

    -------------------------------------------------
    --                  TOP                        --
    -------------------------------------------------

    --**** Device Options ****--
    self.gui.selector, self.gui.selector_vbox = Selector.new({
        success_fn       = self.generate,
        success_fn_param = self,
    }, true)
    
    --DEBUG start
    for k_dev, dev in pairs( Devices ) do
        print( k_dev, dev )
        if Devices[ self.device_id ].options then
            print("    Options:",dev.options)
            for num_opt, opt in ipairs( dev.options ) do
                print("    ", num_opt, opt.var, opt.caption, opt.type)
            end
        end
    end
    --DEBUG end

    if Devices[ self.device_id ].options then
        for _, opt in ipairs( Devices[ self.device_id ].options ) do
            if opt.type == 'choice' then
                self.gui.selector:add_combobox{
                    list     = letk.List.new_from_table( opt ),
                    text_fn  = function( a )
                        return a[2]
                    end,
                    text = opt.caption,
                }
            elseif opt.type == 'checkbox' then
                self.gui.selector:add_checkbox{
                    text = opt.caption,
                }
            elseif opt.type == 'spin' then
                self.gui.selector:add_spin{
                    text = opt.caption,
                    min_value = eval_option( opt.min_value, self ),
                    max_value = eval_option( opt.max_value, self ),
                    step      = eval_option( opt.step, self ),
                    digits    = eval_option( opt.digits, self ),
                }
            elseif opt.type == 'file' then
                self.gui.selector:add_file{
                    text   = opt.caption,
                    title  = opt.title,
                    method = opt.method,
                }
            end
        end
    end
    self.gui.hbox:pack_start( self.gui.selector_vbox, false, false, 0 )

    --**** right notebook ****--
    self.gui.note  = gtk.Notebook.new()
    self.gui.hbox:pack_start( self.gui.note, true, true, 5 )

    --** Source View - Input **--
    self.gui.code_input_hbox    = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
        self.gui.code_input_vbox    = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)

    self.gui.code_input_treeview = Treeview.new()
        :add_column_text("Events",100)
        :bind_onclick(CodeGen.change_event_input, self)

    self.gui.code_input_label = gtk.Label.new_with_mnemonic( '---' )

    self.gui.code_input_view     = gtk.SourceView.new()
    self.gui.code_input_buffer   = self.gui.code_input_view:get('buffer')
    self.gui.code_input_manager  = gtk.source_language_manager_get_default()
    self.gui.code_input_lang     = self.gui.code_input_manager:get_language('c')
    self.gui.code_input_scroll   = gtk.ScrolledWindow.new()
    self.gui.code_input_view:set('show-line-numbers', true, 'highlight-current-line', true, 'auto-indent', true)
    self.gui.code_input_scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.gui.code_input_scroll:add(self.gui.code_input_view)
    self.gui.code_input_buffer:set('language', self.gui.code_input_lang)

    self.gui.note:insert_page( self.gui.code_input_hbox, gtk.Label.new("Input"), -1)
    self.gui.code_input_hbox:pack_start( self.gui.code_input_treeview:build{width = 150}, false, false, 0 )
    self.gui.code_input_hbox:pack_start( self.gui.code_input_vbox, true, true, 0 )
        self.gui.code_input_vbox:pack_start( self.gui.code_input_label, false, false, 0 )
        self.gui.code_input_vbox:pack_start( self.gui.code_input_scroll, true, true, 0 )

    self.gui.code_input_buffer:connect('changed', CodeGen.change_code_input, self )

    --** Source View - Output **--
    self.gui.code_output_hbox    = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
        self.gui.code_output_vbox    = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)

    self.gui.code_output_treeview = Treeview.new()
        :add_column_text("Events",100)
        :bind_onclick(CodeGen.change_event_output, self)

    self.gui.code_output_label = gtk.Label.new_with_mnemonic( '---' )

    self.gui.code_output_view     = gtk.SourceView.new()
    self.gui.code_output_buffer   = self.gui.code_output_view:get('buffer')
    self.gui.code_output_manager  = gtk.source_language_manager_get_default()
    self.gui.code_output_lang     = self.gui.code_output_manager:get_language('c')
    self.gui.code_output_scroll   = gtk.ScrolledWindow.new()
    self.gui.code_output_view:set('show-line-numbers', true, 'highlight-current-line', true, 'auto-indent', true)
    self.gui.code_output_scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.gui.code_output_scroll:add(self.gui.code_output_view)
    self.gui.code_output_buffer:set('language', self.gui.code_output_lang)

    self.gui.note:insert_page( self.gui.code_output_hbox, gtk.Label.new("Output"), -1)
    self.gui.code_output_hbox:pack_start( self.gui.code_output_treeview:build{width = 150}, false, false, 0 )
    self.gui.code_output_hbox:pack_start( self.gui.code_output_vbox, true, true, 0 )
        self.gui.code_output_vbox:pack_start( self.gui.code_output_label, false, false, 0 )
        self.gui.code_output_vbox:pack_start( self.gui.code_output_scroll, true, true, 0 )

    self.gui.code_output_buffer:connect('changed', CodeGen.change_code_output, self )
    
        --** Source View - Custom **--
    self.gui.code_custom_hbox    = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
        self.gui.code_custom_vbox    = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)

    self.gui.code_custom_treeview = Treeview.new()
        :add_column_text("Place",100)
        :bind_onclick(CodeGen.change_place_custom, self)

    self.gui.code_custom_label = gtk.Label.new_with_mnemonic( '---' )

    self.gui.code_custom_view     = gtk.SourceView.new()
    self.gui.code_custom_buffer   = self.gui.code_custom_view:get('buffer')
    self.gui.code_custom_manager  = gtk.source_language_manager_get_default()
    self.gui.code_custom_lang     = self.gui.code_custom_manager:get_language('c') --TODO language is a param from Device
    self.gui.code_custom_scroll   = gtk.ScrolledWindow.new()
    self.gui.code_custom_view:set('show-line-numbers', true, 'highlight-current-line', true, 'auto-indent', true)
    self.gui.code_custom_scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.gui.code_custom_scroll:add(self.gui.code_custom_view)
    self.gui.code_custom_buffer:set('language', self.gui.code_custom_lang)

    self.gui.note:insert_page( self.gui.code_custom_hbox, gtk.Label.new("Custom code"), -1)
    self.gui.code_custom_hbox:pack_start( self.gui.code_custom_treeview:build{width = 150}, false, false, 0 )
    self.gui.code_custom_hbox:pack_start( self.gui.code_custom_vbox, true, true, 0 )
        self.gui.code_custom_vbox:pack_start( self.gui.code_custom_label, false, false, 0 )
        self.gui.code_custom_vbox:pack_start( self.gui.code_custom_scroll, true, true, 0 )

    self.gui.code_custom_buffer:connect('changed', CodeGen.change_code_custom, self )

    -- Source View - All --

    self:update_treeviews()

    --** Footer Buttons Connect **--

    self.gui.btn_execute:connect('clicked', self.gui.selector.success, self.gui.selector )
    self.gui.btn_save:connect('clicked', self.save_project, self )
    self.gui.btn_load:connect('clicked', self.load_project, self )

    gui:add_tab( self.gui.vbox, 'Code Gen: ' .. self.device.name )
end

function CodeGen:update_treeviews()
    local in_ev  = {}
    local out_ev = {}
    for ev_nm, prop in pairs( self.event_code ) do
        if not prop.controllable then
            in_ev[#in_ev +1] = ev_nm
        end
        out_ev[#out_ev +1] = ev_nm
    end
    table.sort( in_ev )
    table.sort( out_ev )

    self.gui.code_input_treeview:clear_all()
    self.gui.code_output_treeview:clear_all()
    self.gui.code_custom_treeview:clear_all()

    for k_ev, ev_nm in ipairs( in_ev ) do
        self.gui.code_input_treeview:add_row{ ev_nm }
    end
    for k_ev, ev_nm in ipairs( out_ev ) do
        self.gui.code_output_treeview:add_row{ ev_nm }
    end
    for k_cc, cc in ipairs( self.device.custom_code or {} ) do
        self.gui.code_custom_treeview:add_row{ cc }
    end

    self.gui.code_input_treeview:update()
    self.gui.code_output_treeview:update()
    self.gui.code_custom_treeview:update()

    self.gui.code_input_label:set_text( '---' )
    self.gui.code_output_label:set_text( '---' )
    self.gui.code_custom_label:set_text( '---' )
end

function CodeGen:change_event_input()
    self.selected_event_input = self.gui.code_input_treeview:get_selected(1)
    if self.selected_event_input then
        self.gui.code_input_label:set_text( self.selected_event_input )
        self.gui.code_input_buffer:set( 'text',  self.event_code[ self.selected_event_input ].input )
    end
end

function CodeGen:change_event_output()
    self.selected_event_output = self.gui.code_output_treeview:get_selected(1)
    if self.selected_event_output then
        self.gui.code_output_label:set_text( self.selected_event_output )
        self.gui.code_output_buffer:set( 'text',  self.event_code[ self.selected_event_output ].output )
    end
end

function CodeGen:change_place_custom()
    self.selected_custom_code = self.gui.code_custom_treeview:get_selected(1)
    if self.selected_custom_code then
        self.gui.code_custom_label:set_text( self.selected_custom_code )
        self.gui.code_custom_buffer:set( 'text',  self.custom_code[ self.selected_custom_code  ] or '' )
    end
end

function CodeGen:change_code_input()
    if not self.selected_event_input and not self.event_code[ self.selected_event_input ] then return end
    self.event_code[ self.selected_event_input ].input = self.gui.code_input_buffer:get( 'text' )
end

function CodeGen:change_code_output()
    if not self.selected_event_output and not self.event_code[ self.selected_event_output ] then return end
    self.event_code[ self.selected_event_output ].output = self.gui.code_output_buffer:get( 'text' )
end

function CodeGen:change_code_custom()
    if not self.selected_custom_code then return end
    self.custom_code[ self.selected_custom_code ] = self.gui.code_custom_buffer:get( 'text' )
end

function CodeGen:save_project()
     local dialog = gtk.FileChooserDialog.new(
        "Save AS", nil,gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.ncp")
    filter:set_name("Nadzoru Code Project")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        if not names[1]:match( '%.ncp$' ) then
            names[1] = names[1] .. '.ncp'
        end
        local file = io.open( names[1], 'w')
        if file then
            local data       = {}
            data.events      = {}
            data.custom_code = {}
            for nm_ev, prop in pairs( self.event_code ) do
                data.events [ nm_ev ] = {
                    input        = prop.input,
                    output       = prop.output,
                    controllable = prop.controllable
                }
            end
            for nm_cc, cc in pairs( self.custom_code ) do
                data.custom_code[ nm_cc ] = cc
            end
            file:write( letk.serialize( data ) )
            file:close()
        end
    end
end

function CodeGen:load_project()
     local dialog = gtk.FileChooserDialog.new(
        "Save AS", nil,gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.ncp")
    filter:set_name("Nadzoru Code Project")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        local file = io.open( names[1], 'r')
        if file then
            local s    = file:read('*a')
            local data = loadstring('return ' .. s)()
            for nm_ev, prop in pairs( data.events ) do
                if not self.event_code[ nm_ev ] then
                    self.event_code[ nm_ev ] = {
                        source = "Project",
                    }
                end
                self.event_code[ nm_ev ].input        = prop.input
                self.event_code[ nm_ev ].output       = prop.output
                self.event_code[ nm_ev ].controllable = self.event_code[ nm_ev ].controllable or prop.controllable
            end
            for nm_cc, cc in pairs( data.custom_code ) do
                self.custom_code[ nm_cc ] = cc
            end
            self:update_treeviews()
        end
    end
end

------------------------------------------------------------------------
--                             GENERATE                               --
------------------------------------------------------------------------

function CodeGen:generate_event_map()
    if not self.event_map or not self.event_map_file then return end
    local ev_map = {}
    for name, id in pairs( self.events_map ) do
        ev_map[ name ] = id
        ev_map[ id   ] = name
    end
    local file = io.open( self.event_map_file, "w")
    file:write( letk.serialize( ev_map )  )
    file:close()
end

function CodeGen.generate( results, numresults, selector, self )
    -- Context --
    local options = {}
    if Devices[ self.device_id ].options then
        for i, opt in ipairs( Devices[ self.device_id ].options ) do
            if opt.type == 'choice' then
                --~ self[ opt.var ] = results[ i ][ 1 ]
                options[ opt.var ] = results[ i ][ 1 ]
            --~ elseif opt.type == 'checkbox' then
            else
                --~ self[ opt.var ] = results[ i ]
                options[ opt.var ] = results[ i ]
            end
        end
    end
    local Context = letk.Context.new()
    Context:push( options )
    Context:push( self )
    Context:push( self.device )
    if self.custom_code then
        Context:push( self.custom_code )
    end
    
    -- Template --
    if self.device.template_file then
        local tmpls = type( self.device.template_file ) == 'table' and self.device.template_file or { self.device.template_file }
        for _, tmpl in ipairs( tmpls ) do
            local Template = letk.Template.new( './res/codegen/templates/' .. tmpl )
            local code = Template( Context )

            local file = io.open( options.pathname .. '/'  .. tmpl, "w")
            file:write( code )
            file:close()
        end
    end
    
    self:generate_event_map()
end
