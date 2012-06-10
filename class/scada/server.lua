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

function ScadaServer:build_gui()
     self.vbox                           = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.toolbar                     = gtk.Toolbar.new()
            
    self.vbox:pack_start( self.toolbar, false, false, 0 )
    
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

    self.gui:add_tab( self.vbox, "SERVER" )
end

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
        local f, err = io.open( self.SCWgui.entry_device:get_text(), 'r+' )
        if f then
            gtk.InfoDialog.showInfo( "Connection to device OK" )
        else
            gtk.InfoDialog.showInfo( "Connection to device Error:\n\n" .. err )
        end
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

function ScadaServer:check_automata_group( )
    if not self.automata_group then return false, "Automata group can not be loaded" end
    self.automata_group:load_automata( self.elements )
    if not self.automata_group:check_automata() then return false, "All automata from automa group can not be loaded" end
    return true
end

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

function ScadaServer:set_act_cfgcon()
    self.SCWgui.win:show_all()
end

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
            self.device_file, device_err = io.open( self.server_config.device, 'a+')
            if status_connection and self.device_file then
                self.img_act_connect:set_from_file('./images/icons/connect.png')
                self:run_init()
                glib.timeout_add(glib.PRIORITY_DEFAULT, 1000, self.run_callback, self) --config time?
            else
                gtk.InfoDialog.showInfo( "Connection error:\n\n" .. (err_connection or '') .. (device_err or '') )
            end
        else
            gtk.InfoDialog.showInfo( "Plant load fail:\n\n" .. err_plant )
        end
    else
        self.img_act_connect:set_from_file('./images/icons/disconnect.png')
        self.run = nil
    end
end

function ScadaServer:run_init()
    self.run = {
        simulators     = {},
    }
        
    for automaton_name, const in pairs( self.automata_group.automata_file.x ) do
        local automaton = self.automata_group.automata_object[ automaton_name ]
        self.run.simulators[ automaton_name ] = Simulator.new( automaton )
    end
    
    self.run.event_position = 1
end

function ScadaServer:run_callback()
    if not self.run then return false end
    
    --input
    local input = self.device_file:read('*a')
    for i = 1, #input do
        local event_name = self.event_map[ input:byte( i ) + 1 ] --Serial get [0,n-1], Lua use [1,n]
        if event_name then
            self.redis_connection:lpush( self.server_config.namespace .. '_EVENTS', event_name )        
            for automaton_name, automaton in pairs( self.run.simulators ) do
                if automaton:event_exists( event_name ) then
                    automaton:event_evolve( event_name )
                end
            end
        end
    end
    
    --Evolve controlable events from X (TODO) calc disable
    for automaton_name, automaton in pairs( self.run.simulators ) do
        local events = automaton:get_current_state_controllable_events()
        if #events > 0 then
            local id = math.random( 1, #events )
            local event_name = events[id].name
            automaton:event_evolve( event_name )
            self.redis_connection:lpush( self.server_config.namespace .. '_EVENTS', event_name )
            
            local event_id   = self.event_map[ event_name ]
            if event_id then
                self.device_file:write( string.char( event_id - 1) )
                self.device_file:flush()
            end
        end
    end
    
    --Custom user Event generation

    
    return self.run and true or false
end
 
