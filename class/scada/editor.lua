ScadaEditor = letk.Class( function( self, gui, scada_plant )
    Object.__super( self )
    self.gui         = gui
    self.scada_plant = scada_plant

    self:build_gui()

    -- Interface states
    self.operation                     = nil
    self.selected_component_IconView   = nil --from IconView
    self.selected_component            = nil --from DrawningArea
    self.selected_component_properties = nil --map id -> prop_name

end, Object )

function ScadaEditor:build_gui()
     self.vbox                            = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.toolbar                      = gtk.Toolbar.new()
        self.hbox                         = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.scrolled                 = gtk.ScrolledWindow.new()
                self.drawing_area         = gtk.DrawingArea.new( )
            self.treeview_properties  = Treeview.new( true )


    self.drawing_area:add_events( gdk.BUTTON_PRESS_MASK )
    self.drawing_area:connect("button_press_event", self.drawing_area_press, self )
    self.drawing_area:connect('draw', self.drawing_area_expose, self )

    self.treeview_properties:add_column_text( "Property",100 )
    self.treeview_properties:add_column_text( "Value", 50, self.change_property, self )

    self.vbox:pack_start( self.toolbar, false, false, 0 )
    self.vbox:pack_start( self.hbox, true, true, 0 )
        self.hbox:pack_start( self.scrolled, true, true, 0 )
            self.scrolled:add_with_viewport(self.drawing_area)
        self.hbox:pack_start( self.treeview_properties:build{ width = 236 }, false, false, 0 )

    self:build_gui_components_list()

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

    --move
    self.img_act_move = gtk.Image.new_from_file( './images/icons/move.png' )
    self.btn_act_move = gtk.ToggleToolButton.new( )
    self.btn_act_move:set_icon_widget( self.img_act_move )
    self.btn_act_move:connect( 'toggled', self.set_act_move, self )
    self.toolbar:insert( self.btn_act_move, -1 )

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

    self.scrolled:add( self.icon_view )

    --Icon View (list of components)
    self.components_list = {}
    for name, component in pairs( ScadaComponent ) do
        self.components_list[ #self.components_list + 1 ] = name
        model:append( iter )
        local pixbuf = gdk.Pixbuf.new_from_file( component.icon )
        model:set( iter, 0 , component.caption, 1, pixbuf )
    end

    self.vbox:pack_start( self.scrolled, false, false, 0 )

    --~ self.icon_view:connect('item-activated', self.select_component, self )
    self.icon_view:connect('selection-changed', self.select_component, self )
end

function ScadaEditor:drawing_area_press( event )
    if self.last_drawing_area_lock then return end
    self.last_drawing_area_lock = true

    glib.timeout_add(glib.PRIORITY_DEFAULT, 100, function( self )
        self.last_drawing_area_lock = nil
    end, self )

    local _, x, y                      = gdk.Event.get_coords( event )
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
    elseif self.operation == 'move' then
        if not self.selected_component then
            self.selected_component = selected_component
        else
            self.selected_component:set_property( 'x', x )
            self.selected_component:set_property( 'y', y )
            self.selected_component = nil
        end
        self:update()
    elseif self.operation == 'delete' then
        if selected_component and position then
            self.scada_plant.component:remove( position )
            self:update()
        end
    end
end

function ScadaEditor:select_component()
    local itens = self.icon_view:get_selected_items()
    if itens and itens[1] then
        self.selected_component_IconView = self.components_list[ itens[1] + 1 ]
    end
end

function ScadaEditor:change_property( row_id, new_value )
    if self.selected_component and self.selected_component_properties then
        self.selected_component:set_property(
            self.selected_component_properties[ row_id+1 ],
            new_value
        )
        self:update()
    end
end

function ScadaEditor:drawing_area_expose( cr )
    cr = cairo.Context.wrap(cr)
    self.scada_plant:render( cr )
end

function ScadaEditor:update_render()
    self.drawing_area:queue_draw()
end

function ScadaEditor:update_properties()
    self.treeview_properties:clear_all()
    self.selected_component_properties = {}

    if self.selected_component then
        for prop_name, prop in pairs( self.selected_component.properties ) do
            if not prop.private then
                self.treeview_properties:add_row{ prop.caption, self.selected_component:get_property( prop_name ) }
                self.selected_component_properties[ #self.selected_component_properties + 1 ] = prop_name
            end
        end
    end

    self.treeview_properties:update()
end

function ScadaEditor:update()
    self:update_render( cr )
    self:update_properties( cr )
end

function ScadaEditor:toolbar_set_unset_operation( mode )
    local btn      = {'edit','move','add','delete'}
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

function ScadaEditor:set_act_move()
    self:toolbar_set_unset_operation( 'move' )
end

function ScadaEditor:set_act_add()
    self:toolbar_set_unset_operation( 'add' )
end

function ScadaEditor:set_act_delete()
    self:toolbar_set_unset_operation( 'delete' )
end

function ScadaEditor:set_act_automaton()

end
