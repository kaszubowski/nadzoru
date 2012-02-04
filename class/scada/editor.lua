ScadaEditor = letk.Class( function( self, gui, scada_plant, elements )
    Object.__super( self )
    self.gui         = gui
    self.scada_plant = scada_plant
    self.elements    = elements

    self:build_gui()

    -- Interface states
    self.operation                      = nil
    self.selected_component_IconView    = nil --from IconView
    self.selected_component             = nil --from DrawningArea
    self.selected_component_move_motion_diff_x = nil
    self.selected_component_move_motion_diff_y = nil
    self.scale = 13

end, Object )

ScadaEditor.scale_values = { 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.25, 1.5, 1.75, 2, 2.5, 3, 3.5, 4 }

function ScadaEditor:build_gui()
     self.vbox                            = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.toolbar                      = gtk.Toolbar.new()
        self.hbox                         = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.scrolled                 = gtk.ScrolledWindow.new()
                self.drawing_area         = gtk.DrawingArea.new( )
            --~ self.treeview_properties      = Treeview.new( true )
            self.properties               = PropertyEditor.new( )

    --~ self.drawing_area:add_events( gdk.POINTER_MOTION_MASK ) --movimento do mouse
    self.drawing_area:add_events( gdk.BUTTON_MOTION_MASK ) --movimento do mouse clicado
    self.drawing_area:connect("motion_notify_event", self.drawing_area_move_motion, self )
    self.drawing_area:add_events( gdk.BUTTON_PRESS_MASK )
    self.drawing_area:connect("button_press_event", self.drawing_area_press, self )
    self.drawing_area:connect('draw', self.drawing_area_expose, self )

    --~ self.treeview_properties:add_column_text( "Property",100 )
    --~ self.treeview_properties:add_column_text( "Value", 50, self.change_property, self )

    self.vbox:pack_start( self.toolbar, false, false, 0 )
    self.vbox:pack_start( self.hbox, true, true, 0 )
        self.hbox:pack_start( self.scrolled, true, true, 0 )
            self.scrolled:add_with_viewport(self.drawing_area)
        self.hbox:pack_start( self.properties:build( 128, 200 ), false, false, 0 )

    self:build_gui_components_list()
    self.properties:draw_interface()
    
    self:build_automaton_window()

    --save
    self.img_act_save = gtk.Image.new_from_file( './images/icons/save.png' )
    self.btn_act_save = gtk.ToolButton.new( self.img_act_save, "Save" )
    self.btn_act_save:connect( 'clicked', self.set_act_save, self )
    self.toolbar:insert( self.btn_act_save, -1 )

    --saveas
    self.img_act_saveas = gtk.Image.new_from_file( './images/icons/save_as.png' )
    self.btn_act_saveas = gtk.ToolButton.new( self.img_act_saveas, "Save As" )
    self.btn_act_saveas:connect( 'clicked', self.set_act_save_as, self )
    self.toolbar:insert( self.btn_act_saveas, -1 )

    --png
    self.img_act_png = gtk.Image.new_from_file( './images/icons/png.png' )
    self.btn_act_png = gtk.ToolButton.new( self.img_act_png, "PNG" )
    self.btn_act_png:connect( 'clicked', self.set_act_png, self )
    self.toolbar:insert( self.btn_act_png, -1 )

    --edit
    self.img_act_edit = gtk.Image.new_from_file( './images/icons/edit.png' )
    self.btn_act_edit = gtk.ToggleToolButton.new( )
    self.btn_act_edit:set_icon_widget( self.img_act_edit )
    self.btn_act_edit:connect( 'toggled', self.set_act_edit, self )
    self.toolbar:insert( self.btn_act_edit, -1 )

    --move_motion
    self.img_act_move_motion = gtk.Image.new_from_file( './images/icons/move_motion.png' )
    self.btn_act_move_motion = gtk.ToggleToolButton.new( )
    self.btn_act_move_motion:set_icon_widget( self.img_act_move_motion )
    self.btn_act_move_motion:connect( 'toggled', self.set_act_move_motion, self )
    self.toolbar:insert( self.btn_act_move_motion, -1 )

    --add
    self.img_act_add = gtk.Image.new_from_file( './images/icons/add.png' )
    self.btn_act_add = gtk.ToggleToolButton.new( )
    self.btn_act_add:set_icon_widget( self.img_act_add )
    self.btn_act_add:connect( 'toggled', self.set_act_add, self )
    self.toolbar:insert( self.btn_act_add, -1 )

    --delete
    self.img_act_delete = gtk.Image.new_from_file( './images/icons/delete.png' )
    self.btn_act_delete = gtk.ToggleToolButton.new( )
    self.btn_act_delete:set_icon_widget( self.img_act_delete )
    self.btn_act_delete:connect( 'toggled', self.set_act_delete, self )
    self.toolbar:insert( self.btn_act_delete, -1 )

    --automaton
    self.img_act_automaton = gtk.Image.new_from_file( './images/icons/automaton.png' )
    self.btn_act_automaton = gtk.ToolButton.new( self.img_act_automaton, "Automaton" )
    self.btn_act_automaton:connect( 'clicked', self.set_act_automaton, self )
    self.toolbar:insert( self.btn_act_automaton, -1 )

    --zoom_in
    self.img_act_zoom_in = gtk.Image.new_from_file( './images/icons/zoom_in.png' )
    self.btn_act_zoom_in = gtk.ToolButton.new( self.img_act_zoom_in, "Zoom in" )
    self.btn_act_zoom_in:connect( 'clicked', self.set_act_zoom_in, self )
    self.toolbar:insert( self.btn_act_zoom_in, -1 )
    
    --zoom_out
    self.img_act_zoom_out = gtk.Image.new_from_file( './images/icons/zoom_out.png' )
    self.btn_act_zoom_out = gtk.ToolButton.new( self.img_act_zoom_out, "Zoom out" )
    self.btn_act_zoom_out:connect( 'clicked', self.set_act_zoom_out, self )
    self.toolbar:insert( self.btn_act_zoom_out, -1 )

    self.gui:add_tab( self.vbox, "edit " .. (self.scada_plant:get('file_name') or "-x-") )
end

function ScadaEditor:build_gui_components_list()
    self.scrolled = gtk.ScrolledWindow.new()
    self.scrolled:set_shadow_type(gtk.SHADOW_ETCHED_IN)
    self.scrolled:set_policy(gtk.POLICY_AUTOMATIC, gtk.POLICY_AUTOMATIC)

    local iter  = gtk.TreeIter.new()
    local model = gtk.ListStore.new( 'gchararray', 'GdkPixbuf' )
    self.icon_view = gtk.IconView.new_with_model( model )
    self.icon_view:set_text_column ( 0 )
    self.icon_view:set_pixbuf_column  ( 1 )
    self.icon_view:set_item_padding( 1 )
    self.icon_view:set( 'item-width', 110 )
    self.scrolled:set( 'height-request', 110 )

    self.scrolled:add( self.icon_view )

    --Icon View (list of components)
    self.components_list = {}
    local count_itens = 0
    for name, component in pairs( ScadaComponent ) do
        self.components_list[ #self.components_list + 1 ] = name
        model:append( iter )
        local pixbuf = gdk.Pixbuf.new_from_file( component.icon )
        model:set( iter, 0 , component.caption, 1, pixbuf )
        count_itens = count_itens + 1
    end
    self.icon_view:set( 'columns', count_itens )

    self.vbox:pack_start( self.scrolled, false, false, 0 )

    --~ self.icon_view:connect('item-activated', self.select_component, self )
    self.icon_view:connect('selection-changed', self.select_component, self )
end

function ScadaEditor:build_automaton_window()
    self.AWgui = {}

    self.AWgui.win                               = gtk.Window.new( gtk.WINDOW_TOPLEVEL )
        self.AWgui.vbox                          = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
            self.AWgui.hbox                      = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            
                self.AWgui.treeview_automata     = Treeview.new( true )
                
                self.AWgui.vbox_g                = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                    self.AWgui.label_g           = gtk.Label.new_with_mnemonic( "G" )
                    self.AWgui.hbox_g_btn        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                        self.AWgui.btn_g_add     = gtk.Button.new_from_stock('gtk-add')
                        self.AWgui.btn_g_rm      = gtk.Button.new_from_stock('gtk-delete')
                    self.AWgui.treeview_g        = Treeview.new( true )
                    
                self.AWgui.vbox_e                = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                    self.AWgui.label_e           = gtk.Label.new_with_mnemonic( "E" )
                    self.AWgui.hbox_e_btn        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                        self.AWgui.btn_e_add     = gtk.Button.new_from_stock('gtk-add')
                        self.AWgui.btn_e_rm      = gtk.Button.new_from_stock('gtk-delete')
                    self.AWgui.treeview_e       = Treeview.new( true )
                    
                self.AWgui.vbox_k                = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                    self.AWgui.label_k           = gtk.Label.new_with_mnemonic( "K" )
                    self.AWgui.hbox_k_btn        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                        self.AWgui.btn_k_add     = gtk.Button.new_from_stock('gtk-add')
                        self.AWgui.btn_k_rm      = gtk.Button.new_from_stock('gtk-delete')
                    self.AWgui.treeview_k        = Treeview.new( true )
                    
                self.AWgui.vbox_s                = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                    self.AWgui.label_s           = gtk.Label.new_with_mnemonic( "S" )
                    self.AWgui.hbox_s_btn        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                        self.AWgui.btn_s_add     = gtk.Button.new_from_stock('gtk-add')
                        self.AWgui.btn_s_rm      = gtk.Button.new_from_stock('gtk-delete')
                    self.AWgui.treeview_s        = Treeview.new( true )
                    
        self.AWgui.hbox_btn                      = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.AWgui.btn_close                 = gtk.Button.new_with_label("Close")
            
    self.AWgui.treeview_automata:add_column_text( "Automaton",120 )
    self.AWgui.treeview_g:add_column_text( "Automaton",120 )
    self.AWgui.treeview_e:add_column_text( "Automaton",120 )
    self.AWgui.treeview_k:add_column_text( "Automaton",120 )
    self.AWgui.treeview_s:add_column_text( "Automaton",120 )
    
    self.AWgui.win:set("title", "nadzoru::SCADA - Automaton selector", "width-request", 600,
        "height-request", 500, "window-position", gtk.WIN_POS_CENTER,
        "icon-name", "gtk-about", "deletable", false)
            
    self.AWgui.win:add( self.AWgui.vbox )
        self.AWgui.vbox:pack_start( self.AWgui.hbox, true, true, 0 )
            self.AWgui.hbox:pack_start( self.AWgui.treeview_automata:build{width = 120}, true, true, 0 )
            
            self.AWgui.hbox:pack_start( self.AWgui.vbox_g, true, true, 0 )
                self.AWgui.vbox_g:pack_start( self.AWgui.label_g, false, false, 0 )
                self.AWgui.vbox_g:pack_start( self.AWgui.hbox_g_btn, false, false, 0 )
                    self.AWgui.hbox_g_btn:pack_start( self.AWgui.btn_g_add, true, true, 0 )
                    self.AWgui.hbox_g_btn:pack_start( self.AWgui.btn_g_rm, true, true, 0 )
                self.AWgui.vbox_g:pack_start( self.AWgui.treeview_g:build(), true, true, 0 )
            
            self.AWgui.hbox:pack_start( self.AWgui.vbox_e, true, true, 0 )
                self.AWgui.vbox_e:pack_start( self.AWgui.label_e, false, false, 0 )
                self.AWgui.vbox_e:pack_start( self.AWgui.hbox_e_btn, false, false, 0 )
                    self.AWgui.hbox_e_btn:pack_start( self.AWgui.btn_e_add, true, true, 0 )
                    self.AWgui.hbox_e_btn:pack_start( self.AWgui.btn_e_rm, true, true, 0 )
                self.AWgui.vbox_e:pack_start( self.AWgui.treeview_e:build(), true, true, 0 )
            
            self.AWgui.hbox:pack_start( self.AWgui.vbox_k, true, true, 0 )
                self.AWgui.vbox_k:pack_start( self.AWgui.label_k, false, false, 0 )
                self.AWgui.vbox_k:pack_start( self.AWgui.hbox_k_btn, false, false, 0 )
                    self.AWgui.hbox_k_btn:pack_start( self.AWgui.btn_k_add, true, true, 0 )
                    self.AWgui.hbox_k_btn:pack_start( self.AWgui.btn_k_rm, true, true, 0 )
                self.AWgui.vbox_k:pack_start( self.AWgui.treeview_k:build(), true, true, 0 )
                
            self.AWgui.hbox:pack_start( self.AWgui.vbox_s, true, true, 0 )
                self.AWgui.vbox_s:pack_start( self.AWgui.label_s, false, false, 0 )
                self.AWgui.vbox_s:pack_start( self.AWgui.hbox_s_btn, false, false, 0 )
                    self.AWgui.hbox_s_btn:pack_start( self.AWgui.btn_s_add, true, true, 0 )
                    self.AWgui.hbox_s_btn:pack_start( self.AWgui.btn_s_rm, true, true, 0 )
                self.AWgui.vbox_s:pack_start( self.AWgui.treeview_s:build(), true, true, 0 )
                
        self.AWgui.vbox:pack_start( self.AWgui.hbox_btn, false, false, 0 )
            self.AWgui.hbox_btn:pack_start( self.AWgui.btn_close, true, true, 0 )
            
            
        local function AWgui_close()
            self.scada_plant:load_automata( self.elements )
            self:update_properties()
            self.AWgui.win:hide()
        end
        self.AWgui.btn_close:connect('clicked', AWgui_close) 
        
        local function AWgui_add( opt )
            local positions = self.AWgui.treeview_automata:get_selected()
            for k,v in ipairs( positions ) do
                self.scada_plant.automata[ opt ][ self.AWgui.automata.all[v] ] = true
            end
            self:update_automaton_window()
        end
        self.AWgui.btn_g_add:connect('clicked', AWgui_add, 'g') 
        self.AWgui.btn_e_add:connect('clicked', AWgui_add, 'e') 
        self.AWgui.btn_k_add:connect('clicked', AWgui_add, 'k') 
        self.AWgui.btn_s_add:connect('clicked', AWgui_add, 's') 
        
        local function AWgui_rm( opt )
            local positions = self.AWgui['treeview_' .. opt]:get_selected()
            for k,v in ipairs( positions ) do
                self.scada_plant.automata[ opt ][ self.AWgui.automata[ opt ][v] ] = nil
            end
            self:update_automaton_window()
        end
        self.AWgui.btn_g_rm:connect('clicked', AWgui_rm, 'g') 
        self.AWgui.btn_e_rm:connect('clicked', AWgui_rm, 'e') 
        self.AWgui.btn_k_rm:connect('clicked', AWgui_rm, 'k') 
        self.AWgui.btn_s_rm:connect('clicked', AWgui_rm, 's') 
end

function ScadaEditor:start_automaton_window()
    if not self.AWgui then return end
    self.AWgui.treeview_automata:clear_data()
    
    self.AWgui.automata = {
        all = {},
    }
    
    for k, v in self.elements:ipairs() do
        if v.__TYPE == 'automaton' then
            self.AWgui.automata.all[#self.AWgui.automata.all + 1] = v:get( 'file_name' )
        end
    end
    table.sort( self.AWgui.automata.all )
    for k,v in ipairs( self.AWgui.automata.all ) do
        self.AWgui.treeview_automata:add_row{ v }
    end
    self.AWgui.treeview_automata:update()
end

function ScadaEditor:update_automaton_window()
    if not self.AWgui then return end
    self.AWgui.treeview_g:clear_data()
    self.AWgui.treeview_e:clear_data()
    self.AWgui.treeview_k:clear_data()
    self.AWgui.treeview_s:clear_data()

    self.AWgui.automata.g = {}
    self.AWgui.automata.e = {}
    self.AWgui.automata.k = {}
    self.AWgui.automata.s = {}
    
    for kp, p in ipairs{'g','e','k','s'} do
        for v, s in pairs( self.scada_plant.automata[p] ) do
            self.AWgui.automata[p][#self.AWgui.automata[p] + 1] = v
        end
        table.sort( self.AWgui.automata[p] )
        for k,v in ipairs( self.AWgui.automata[p] ) do
            self.AWgui['treeview_' .. p]:add_row{ v }
        end
        self.AWgui['treeview_' .. p]:update()
    end
end

function ScadaEditor:drawing_area_move_motion( event )
    local stats, coord_x, coord_y           = gdk.Event.get_coords( event )
    coord_x = coord_x / self.scale_values[ self.scale ]
    coord_y = coord_y / self.scale_values[ self.scale ]
    if self.operation == 'move_motion' then
        if self.selected_component then
            local v_x = math.floor(coord_x) - (self.selected_component_move_motion_diff_x or 0)
            local v_y = math.floor(coord_y) - (self.selected_component_move_motion_diff_y or 0)
            self.selected_component:set_property( 'x', v_x )
            self.selected_component:set_property( 'y', v_y )
            self.properties:set_value( 'x', self.selected_component:get_property( 'x' ) )
            self.properties:set_value( 'y', self.selected_component:get_property( 'y' ) )
            self:update_render()
        end
    end
end

function ScadaEditor:drawing_area_press( event )
    local stats, button_press = gdk.Event.get_button( event )

    if button_press == 1 then
        if self.last_drawing_area_lock then return end
        self.last_drawing_area_lock = true

        glib.timeout_add(glib.PRIORITY_DEFAULT, 100, function( self )
            self.last_drawing_area_lock = nil
        end, self )

        local _, x, y                      = gdk.Event.get_coords( event )
        x = x / self.scale_values[ self.scale ]
        y = y / self.scale_values[ self.scale ]
        local selected_component, position = self.scada_plant:get_selected( x, y )

        if self.operation == 'add' and self.selected_component_IconView then
            local new_component = self.scada_plant:add_component( self.selected_component_IconView )
            new_component:set_property( 'x', x )
            new_component:set_property( 'y', y )
            self.selected_component = new_component
            self:update()
        elseif self.operation == 'edit' then
            self.selected_component  = selected_component
            self:update_properties()
        elseif self.operation == 'move_motion' then
            if selected_component then
                self.selected_component = selected_component
                self.selected_component_move_motion_diff_x = math.floor(x) - self.selected_component:get_property( 'x', x )
                self.selected_component_move_motion_diff_y = math.floor(y) - self.selected_component:get_property( 'y', y )
                self:update()
            end
        elseif self.operation == 'delete' then
            if selected_component and position then
                self.scada_plant.component:remove( position )
                self:update()
            end
        end
    end
end

function ScadaEditor:select_component()
    local itens = self.icon_view:get_selected_items()
    if itens and itens[1] then
        self.selected_component_IconView = self.components_list[ itens[1] + 1 ]
    end
end

function ScadaEditor:change_property( prop_name, old_value, new_value )
    if self.selected_component then
        self.selected_component:set_property(
            prop_name,
            new_value
        )
        self:update_render()
    end
end

function ScadaEditor:drawing_area_expose( cr )
    cr = cairo.Context.wrap(cr)
    cr:scale( self.scale_values[ self.scale ], self.scale_values[ self.scale ] )
    self.scada_plant:render( cr )
end

function ScadaEditor:update_render()
    self.drawing_area:queue_draw()
end

local function make_help( self )
    local h = {}
    
    --Automaton
    local a     = { caption = "Automata", value = 'dfa_sim_list'}
    local all_a = {}
    for type_a, list_a in pairs(self.scada_plant.automata) do
        for name, value in pairs( list_a ) do
            all_a[ name ] = true
        end
    end
    
    for name, value in pairs( all_a ) do
        local new_value = string.format('dfa_sim_list[\'%s\']', name)
        local new_a     = { caption = name, value = new_value }
        for k_cmd, cmd in ipairs{
                {'get_current_state'             ,'get_current_state()'              }, 
                {'get_current_state_info'        ,'get_current_state()'              }, 
                {'get_current_state_events_info' ,'get_current_state()'              }, 
                {'change_state'                  ,'get_current_state( state_index )' }, 
            } 
        do
            table.insert(new_a, { caption = cmd[1], value = new_value .. ':' .. cmd[2] } )
        end
        table.insert( new_a, { caption = "Events" } )
        for k_event, event in self.scada_plant.automata_object[ name ].events:ipairs() do
            table.insert( new_a[#new_a], { caption =  event.name, value = string.format( '\'%s\'', event.name) } )
        end
        
        table.insert(a, new_a)
    end
        
    table.insert(h, a)
    
    --Component
    local c     = { caption = "Component", value = 'self' }
    for prop_name, prop in pairs( self.selected_component.properties ) do
        table.insert(c, { caption = prop.caption or prop_name, value = string.format('\'%s\'', prop_name) } )
        for k_cmd, cmd in ipairs{
                { 'set_property', 'set_property( \'%s\', value )'}, 
                { 'get_property', 'get_property( \'%s\' )'       }, 
            } 
        do
            table.insert( c[#c], { caption = cmd[1], value = 'self:' .. string.format( cmd[2], prop_name ) } )
        end
    end
    table.insert(h, c)
    
    --Expressions
    table.insert(h, { caption = "Expressions",
        { caption = 'if', value = 'if then\n\nend' },
        { caption = 'if else', value = 'if then\n\nelse\n\nend' },
        { caption = 'if elseif', value = 'if then\n\nelseif then\n\nend' },
        { caption = 'if elseif else', value = 'if then\n\nelseif then\n\nelse\n\nend' },
        { caption = 'while', value = 'while do\n\nend' },
        { caption = 'for <numeric>', value = 'for i= 1,10 do\n\nend' },
    
    })
    
    return h
end

function ScadaEditor:update_properties()
    self.properties:clear()

    if self.selected_component then
        self.properties:add_change_callback( self.change_property, self )
        for prop_name, prop in pairs( self.selected_component.properties ) do
            if not prop.private then
                if prop.type == 'integer' or prop.type == 'number' then
                    self.properties:add_row_entry( prop_name, prop.caption, self.selected_component:get_property( prop_name ), { min = prop.min, max = prop.max, type = prop.type})
                elseif prop.type == 'string' then
                    self.properties:add_row_entry( prop_name, prop.caption, self.selected_component:get_property( prop_name ), { type = prop.type})
                elseif prop.type == 'combobox' then
                    self.properties:add_row_combobox( prop_name, prop.caption, self.selected_component:get_property( prop_name ), prop.values )
                elseif prop.type == 'color' then
                    self.properties:add_row_color( prop_name, prop.caption, self.selected_component:get_property( prop_name ) )
                elseif prop.type == 'code' then
                    --Isolar em uma função local get_help( self , ... )
                    local options = {}
                    if prop.help then
                        options.help = make_help( self )
                    end
                    self.properties:add_row_code( prop_name, prop.caption, self.selected_component:get_property( prop_name ), options )
                end
            end
        end
    end

    self.properties:draw_interface()
end

function ScadaEditor:update()
    self:update_render( )
    self:update_properties( )
end

function ScadaEditor:toolbar_set_unset_operation( mode )
    local btn      = {'edit','move_motion','add','delete'}
    local active   = self['btn_act_' .. mode]:get('active')

    if active then
        self.operation = mode
        for _, b in ipairs( btn ) do
            if b ~= mode then
                self['btn_act_' .. b]:set('active',false)
            end
        end
    else
        if self.operation == mode then
            self.operation = nil
        end
    end
    self.selected_component = nil
    self:update()
end

function ScadaEditor:set_act_save()
    local status, err, err_list = self.scada_plant:save()
    if not status then
        if err == err_list.NO_FILE_NAME then
            self:set_act_save_as()
        elseif err == err_list.INVALID_FILE_TYPE then
            gtk.InfoDialog.showInfo("This plant is not a .nsp, use 'save as' or 'export'")
        elseif err == err_list.ACCESS_DENIED then
            gtk.InfoDialog.showInfo("Access denied for file: " .. tostring(self.scada_plant:get('full_file_name')) )
        end
    end
end

function ScadaEditor:set_act_save_as()
    local dialog = gtk.FileChooserDialog.new(
        "Save AS", nil,gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.nsp")
    filter:set_name("Nadzoru SCADA Plant")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        local status, err, err_list = self.scada_plant:save_as( names[1] )
        if not status then
            if err == err_list.ACCESS_DENIED then
                gtk.InfoDialog.showInfo("Access denied for file: " .. tostring(self.scada_plant:get('full_file_name')) )
            end
        else
            self.gui:set_tab_page_title( self.vbox, "edit " .. (self.scada_plant:get('file_name') or "-x-") )
        end
    end
end

function ScadaEditor:set_act_png()

end

function ScadaEditor:set_act_edit()
    self:toolbar_set_unset_operation( 'edit' )
end

function ScadaEditor:set_act_move_motion()
    self:toolbar_set_unset_operation( 'move_motion' )
end

function ScadaEditor:set_act_add()
    self:toolbar_set_unset_operation( 'add' )
end

function ScadaEditor:set_act_delete()
    self:toolbar_set_unset_operation( 'delete' )
end

function ScadaEditor:set_act_automaton()
    self:start_automaton_window()
    self:update_automaton_window()
    self.AWgui.win:show_all()
end

function ScadaEditor:set_act_zoom_out()
    self.scale = self.scale - 1
    if self.scale <= 0 then self.scale = 1 end
    self:update_render()
end

function ScadaEditor:set_act_zoom_in()
    self.scale = self.scale + 1
    if self.scale > #self.scale_values then self.scale = #self.scale_values end
    self:update_render()
end
