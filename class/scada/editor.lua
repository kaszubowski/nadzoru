ScadaEditor = letk.Class( function( self, gui, scada_plant, elements )
    Object.__super( self )
    self.gui            = gui
    self.scada_plant    = scada_plant
    self.elements       = elements

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
            self.properties               = PropertyEditor.new( )

    --~ self.drawing_area:add_events( gdk.POINTER_MOTION_MASK ) --movimento do mouse
    self.drawing_area:add_events( gdk.BUTTON_MOTION_MASK ) --movimento do mouse clicado
    self.drawing_area:connect("motion_notify_event", self.drawing_area_move_motion, self )
    self.drawing_area:add_events( gdk.BUTTON_PRESS_MASK )
    self.drawing_area:connect("button_press_event", self.drawing_area_press, self )
    self.drawing_area:connect('draw', self.drawing_area_expose, self )

    self.vbox:pack_start( self.toolbar, false, false, 0 )
    self.vbox:pack_start( self.hbox, true, true, 0 )
        self.hbox:pack_start( self.scrolled, true, true, 0 )
            self.scrolled:add_with_viewport(self.drawing_area)
        self.hbox:pack_start( self.properties:build( 128, 200 ), false, false, 0 )
    
    self.scrolled:set_shadow_type(gtk.SHADOW_ETCHED_IN)

    self:build_gui_components_list()
    self.properties:draw_interface()

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
    --~ self.img_act_png = gtk.Image.new_from_file( './images/icons/png.png' )
    --~ self.btn_act_png = gtk.ToolButton.new( self.img_act_png, "PNG" )
    --~ self.btn_act_png:connect( 'clicked', self.set_act_png, self )
    --~ self.toolbar:insert( self.btn_act_png, -1 )

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
        if component.final_component then
            self.components_list[ #self.components_list + 1 ] = name
            model:append( iter )
            local pixbuf = gdk.Pixbuf.new_from_file( component.icon )
            model:set( iter, 0 , component.caption, 1, pixbuf )
            count_itens = count_itens + 1
        end
    end
    self.icon_view:set( 'columns', count_itens )

    self.vbox:pack_start( self.scrolled, false, false, 0 )

    self.icon_view:connect('selection-changed', self.select_component, self )
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
    local x,y = self.scada_plant:render( cr )
    self.drawing_area:set_size_request( (x+32)*self.scale_values[ self.scale ], (y+32)*self.scale_values[ self.scale ] )
end

function ScadaEditor:update_render()
    self.drawing_area:queue_draw()
end

local function make_help( self )
    local h = {}
    
    --Automaton
    local a     = { caption = "Automata", value = 'dfa_sim_list'}
    local all_a = {}
    if self.scada_plant.automata_group_name and not self.scada_plant.automata_group then
        self.scada_plant:load_automata_group( self.elements )
    end
    
    if self.scada_plant.automata_group then
        self.scada_plant.automata_group:load_automata( self.elements )
        for type_a, list_a in pairs( self.scada_plant.automata_group.automata_file ) do
            for name, value in pairs( list_a ) do
                all_a[ name ] = true
            end
        end
    
    
        for name, value in pairs( all_a ) do
            local new_value = string.format('dfa_sim_list[\'%s\']', name)
            local new_a     = { caption = name, value = new_value }
            for k_cmd, cmd in ipairs{
                    {'get_current_state'             ,'get_current_state()'               }, 
                    {'get_current_state_info'        ,'get_current_state_info()'          }, 
                    {'get_current_state_events_info' ,'get_current_state_events_info()'   }, 
                    {'change_state'                  ,'change_state( state_index )'       }, 
                    {'get_event_options'             ,'get_event_options( event_index )'  }, 
                    {'event_evolve'                  ,'event_evolve( event_index )'       }, 
                } 
            do
                table.insert(new_a, { caption = cmd[1], value = new_value .. ':' .. cmd[2] } )
            end
            table.insert( new_a, { caption = "Events" } )
            if self.scada_plant.automata_group.automata_object and self.scada_plant.automata_group.automata_object[ name ] then
                for k_event, event in self.scada_plant.automata_group.automata_object[ name ].events:ipairs() do
                    table.insert( new_a[#new_a], { caption =  event.name, value = string.format( '\'%s\'', event.name) } )
                end
            end
            table.insert( new_a, { caption = "States" } )
            if self.scada_plant.automata_group.automata_object and self.scada_plant.automata_group.automata_object[ name ] then
                for k_state, state in self.scada_plant.automata_group.automata_object[ name ].states:ipairs() do
                    table.insert( new_a[#new_a], { caption =  state.name, value = string.format( '%i', k_state ) } )
                end
            end
            
            table.insert(a, new_a)
        end
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
                elseif prop.type == 'boolean' then
                    self.properties:add_row_checkbox( prop_name, prop.caption, self.selected_component:get_property( prop_name ) )
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
    Selector.new({
        title = "Automata Group",
        success_fn = function( results, numresult )
            if results and results[1] then
                self.scada_plant:add_automata_group( results[1] )
                self:update_properties()
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automatagroup'
        end,
        text = "Automata Group:"
    }
    :run()
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
