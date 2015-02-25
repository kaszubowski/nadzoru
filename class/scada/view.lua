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

--[[
module "ScadaView"
--]]
ScadaView = letk.Class( function( self, gui, scada_plant, elements )
    Object.__super( self )
    self.gui         = gui
    self.scada_plant = scada_plant
    self.elements    = elements
    
    self.server_config    = nil
    self.redis_connection = nil
    self.run              = nil

    self:build_gui()
    
    self.scale = 13
end, Object )

ScadaView.scale_values = ScadaEditor.scale_values

---TODO
--TODO
--@param self TODO
--@see ScadaView:build_server_config_window
--@see Gui:add_tab
function ScadaView:build_gui()
     self.vbox                           = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.toolbar                     = gtk.Toolbar.new()
        self.scrolled                    = gtk.ScrolledWindow.new()
            self.drawing_area            = gtk.DrawingArea.new( )
            
    self.vbox:pack_start( self.toolbar, false, false, 0 )
    self.vbox:pack_start( self.scrolled, true, true, 0 )
        self.scrolled:add(self.drawing_area)
            
    self.drawing_area:add_events( gdk.BUTTON_PRESS_MASK )
    self.drawing_area:connect("button_press_event", self.drawing_area_press, self )
    self.drawing_area:connect('draw', self.drawing_area_expose, self )
    
    
    self:build_server_config_window()
    
    --config_connection
    self.img_act_cfgcon = gtk.Image.new_from_file( './images/icons/computer_edit.png' )
    self.btn_act_cfgcon = gtk.ToolButton.new( self.img_act_cfgcon, "Config Connection" )
    self.btn_act_cfgcon:connect( 'clicked', self.set_act_cfgcon, self )
    self.toolbar:insert( self.btn_act_cfgcon, -1 )
    
    --connect/disconnect
    self.img_act_connect = gtk.Image.new_from_file( './images/icons/disconnect.png' )
    self.btn_act_connect    = gtk.ToolButton.new( self.img_act_connect, "Config Connection" )
    self.btn_act_connect:connect( 'clicked', self.set_act_connect, self )
    self.toolbar:insert( self.btn_act_connect, -1 )

    self.gui:add_tab( self.vbox, "view " .. (self.scada_plant:get('file_name') or "-x-") )
end

---TODO
--TODO
--@param self TODO
function ScadaView:build_server_config_window()
    self.SCWgui = {}
    self.SCWgui.win                               = gtk.Window.new( gtk.WINDOW_TOPLEVEL )
        self.SCWgui.vbox                          = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
            self.SCWgui.hbox_ip                   = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                self.SCWgui.label_ip              = gtk.Label.new_with_mnemonic( "IP:" )
                self.SCWgui.entry_ip              = gtk.Entry.new()
            self.SCWgui.hbox_port                 = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                self.SCWgui.label_port            = gtk.Label.new_with_mnemonic( "Port:" )
                self.SCWgui.entry_port            = gtk.Entry.new()
            self.SCWgui.hbox_database             = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                self.SCWgui.label_database        = gtk.Label.new_with_mnemonic( "Database Num:" )
                self.SCWgui.spin_database         = gtk.SpinButton.new_with_range(0, 128, 1)
            self.SCWgui.hbox_namespace            = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                self.SCWgui.label_namespace       = gtk.Label.new_with_mnemonic( "Namespace:" )
                self.SCWgui.entry_namespace       = gtk.Entry.new()
            self.SCWgui.hbox_btn                  = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                self.SCWgui.btn_test              = gtk.Button.new_with_label("Test")
                self.SCWgui.btn_cancel            = gtk.Button.new_with_label("Cancel")
                self.SCWgui.btn_ok                = gtk.Button.new_with_label("Ok")
                
    self.SCWgui.win:add( self.SCWgui.vbox )
        self.SCWgui.vbox:pack_start( self.SCWgui.hbox_ip, true, true, 0 )
            self.SCWgui.hbox_ip:pack_start( self.SCWgui.label_ip, true, true, 0 )
            self.SCWgui.hbox_ip:pack_start( self.SCWgui.entry_ip, true, true, 0 )
        self.SCWgui.vbox:pack_start( self.SCWgui.hbox_port, true, true, 0 )
            self.SCWgui.hbox_port:pack_start( self.SCWgui.label_port, true, true, 0 )
            self.SCWgui.hbox_port:pack_start( self.SCWgui.entry_port, true, true, 0 )
        self.SCWgui.vbox:pack_start( self.SCWgui.hbox_database, true, true, 0 )
            self.SCWgui.hbox_database:pack_start( self.SCWgui.label_database, true, true, 0 )
            self.SCWgui.hbox_database:pack_start( self.SCWgui.spin_database, true, true, 0 )
        self.SCWgui.vbox:pack_start( self.SCWgui.hbox_namespace, true, true, 0 )
            self.SCWgui.hbox_namespace:pack_start( self.SCWgui.label_namespace, true, true, 0 )
            self.SCWgui.hbox_namespace:pack_start( self.SCWgui.entry_namespace, true, true, 0 )
        self.SCWgui.vbox:pack_start( self.SCWgui.hbox_btn, false, false, 0 )
            self.SCWgui.hbox_btn:pack_start( self.SCWgui.btn_test, true, true, 0 )
            self.SCWgui.hbox_btn:pack_start( self.SCWgui.btn_cancel, true, true, 0 )
            self.SCWgui.hbox_btn:pack_start( self.SCWgui.btn_ok, true, true, 0 )
            
    self.SCWgui.win:set('title', "Connection", 'width-request', 200,
        'height-request', 300, 'window-position', gtk.WIN_POS_CENTER,
        'icon-name', 'gtk-about', 'deletable', false)
        
    self.SCWgui.entry_ip:set_text( 'localhost' )
    self.SCWgui.entry_port:set_text( '6379' )
    self.SCWgui.entry_namespace:set_text( 'NadzoruScada' )
        
        
    function redis_test()
        local params = {
            host = self.SCWgui.entry_ip:get_text(),
            port = self.SCWgui.entry_port:get_text(),
        } 
        local namespace                     = self.SCWgui.entry_namespace:get_text()
        local database                      = self.SCWgui.spin_database:get_value()
        local status_connection, connection = pcall( Redis.connect, params )
        if status_connection then
            local status_db = pcall( connection.select, connection, database )
            if status_db then
                local info = connection:info()
                local msg  = "Connection OK:\n"
                --~ for k,v in pairs( info ) do
                    --~ if type( v ) == 'string' then
                        --~ msg = msg .. '\n' .. k .. ' = ' .. v
                    --~ end
                --~ end
                gtk.InfoDialog.showInfo( msg )
            else
                gtk.InfoDialog.showInfo( "Invalid Database: " .. tostring( database ) )
            end
            connection:quit()
        else
            gtk.InfoDialog.showInfo( "Connection Error:\n\n" .. connection )
        end
    end
    self.SCWgui.btn_test:connect( 'clicked', redis_test )
    
    function redis_cancel()
        self.SCWgui.win:hide()
    end
    self.SCWgui.btn_cancel:connect( 'clicked', redis_cancel )
   
    function redis_ok()
        self.server_config = {
            params = {
                host = self.SCWgui.entry_ip:get_text(),
                port = self.SCWgui.entry_port:get_text(),
            },
            namespace          = self.SCWgui.entry_namespace:get_text(),
            database           = self.SCWgui.spin_database:get_value(),
        }
        redis_cancel()
    end
    self.SCWgui.btn_ok:connect( 'clicked', redis_ok )
        
    self.SCWgui.label_ip:set( 'width-request', 150 )
    self.SCWgui.entry_ip:set( 'width-request', 150 )
    self.SCWgui.label_port:set( 'width-request', 150 )
    self.SCWgui.entry_port:set( 'width-request', 150 )
    self.SCWgui.label_namespace:set( 'width-request', 150 )
    self.SCWgui.entry_namespace:set( 'width-request', 150 )
end

---TODO
--TODO
--@param self TODO
--@param cr TODO
--@see ScadaPlant:render
function ScadaView:drawing_area_expose( cr )
    cr = cairo.Context.wrap(cr)
    cr:scale( self.scale_values[ self.scale ], self.scale_values[ self.scale ] )
    local x, y = self.scada_plant:render( cr )
    self.drawing_area:set_size_request( (x+32)*self.scale_values[ self.scale ], (y+32)*self.scale_values[ self.scale ] )
end

---TODO
--TODO
--@param self TODO
--@param event TODO
--@see ScadaPlant:get_selected
--@see ScadaComponent.Base:click
function ScadaView:drawing_area_press( event )
    local stats, button_press = gdk.Event.get_button( event )

    if button_press == 1 then
        if self.last_drawing_area_lock then return end
        self.last_drawing_area_lock = true

        glib.timeout_add(glib.PRIORITY_DEFAULT, 100, function( self )
            self.last_drawing_area_lock = nil
        end, self )
        
        local _, x, y                      = gdk.Event.get_coords( event )
        local selected_component, position = self.scada_plant:get_selected( x, y )
        selected_component:click()
    end
end

---TODO
--TODO
--@param self TODO
--@return TODO
--@see ScadaPlant:load_automata_group
--@see AutomataGroup:load_automata
--@see AutomataGroup:check_automata
function ScadaView:check_plant( )
    if not self.scada_plant then return false, "No plant" end
    if not self.scada_plant.automata_group_name then return false, "Plant do not have automata group" end
    if not self.scada_plant.automata_group then
        self.scada_plant:load_automata_group( self.elements )
    end
    if not self.scada_plant.automata_group then return false, "Automata group can not be loaded" end
    self.scada_plant.automata_group:load_automata( self.elements )
    if not self.scada_plant.automata_group:check_automata() then return false, "All automata from automa group can not be loaded" end
    return true
end

---TODO
--TODO
--@param self TODO
--@return TODO
function ScadaView:redis_connect()
    if not self.server_config or not self.server_config.params then
        return false, "Connection not configured" 
    end
    local status, connection = pcall( Redis.connect, self.server_config.params )
    if status then
        self.redis_connection = connection
        local status_db = pcall( connection.select, connection, self.server_config.database )
        if status_db then
            return true
        else
            connection:quit()
            return false, "Invalid Database: " .. tostring( self.server_config.database )
        end
    else
        return false, connection
    end
end

---TODO
--TODO
--@param self TODO
function ScadaView:set_act_cfgcon()
    self.SCWgui.win:show_all()
end

---TODO
--TODO
--@param self TODO
--@see ScadaView:check_plant
--@see ScadaView:redis_connect
--@see ScadaView:run_init
function ScadaView:set_act_connect()
    if not self.run then
        local status_plant, err_plant = self:check_plant( )
        if status_plant then
            local status_connection, err_connection = self:redis_connect()
            if status_connection then
                self.img_act_connect:set_from_file('./images/icons/connect.png')
                self:run_init()
                glib.timeout_add(glib.PRIORITY_DEFAULT, 1000, self.run_callback, self) --config time?
                glib.timeout_add(glib.PRIORITY_DEFAULT, 300, self.tick_callback, self) --config time?
            else
                gtk.InfoDialog.showInfo( "Connection error:\n\n" .. err_connection )
            end
        else
            gtk.InfoDialog.showInfo( "Plant load fail:\n\n" .. err_plant )
        end
    else
        self.run = nil
        self.img_act_connect:set_from_file('./images/icons/disconnect.png')
    end
end

---TODO
--TODO
--@param self TODO
function ScadaView:run_init()
    local base_env = {
        print    = print,
        table    = table,
        string   = string,
        math     = math,
        tonumber = tonumber,
        tostring = tostring,
        select   = select,
        pairs    = pairs,
        ipairs   = ipairs,
        type     = type,
    }
    self.run = {
        components_env = {},
        simulators     = {},
    }
    local functions = { 'onupdate' }
    for k, component in self.scada_plant.component:ipairs() do
        local code = {}
        self.run.components_env[ k ] = {}
        setmetatable( self.run.components_env[ k ], { __index = base_env } )
        self.run.components_env[ k ].component = component
        
        for k_fn, fn_name in ipairs( functions ) do 
            local code_fn = component:get_property( fn_name )
            if type( code_fn ) == 'string' then
                local chunk = loadstring( code_fn )
                if chunk then
                    setfenv( chunk, self.run.components_env[ k ] )
                    chunk()
                end
            end
        end
        
        for automaton_name, automaton in pairs( self.scada_plant.automata_group.automata_object ) do
            self.run.simulators[ automaton_name ] = Simulator.new( automaton )
        end
    end
    
    self.run.event_position = 1
end

---TODO
--TODO
--@param self TODO
--@return TODO
--@see Simulator:event_exists
--@see Simulator:event_evolve
function ScadaView:run_callback()
    if not self.run then return false end
    local event_name = true 
    while event_name do
        event_name = self.redis_connection:lindex( self.server_config.namespace .. '_EVENTS_NAME_TO_APP', self.run.event_position * -1 )
        if event_name then
            for automaton_name, automaton in pairs( self.scada_plant.automata_group.automata_object ) do
                if self.run.simulators[ automaton_name ]:event_exists( event_name ) then
                    self.run.simulators[ automaton_name ]:event_evolve( event_name )
                end
            end
            
            for k, enviroment in ipairs( self.run.components_env ) do
                if enviroment.onupdate then
                    enviroment.onupdate( enviroment.component, event_name, self.run.simulators ) --TODO pcall
                end
            end
            self.run.event_position = self.run.event_position + 1
        end
    end

    self.drawing_area:queue_draw()
    return self.run and true or false
end

---TODO
--TODO
--@param self TODO
--@return TODO
--@see ScadaComponent.Base:tick
function ScadaView:tick_callback()
    if not self.run then return false end
    for k, enviroment in ipairs( self.run.components_env ) do
        enviroment.component:tick()
    end

    self.drawing_area:queue_draw()
    return self.run and true or false
end
