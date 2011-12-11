AutomatonEditor = letk.Class( function( self, gui, automaton )
    self.operation = nil
    self.automaton = automaton

    self.gui = gui

    self.vbox                  = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.toolbar           = gtk.Toolbar.new()
        self.hbox                  = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.render, self.scrolled, self.drawing_area = AutomatonRender.new( automaton )
            self.vbox2             = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                self.treeview_events      = Treeview.new( true )
                self.btn_add_event        = gtk.Button.new_from_stock( 'gtk-add' )
                self.btn_delete_event     = gtk.Button.new_from_stock( 'gtk-delete' )


    self.drawing_area:add_events( gdk.BUTTON_PRESS_MASK )
    self.drawing_area:connect("button_press_event", self.drawing_area_press, self )

    self.btn_add_event:connect('clicked', self.add_event, self )
    self.btn_delete_event:connect('clicked', self.delete_event, self )

    self.treeview_events:add_column_text("Events",100, self.edit_event, self)
    self.treeview_events:add_column_toggle("Con", 50, self.toggle_controllable, self )
    self.treeview_events:add_column_toggle("Obs", 50, self.toggle_observable,  self )

    self.vbox:pack_start( self.toolbar, false, false, 0 )
    self.vbox:pack_start( self.hbox, true, true, 0 )
        self.hbox:pack_start( self.scrolled, true, true, 0 )
        self.hbox:pack_start( self.vbox2, false, false, 0 )
            self.vbox2:pack_start( self.treeview_events:build{ width = 236 }, true, true, 0 )
            self.vbox2:pack_start( self.btn_add_event, false, false, 0 )
            self.vbox2:pack_start( self.btn_delete_event, false, false, 0 )

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

    --state
    self.img_act_state = gtk.Image.new_from_file( './images/icons/state.png' )
    self.btn_act_state = gtk.ToggleToolButton.new( )
    self.btn_act_state:set_icon_widget( self.img_act_state )
    self.btn_act_state:connect( 'toggled', self.set_act_state, self )
    self.toolbar:insert( self.btn_act_state, -1 )

     --state initial
    self.img_act_initial = gtk.Image.new_from_file( './images/icons/state_initial.png' )
    self.btn_act_initial = gtk.ToggleToolButton.new( )
    self.btn_act_initial:set_icon_widget( self.img_act_initial )
    self.btn_act_initial:connect( 'toggled', self.set_act_initial, self )
    self.toolbar:insert( self.btn_act_initial, -1 )

    --state marked
    self.img_act_marked = gtk.Image.new_from_file( './images/icons/state_marked.png' )
    self.btn_act_marked = gtk.ToggleToolButton.new( )
    self.btn_act_marked:set_icon_widget( self.img_act_marked )
    self.btn_act_marked:connect( 'toggled', self.set_act_marked, self )
    self.toolbar:insert( self.btn_act_marked, -1 )

    --transition
    self.img_act_transition = gtk.Image.new_from_file( './images/icons/transition.png' )
    self.btn_act_transition = gtk.ToggleToolButton.new( )
    self.btn_act_transition:set_icon_widget( self.img_act_transition )
    self.btn_act_transition:connect( 'toggled', self.set_act_transition, self )
    self.toolbar:insert( self.btn_act_transition, -1 )

    --delete
    self.img_act_delete = gtk.Image.new_from_file( './images/icons/delete.png' )
    self.btn_act_delete = gtk.ToggleToolButton.new( )
    self.btn_act_delete:set_icon_widget( self.img_act_delete )
    self.btn_act_delete:connect( 'toggled', self.set_act_delete, self )
    self.toolbar:insert( self.btn_act_delete, -1 )

    gui:add_tab( self.vbox, "edit " .. (automaton:get('file_name') or "-x-") )

    self:update_treeview_events()

    -- *** State Edit Window *** --
    self.state_window = {}
    self.state_window.window = gtk.Window.new(gtk.WINDOW_TOPLEVEL)
    self.state_window.vbox   = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
    self.state_window.hbox_1 = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
        self.state_window.lbl_nm = gtk.Label.new("Name")
        self.state_window.lbl_nm:set('xalign', 1)
        self.state_window.ent_nm = gtk.Entry.new()
    self.state_window.hbox_2 = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)


    self.state_window.window:set('title', "nadzoru - edit state", 'width-request', 300,
        'height-request', 200, 'window-position', gtk.WIN_POS_CENTER,
        'icon-name', 'gtk-about')
end, Object )

function AutomatonEditor:update_treeview_events()
    self.treeview_events:clear_data()
    for event_id, event in self.automaton.events:ipairs() do
        self.treeview_events:add_row{ event.name, event.controllable, event.observable }
    end
    self.treeview_events:update()
end

function AutomatonEditor:edit_state( state )
    local window       = gtk.Window.new(gtk.WINDOW_TOPLEVEL)
    local vbox         = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
    local hbox1        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    local hbox2        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    local label        = gtk.Label.new("Name")
    local entry        = gtk.Entry.new()
    local btnOk        = gtk.Button.new_with_mnemonic( "OK" )
    local btnCancel    = gtk.Button.new_with_mnemonic( "Cancel" )

    window:add( vbox )
        vbox:pack_start(hbox1, false, false, 0)
            hbox1:pack_start(label, true, true, 0)
            hbox1:pack_start(entry, true, true, 0)
        vbox:pack_start(hbox2, false, false, 0)
            hbox2:pack_start(btnOk, true, true, 0)
            hbox2:pack_start(btnCancel, true, true, 0)

    entry:set_text( state.name or '' )
    window:set_modal( true )
    window:set(
        "title", "State properties",
        "width-request", 200,
        "height-request", 70,
        "window-position", gtk.WIN_POS_CENTER,
        "icon-name", "gtk-about"
    )

    window:connect("delete-event", window.destroy, window)
    btnCancel:connect('clicked', function()
        self.render:draw({},{})
        window:destroy()
    end)
    btnOk:connect('clicked', function()
        state.name = entry:get_text()
        self.render:draw({},{})
        window:destroy()
    end)

    window:show_all()
end

function AutomatonEditor:edit_transition( source, target )
    local window          = gtk.Window.new(gtk.WINDOW_TOPLEVEL)
    local vbox            = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
    local tree            = Treeview.new( true )
    local btnOk           = gtk.Button.new_with_mnemonic( "OK" )
    local transitions_map
    local events_map

    function update()
        tree:clear_all()
        transitions_map = {}
        events_map      = {}
        for k_event, event in  self.automaton.events:ipairs() do
            tree:add_row{
                source.event_target[event] and source.event_target[event][target] and true or false,
                event.name
            }
            events_map[ k_event ] = event
            if source.event_target[event] and source.event_target[event][target] then
                for k_transition, transition in source.transitions_out:ipairs() do
                    if
                        transition.source == source and
                        transition.target == target and
                        transition.event  == event
                    then
                        transitions_map[ k_event ] = transition
                    end
                end
            end
        end
        tree:update()
    end

    tree:add_column_toggle("Tran", 50, function(self, row_id)
        if transitions_map then
            local item = row_id + 1
            if transitions_map[ item ]  then
                self.automaton:transition_remove( transitions_map[ item ] )
            else
                self.automaton:transition_add( source, target, events_map[ item ]  )
            end
            update()
        end
    end, self )
    tree:add_column_text("Event",100)

    window:add( vbox )
        vbox:pack_start(tree:build(), true, true, 0)
        vbox:pack_start(btnOk, false, false, 0)

    update()

    window:set_modal( true )
    window:set(
        "title", "Transition properties",
        "width-request", 200,
        "height-request", 300,
        "window-position", gtk.WIN_POS_CENTER,
        "icon-name", "gtk-about"
    )

    window:connect("delete-event", window.destroy, window)
    btnOk:connect('clicked', function()
        self.render:draw({},{})
        window:destroy()
    end)

    window:show_all()
end

function AutomatonEditor:toolbar_set_unset_operation( mode )
    local btn      = {'edit','move','state','marked','initial','transition','delete'}
    local active   = self['btn_act_' .. mode]:get('active')

    if active then
        self.operation = mode
        for _, b in ipairs( btn ) do
            if b ~= mode then
                self['btn_act_' .. b]:set('active',false)
            end
        end
        self.last_element = nil
        self.render:draw({},{})
    else
        if self.operation == mode then
            self.operation = nil
        end
    end
end

function AutomatonEditor:set_act_save()
    local status, err, err_list = self.automaton:save()
    if not status then
        if err == err_list.NO_FILE_NAME then
            self:set_act_save_as()
        elseif err == err_list.INVALID_FILE_TYPE then
            gtk.InfoDialog.showInfo("This automaton is not a .nza, use 'save as' or 'export'")
        elseif err == err_list.ACCESS_DENIED then
            gtk.InfoDialog.showInfo("Access denied for file: " .. tostring(self.automaton:get('full_file_name')) )
        end
    end
end

function AutomatonEditor:set_act_save_as()
    local dialog = gtk.FileChooserDialog.new(
        "Save AS", nil,gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.nza")
    filter:set_name("Nadzoru Automaton")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        local status, err, err_list = self.automaton:save_as( names[1] )
        if not status then
            if err == err_list.ACCESS_DENIED then
                gtk.InfoDialog.showInfo("Access denied for file: " .. tostring(self.automaton:get('full_file_name')) )
            end
        else
            self.gui:set_tab_page_title( self.vbox, "edit " .. (self.automaton:get('file_name') or "-x-") )
        end
    end
end

function AutomatonEditor:set_act_png()
    local dialog = gtk.FileChooserDialog.new(
        "Save AS", nil,gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.png")
    filter:set_name("Png image")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        local surface = cairo.ImageSurface.create(cairo.FORMAT_ARGB32, (self.render.last_size.x or 512)+64, (self.render.last_size.y or 512)+64 )
        print( self.render.last_size.x, self.render.last_size.y )
        local cr      = cairo.Context.create(surface)
        local size    = self.render:draw_context( cr )
        surface:write_to_png( names[1] )
        cr:destroy()
        surface:destroy()
    end
end

function AutomatonEditor:set_act_edit()
    self:toolbar_set_unset_operation( 'edit' )
end

function AutomatonEditor:set_act_move()
    self:toolbar_set_unset_operation( 'move' )
end

function AutomatonEditor:set_act_state()
    self:toolbar_set_unset_operation( 'state' )
end

function AutomatonEditor:set_act_initial()
    self:toolbar_set_unset_operation( 'initial' )
end

function AutomatonEditor:set_act_marked()
    self:toolbar_set_unset_operation( 'marked' )
end

function AutomatonEditor:set_act_transition()
    self:toolbar_set_unset_operation( 'transition' )
end

function AutomatonEditor:set_act_delete()
    self:toolbar_set_unset_operation( 'delete' )
end

function AutomatonEditor:drawing_area_press( event )
    if self.last_drawing_area_lock then return end
    self.last_drawing_area_lock = true

    glib.timeout_add(glib.PRIORITY_DEFAULT, 100, function( self )
        self.last_drawing_area_lock = nil
    end, self )

    local _, x, y = gdk.Event.get_coords( event )
    local element = self.render:select_element( x, y )

    --Botão para estado marcado, botão para estado inicial

    if self.operation == 'edit' then
        if element and element.type == 'state' then
            self.render:draw({[element.id] = {0.85,0,0}},{})
            self:edit_state( element.object )
        elseif element and element.type == 'transition' then
            self.render:draw({},{[element.index] = {0.85,0,0}})
            self:edit_transition( element.source_obj, element.target_obj )
        end
    elseif self.operation == 'state' then
        local id = self.automaton:state_add()
        self.automaton:state_set_position( id, x, y )
        self.render:draw({},{})
    elseif self.operation == 'move' then
        if self.last_element and self.last_element.type == 'state' then
            self.automaton:state_set_position( self.last_element.id, x, y )
            self.last_element = nil
            self.render:draw({},{})
        elseif element and element.type == 'state' then
            self.last_element = element
            self.render:draw({ [element.id] = {0.85,0,0} }, {})
        end
    elseif self.operation == 'initial' then
        if element and element.type == 'state' then
            self.automaton:state_set_initial( element.id )
            self.render:draw({},{})
        end
    elseif self.operation == 'marked' then
        if element and element.type == 'state' then
            if self.automaton:state_get_marked( element.id ) then
                self.automaton:state_unset_marked( element.id )
            else
                self.automaton:state_set_marked( element.id )
            end
            self.render:draw({},{})
        end
    elseif self.operation == 'delete' then
        if element and element.type == 'state' then
            self.automaton:state_remove( element.id )
            self.render:draw({},{})
        elseif element and element.type == 'transition' then
            for k_transition, transition in ipairs( element ) do
                self.automaton:transition_remove( transition.object )
            end
            self.render:draw({},{})
        end
    elseif self.operation == 'transition' then
        if self.last_element and self.last_element.type == 'state' and element and element.type == 'state' then
            local events = self.treeview_events:get_selected()
            for _, event_id in ipairs( events ) do
                self.automaton:transition_add( self.last_element.id, element.id, event_id )
            end
            self.last_element = nil
            self.render:draw({},{})
        elseif element and element.type == 'state' then
            self.last_element = element
            self.render:draw({[element.id] = {0.85,0,0} },{})
        end
    end
end

function AutomatonEditor:toggle_controllable( row_id )
    local event_id     = row_id+1
    if self.automaton:event_get_controllable( event_id ) then
        self.automaton:event_unset_controllable( event_id )
    else
        self.automaton:event_set_controllable( event_id )
    end
    self:update_treeview_events()
    self.render:draw()
end

function AutomatonEditor:toggle_observable( row_id )
    local event_id = row_id+1
    if self.automaton:event_get_observable( event_id ) then
        self.automaton:event_unset_observable( event_id )
    else
        self.automaton:event_set_observable( event_id )
    end
    self:update_treeview_events()
    self.render:draw()
end

function AutomatonEditor:edit_event( row_id, new_name )
    local event_id = row_id+1
    if event_id and new_name then
        self.automaton:event_set_name( event_id, new_name )
    end
    self:update_treeview_events()
    self.render:draw()
end

function AutomatonEditor:add_event()
    self.automaton:event_add("new")
    self:update_treeview_events()
end

function AutomatonEditor:delete_event()
    local events = self.treeview_events:get_selected()
    for _, event_id in ipairs( events ) do
        self.automaton:event_remove( event_id )
    end
    self:update_treeview_events()
    self.render:draw()
end
