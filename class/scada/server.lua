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

require 'letk.linuxserial'

--[[
module "ScadaServer"
--]]
ScadaServer = letk.Class( function( self, gui, automata_group, event_map_file, elements )
    Object.__super( self )
    self.gui            = gui
    self.automata_group = automata_group
    self.elements       = elements
    self.event_map      = {}
    
    local file = io.open( event_map_file, 'r')
    if file then
        local s    = file:read('*a')
        local data = loadstring('return ' .. s)()
        for event_id, event_name in ipairs( data ) do
            self.event_map[ tonumber(event_id) ]  = event_name
            self.event_map[ event_name]           = tonumber(event_id)
        end
    end
    
    self.server_config    = nil
    self.redis_connection = nil
    self.device_file      = nil
    self.run              = nil

    self:build_gui()
    
    self.scale = 13
end, Object )

---TODO
--TODO
--@param self TODO
--@see ScadaServer:build_server_config_window
--@see Treeview:add_column_text
--@see Treeview:build
--@see Gui:add_tab
function ScadaServer:build_gui()
     self.vbox                           = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.toolbar                     = gtk.Toolbar.new()
        self.hbox                           = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            
    self.vbox:pack_start( self.toolbar, false, false, 0 )
    self.vbox:pack_start( self.hbox, true, true, 0 )
    
    self:build_server_config_window()
    
    --config_connection
    self.img_act_cfgcon = gtk.Image.new_from_file( './images/icons/computer_edit.png' )
    self.btn_act_cfgcon = gtk.ToolButton.new( self.img_act_cfgcon, "Config Connection" )
    self.btn_act_cfgcon:connect( 'clicked', self.set_act_cfgcon, self )
    self.toolbar:insert( self.btn_act_cfgcon, -1 )
    
    --connect/disconnect
    self.img_act_connect    = gtk.Image.new_from_file( './images/icons/disconnect.png' )
    self.btn_act_connect    = gtk.ToolButton.new( self.img_act_connect, "Connect" )
    self.btn_act_connect:connect( 'clicked', self.set_act_connect, self )
    self.toolbar:insert( self.btn_act_connect, -1 )
    
    --MES load
    self.img_act_mes    = gtk.Image.new_from_file( './images/icons/mes.png' )
    self.btn_act_mes    = gtk.ToolButton.new( self.img_act_mes, "Mes" )
    self.btn_act_mes:connect( 'clicked', self.set_act_mes, self )
    self.toolbar:insert( self.btn_act_mes, -1 )
    
    --MES:
    self.vbox_mes1 = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.cbx_info = gtk.ComboBoxText.new()
        self.btn_info = gtk.Button.new_with_mnemonic ("Execute")
    self.vbox_mes2 = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.mes_treeview      = Treeview.new()
            :add_column_text("Information",400)
            :add_column_text("Value",90)
        
    self.hbox:pack_start( self.vbox_mes1, false, false, 0 )
        self.vbox_mes1:pack_start( self.cbx_info, false, false, 0 )
        self.vbox_mes1:pack_start( self.btn_info, false, false, 0 )
    self.hbox:pack_start( self.vbox_mes2, true, true, 0 )
        self.vbox_mes2:pack_start( self.mes_treeview:build(), true, true, 0 )
        
    self.btn_info:connect( 'clicked', self.set_act_execute_event, self )
    
    --ADD tab
    self.gui:add_tab( self.vbox, "SERVER" )
end

---TODO
--TODO
--@param self TODO
function ScadaServer:build_server_config_window()
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
            self.SCWgui.hbox_device               = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                self.SCWgui.label_device          = gtk.Label.new_with_mnemonic( "Device:" )
                self.SCWgui.entry_device          = gtk.Entry.new()
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
        self.SCWgui.vbox:pack_start( self.SCWgui.hbox_device, true, true, 0 )
            self.SCWgui.hbox_device:pack_start( self.SCWgui.label_device, true, true, 0 )
            self.SCWgui.hbox_device:pack_start( self.SCWgui.entry_device, true, true, 0 )
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
    self.SCWgui.entry_device:set_text( '/dev/ttyUSB0' )
        
        
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
                --~ for k,v in pairs( info ) do
                    --~ if type( v ) == 'string' then
                        --~ msg = msg .. '\n' .. k .. ' = ' .. v
                    --~ end
                --~ end
                gtk.InfoDialog.showInfo( "Connection to redis OK" )
            else
                gtk.InfoDialog.showInfo( "Invalid Database: " .. tostring( database ) )
            end
            connection:quit()
        else
            gtk.InfoDialog.showInfo( "Connection Error:\n\n" .. connection )
        end
    end
    self.SCWgui.btn_test:connect( 'clicked', redis_test )
    
    function device_test()
        --~ local f, err = io.open( self.SCWgui.entry_device:get_text(), 'r+' )
        --~ if f then
            --~ gtk.InfoDialog.showInfo( "Connection to device OK" )
        --~ else
            --~ gtk.InfoDialog.showInfo( "Connection to device Error:\n\n" .. err )
        --~ end
    end
    
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
            device             = self.SCWgui.entry_device:get_text(),
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
--@return TODO
--@see AutomataGroup:load_automata
--@see AutomataGroup:check_automata
function ScadaServer:check_automata_group( )
    if not self.automata_group then return false, "Automata group can not be loaded" end
    self.automata_group:load_automata( self.elements )
    if not self.automata_group:check_automata() then return false, "All automata from automata group can not be loaded" end
    return true
end

---TODO
--TODO
--@param self TODO
--@return TODO
function ScadaServer:redis_connect()
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
function ScadaServer:set_act_cfgcon()
    self.SCWgui.win:show_all()
end

---TODO
--TODO
--@param self TODO
--@see ScadaServer:check_automata_group
--@see ScadaServer:redis_connect
--@see ScadaServer:run_init
function ScadaServer:set_act_connect()
    if not self.run then
        if not self.server_config then
            gtk.InfoDialog.showInfo( "Not Configured!" )
            return 
        end
        local status_plant, err_plant = self:check_automata_group( )
        if status_plant then
            local status_connection, err_connection = self:redis_connect()
            local device_err
            --~ self.device_file, device_err = io.open( self.server_config.device, 'a+')
            self.device_file = serial.open( self.server_config.device )
            if status_connection and self.device_file then
                self.img_act_connect:set_from_file('./images/icons/connect.png')
                self:run_init()
                glib.timeout_add(glib.PRIORITY_DEFAULT, 300, self.run_callback, self) --config time?
                self.redis_connection:del( self.server_config.namespace .. '_EVENTS_TO_SERIAL' ) 
                --~ self.redis_connection:del( self.server_config.namespace .. '_EVENTS_ID_FROM_SERIAL' ) 
                self.redis_connection:del( self.server_config.namespace .. '_EVENTS_NAME_TO_APP' ) 
            else
                gtk.InfoDialog.showInfo( "Connection error:\n\n" .. (err_connection or '') .. (device_err or '') )
            end
        else
            gtk.InfoDialog.showInfo( "Plant load fail:\n\n" .. err_plant )
        end
    else
        self.img_act_connect:set_from_file('./images/icons/disconnect.png')
        self.cbx_info:remove_all()
        self.run      = nil
        self.mes_data = {}
    end
end

---TODO
--TODO
--@param self TODO
--@see ScadaServer:execute_event
function ScadaServer:set_act_execute_event()
    local event_name =  self.cbx_info:get_active_text()
    self:execute_event( event_name, true )
end

---TODO
--TODO
--@param self TODO
--@param event_name TODO
--@param toSerial TODO
--@see Simulator:event_exists
--@see Simulator:event_evolve
--@see ScadaServer:update_mes_data
function ScadaServer:execute_event( event_name, toSerial )
    --Application
    self.redis_connection:lpush( self.server_config.namespace .. '_EVENTS_NAME_TO_APP', event_name ) 
    --Update Server AFD's
    for automaton_name, automaton in pairs( self.run.simulators ) do
        if automaton:event_exists( event_name ) then
            automaton:event_evolve( event_name )
        end
    end
    --Serial:
    if toSerial then
        local event_id = tonumber( self.event_map[event_name] ) 
        if event_id then
            self.device_file:writeByte( event_id )
        end
    end
    
    self:update_mes_data( event_name )
end

---TODO
--TODO
--@param self TODO
--@see Simulator:get_non_controllable_events
function ScadaServer:run_init()
    self.run = {
        simulators     = {},
        to_serial      = 1,
    }
        
    local x_events = {}
    for automaton_name, const in pairs( self.automata_group.automata_file.x ) do
        local automaton = self.automata_group.automata_object[ automaton_name ]
        self.run.simulators[ automaton_name ] = Simulator.new( automaton )
        for k_ev, ev in ipairs( self.run.simulators[ automaton_name ]:get_non_controllable_events() ) do
            x_events[ ev.name ] = true
        end
    end
    self.cbx_info:remove_all()
    for ev_name, _const in pairs( x_events ) do
        self.cbx_info:append_text( ev_name )
    end
    
    self.run.event_position = 1
end

---TODO
--TODO
--@param self TODO
--@see Simulator:get_controllable_events
--@see Simulator:get_current_state_controllable_events
--@see ScadaServer:execute_event
function ScadaServer:run_exclusive_automata()
    --Evolve controlable events from X (TODO) calc disable
    
    function disable_and_run_controllable()
        local eventsList = {}
        for automaton_name, automaton in pairs( self.run.simulators ) do
            for k_ev, ev in ipairs( automaton:get_controllable_events() ) do
                eventsList[ ev.name ] = true
            end
        end
        for automaton_name, automaton in pairs( self.run.simulators ) do
            local controllable_events_all       = {}
            for k_ev, ev in ipairs( automaton:get_controllable_events() ) do
                controllable_events_all[ ev.name ] = true
            end
            for k_ev, ev in ipairs( automaton:get_current_state_controllable_events() ) do
                controllable_events_all[ ev.name ] = nil
            end
            for ev_name, _disable in pairs( controllable_events_all ) do
                eventsList[ ev_name ] = nil
            end
        end
        local i_eventsList = {}
        for ev_name, _disable in pairs( eventsList ) do
            i_eventsList[#i_eventsList + 1] = ev_name
        end
        if #i_eventsList > 0 then
            local selected_event = i_eventsList[ math.random(1,#i_eventsList) ]
            return true, selected_event
        end
        return false
    end
    
    local status, event_name = disable_and_run_controllable()
    if not status then
        return
    end
    
    self:execute_event( event_name, true )
end

---TODO
--TODO
--@param self TODO
--@param event_name TODO
--@see Treeview:clear_data
--@see Treeview:add_row
--@see Treeview:update
function ScadaServer:update_mes_data( event_name )
    if self.mes_data then
        local current_time = os.time()
        self.mes_treeview:clear_data()
        for k_mes, mes_env in ipairs( self.mes_data ) do
            if mes_env.update then
                mes_env.event_name    = event_name
                mes_env.current_time  = current_time
                mes_env.automata      = self.run and self.run.simulators 
                mes_env.update()
                if mes_env.reference then
                    self.mes_data.references[ mes_env.reference ] = mes_env.value
                end
                self.mes_treeview:add_row{ mes_env.name, mes_env.value  }
            end
        end
        self.mes_treeview:update()
    end
end

---TODO
--TODO
--@param self TODO
--@return TODO
--@see ScadaServer:execute_event
--@see ScadaServer:run_exclusive_automata
function ScadaServer:run_callback()
    if not self.run then return false end
    
    local function getEvents()
        local receiveBuffer = {}
        local eventsList    = {}
        repeat
            local data = self.device_file:readByte()
            if data ~= nil then
                if data == 10 or data == 13 then --\n or \r
                    eventsList[ #eventsList + 1 ] = tonumber( table.concat( receiveBuffer ) )
                    receiveBuffer = {}
                else
                    receiveBuffer[#receiveBuffer + 1] = string.char( data )
                end
            end
        until not data
        
        return eventsList
    end
    
    --to_serial (redis -> serial)
    local event_name = true 
    while event_name do
        event_name = self.redis_connection:lindex( self.server_config.namespace .. '_EVENTS_TO_SERIAL', self.run.event_position * -1 )
        if event_name then
            self.run.event_position = self.run.event_position + 1
            self:execute_event( event_name, true )
        end
    end
    --from_serial (serial -> redis)
    local input        = getEvents()
    for k, v in ipairs(input) do
        local event_name = self.event_map[ v ]
        if event_name then
            self:execute_event( event_name, false )
        end
    end  
    
    self:run_exclusive_automata()
    
    return self.run and true or false
end

---TODO
--TODO
--@param self TODO
--@see Treeview:add_row
--@see Treeview:update
function ScadaServer:set_act_mes()
    self.mes_data = { references = {} }
    
     local dialog = gtk.FileChooserDialog.new(
        "Select the file", nil, gtk.FILE_CHOOSER_ACTION_OPEN,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.lua")
    filter:set_name("MES especification")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local filenames = dialog:get_filenames()
    if not (response == gtk.RESPONSE_OK or filenames) then
        print('Canceled')
        return
    end
    local file_mes, err1  = io.open(filenames[1], 'r')
    if not file_mes then
        print( "Error open file", err1 )
        return
    end
    local chunk, err2 = loadstring( 'return ' .. file_mes:read('*a') )
    if not chunk then
        print( "Error reading file", err2 )
    end
    local data = chunk()
    
    local env_base = {
        assert = assert, next     = next    , pcall    = pcall,
        string = string, math     = math    , table    = table,
        ipairs = ipairs, pairs    = pairs   , select   = select,
        print  = print , rawequal = rawequal, rawget   = rawget,
        rawset = rawset, tonumber = tonumber, tostring = tostring,
        type   = type  , unpack   = unpack  , 
    }
    
    function env_base.getReference( name )
        return self.mes_data.references[ name ]
    end
    
    local env_MT = {
        __index = function( t, k )
            return env_base[k]
        end,
    }
    
    
    for k_prop, prop in ipairs( data ) do
        self.mes_data[ k_prop ] = {
            value     = 0,
            name      = prop.name,
            reference = prop.reference,
        }
        
        setmetatable( self.mes_data[ k_prop ], env_MT )
        
        local f, err3 = loadstring( prop.script )
        if f then
            setfenv( f, self.mes_data[ k_prop ] )
            f()
            if self.mes_data[ k_prop ].init then
                self.mes_data[ k_prop ].current_time = os.time()
                self.mes_data[ k_prop ].init()
            end
            self.mes_treeview:add_row{ self.mes_data[ k_prop ].name, self.mes_data[ k_prop ].value  }
        else
            print('Invalid script IN:', prop.name, err3)
        end        
    end
    self.mes_treeview:update()
    
end
