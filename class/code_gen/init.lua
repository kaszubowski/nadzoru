--[[
    This file is part of nadzoru.

    nadzoru is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    nadzoru is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with nadzoru.  If not, see <http://www.gnu.org/licenses/>.

    Copyright (C) 2011 Yuri Kaszubowski Lopes, Eduardo Harbs, Andre Bittencourt Leal and Roberto Silvio Ubertino Rosso Jr.
--]]

--We need check if all the same name events in differens automata are equals (eg: all are controlable or all are not controlabled)

Devices = require 'res.codegen.devices.main'

--[[
module "CodeGen"
--]]
CodeGen = letk.Class( function( self, options )
    Object.__super( self )
    
    options             = options or {}
    --self.workspace_events = options.workspace_events
    self.automata       = options.automata
    self.device_id      = options.device_id
    self.path_name      = options.path_name
    self.event_map      = options.event_map
    self.event_map_file = options.event_map_file
    self.device         = Devices[ self.device_id ].new()
    self.custom_code    = {}

    --self.automata:iremove(function(automaton) --???
    --  return not Devices[ self.device_id ].models[ automaton.type ]
    --end)
    
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

---Executes the code generation.
--Reads the automata and build the gui.
--@param self CodeGen in which the operation is applied.
--@param gui Gui in which the operation is applied.
--@see CodeGen:read_automata
--@see CodeGen:build_gui
function CodeGen:execute( gui )
    self:read_automata( )
    self:build_gui( gui )
end

------------------------------------------------------------------------
--                         Read Automata                              --
------------------------------------------------------------------------

---Reads the event map file.
--Verifies if the file was chosen. Sets the ids from the map to the codegen.
--@param self Codegen in which the operation is applied.
--function CodeGen:read_event_map()
--  if not self.event_map or not self.event_map_file then return end
--  local file = io.open(self.event_map_file, 'r')
--  if file then
--      local s    = file:read('*a')
--      local data = loadstring('return ' .. s)() --This returns the event map as a table
--      if data then
--          local event_info = data.information
--          
--          --events
--          for k, e in pairs(data.events) do
--              if type(e)=='string' then
--                  local event = event_info[k]
--                  self.events[ k ] = {
--                      name = e,
--                      controllable = event.controllable,
--                  }
--                  self.events_map[ e ]   = k
--                  self.event_code[ e ]   = {
--                      id           = k,
--                      input        = event.input,
--                      output       = event.output,
--                      automaton    = {},
--                      source       = event.source,
--                      controllable = event.controllable,
--                      refinement   = event.refinement,
--                  }
--              end
--          end
--          
--          --refinements
--          for k, e in pairs(data.refinements) do
--              if type(e)=='string' then
--                  local event = event_info[k]
--                  self.events_r[ k ] = {
--                      name = e,
--                      controllable = event.controllable,
--                  }
--                  self.events_r_map[ e ] = k
--                  self.event_code[ e ]   = {
--                      id           = k,
--                      input        = event.input,
--                      output       = event.output,
--                      automaton    = {},
--                      source       = event.source,
--                      controllable = event.controllable,
--                      refinement   = event.refinement,
--                  }
--              end
--          end
--      end
--  end
--end

---Reads the automata.
--Reads the event map. For each automaton, sets the event ids from the events that are not mapped yet to the codegen.
--@param self CodeGen in which the operation is applied.
--@see Codegen:read_event_map
function CodeGen:read_automata()
    self.event_code      = {}
    self.events_map      = {}
    --self.events_r_map    = {}
    self.events          = {}
    self.sup_events      = {}

    --[[
    self.events_r        = {}
    self.atm_events      = {}
    self.atm_events_r    = {}
    self.refinements     = {}
    
    self:read_event_map()
    
    for k_event, event in self.workspace_events:ipairs() do
        if event.refinement~='' then
            self.refinements[event.refinement] = self.refinements[event.refinement] or {}
            self.refinements[event.refinement][event.name] = true
        end
    end
   --]]

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

    
--[[ --???
    for k_event, event in self.workspace_events:ipairs() do
        --Event is not a refinement => add to events list
        if event.refinement=='' then
            if not self.events_map[ event.name ] then
                local pos = #self.events + 1
                self.events[ pos ] = event
                self.events_map[ event.name ]   = pos
                self.event_code[ event.name ]   = {
                    id           = pos,
                    input        = '',
                    output       = '',
                    automaton    = {},
                    source       = "Automaton",
                    controllable = event.controllable,
                    refinement   = event.refinement,
                }
            end
        end
        
        --Event doesn't have refinements => add to events_r list
        if not self.refinements[event.name] then
            if not self.events_r_map[ event.name ] then
                local pos = #self.events_r + 1
                self.events_r[ pos ] = event
                self.events_r_map[ event.name ]   = pos
                self.event_code[ event.name ]   = {
                    id           = pos,
                    input        = '',
                    output       = '',
                    automaton    = {},
                    source       = "Automaton",
                    controllable = event.controllable,
                    refinement   = event.refinement,
                }
            end
        end
    end
--]]

    --[[
    for k_automaton, automaton in self.automata:ipairs() do
        self.atm_events[#self.atm_events + 1] = {}
        self.atm_events_r[#self.atm_events_r + 1] = {}
        
        for k_event, event in automaton.events:ipairs() do
            self.event_code[ event.name ].automaton[ k_automaton ] = event.controllable and 'c' or 'n' --Maybe this can be deleted. It's not used anywhere.
            
            --Event is not a refinement => add to atm_events list
            if event.refinement=='' then
                self.atm_events[#self.atm_events][ self.events_map[ event.name ] ] = true
            end
            
            --Event doesn't have refinements => add to atm_events_r list
            if not self.refinements[event.name] then
                self.atm_events_r[#self.atm_events_r][ self.events_r_map[ event.name ] ] = true
            end
        end
    end
    --]]
    
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

---Builds the CodeGen gui.
--TODO
--@param self Codegen in which the operation is applied.
--@param gui TODO
--@see Selector:add_combobox
--@see Treeview:add_column_text
--@see Treeview:bind_onclick
--@see CodeGen:update_treeviews
--@see Gui:add_tab
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

---TODO
--TODO
--@param self TODO
--@see Treeview:clear_all
--@see Treeview:add_row
--@see Treeview:update
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

---TODO
--TODO
--@param self TODO
--@see Treeview:get_selected
function CodeGen:change_event_input()
    self.selected_event_input = self.gui.code_input_treeview:get_selected(1)
    if self.selected_event_input then
        self.gui.code_input_label:set_text( self.selected_event_input )
        self.gui.code_input_buffer:set( 'text',  self.event_code[ self.selected_event_input ].input )
    end
end

---TODO
--TODO
--@param self TODO
--@see Treeview:get_selected
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

---TODO
--TODO
--@param self TODO
--@see Treeview:set_selected
function CodeGen:change_code_input()
    if not self.selected_event_input and not self.event_code[ self.selected_event_input ] then return end
    self.event_code[ self.selected_event_input ].input = self.gui.code_input_buffer:get( 'text' )
end

---TODO
--TODO
--@param self TODO
function CodeGen:change_code_output()
    if not self.selected_event_output and not self.event_code[ self.selected_event_output ] then return end
    self.event_code[ self.selected_event_output ].output = self.gui.code_output_buffer:get( 'text' )
end

function CodeGen:change_code_custom()
    if not self.selected_custom_code then return end
    self.custom_code[ self.selected_custom_code ] = self.gui.code_custom_buffer:get( 'text' )
end

---Opens the window to save the code project to a file.
--TODO
--@param self Codegen to be saved.
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

---Opens the window to load the code project from a file.
--TODO
--@param self Codegen in which the file will be loaded.
--@see CodeGen:update_treeviews
function CodeGen:load_project()
     local dialog = gtk.FileChooserDialog.new(
        "Load Project", nil,gtk.FILE_CHOOSER_ACTION_SAVE,
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

---Generates the event map.
--Verifies if the file was chosen. Maps the events from the CodeGen to the map.
--@param self CodeGen in which the operation is applied.
function CodeGen:generate_event_map()
    if not self.event_map or not self.event_map_file then return end
    local ev_map = {}
    --local ev_map = {
    --  events = {},
    --  refinements = {},
    --  information = {},
    --}
    
    --local event_info = ev_map.information
    
    --events
    for name, id in pairs( self.events_map ) do
        local code = self.event_code[ name ]
        --ev_map.events[ name ] = id
        --ev_map.events[ id   ] = name
        ev_map[ name ] = id
        ev_map[ id   ] = name
        
        --event_info[ id ] = {
        --  input        = code.input,
        --  output       = code.output,
        --  source       = code.source,
        --  controllable = code.controllable,
        --  refinement   = code.refinement,
        --}
    end
    
    --refinements
    --local event_info = ev_map.information
    --for name, id in pairs( self.events_r_map ) do
    --    local code = self.event_code[ name ]
    --    ev_map.refinements[ name ] = id
    --    ev_map.refinements[ id   ] = name
    --    
    --    event_info[ id ] = {
    --      input        = code.input,
    --      output       = code.output,
    --      source       = code.source,
    --      controllable = code.controllable,
    --      refinement   = code.refinement,
    --    }
    --end
    
    local file = io.open( self.event_map_file, "w")
    file:write( letk.serialize( ev_map )  )
    file:close()
end

--[[
local function clean_code(code)
    local n
    code = string.gsub(code, '%s+', ' ')
    repeat
        code, n = string.gsub(code, '\n%s\n', '\n')
    until n==0
    code = string.gsub(code, '\t +', '\t')
    code = string.gsub(code, '^\n+', '')
    code = string.gsub(code, '\n\n+$', '\n')
    return code
end
--]]

---Generates the code.
--TODO
--@param results TODO
--@param numresults TODO
--@param selector TODO
--@param self TODO
--@see CodeGen:generate_event_map
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
