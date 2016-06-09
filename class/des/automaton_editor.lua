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
module "AutomatonEditor"
--]]
AutomatonEditor = letk.Class( function( self, gui, automaton, elements )
    self.operation = nil
    self.automaton = automaton
    self.elements  = elements
    self.gui       = gui

    self.vbox                  = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.toolbar           = gtk.Toolbar.new()
        self.hbox                  = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.render, self.scrolled, self.drawing_area = AutomatonRender.new( automaton )
            self.vbox2             = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
--[[
                self.type_box = gtk.ComboBoxText.new()
                local type_list = get_list('type')
                for _,t in ipairs(type_list) do
                    self.type_box:append_text(t)
                end
                self.type_box:set('active', type_list[automaton.type])
                self.type_box:connect('changed', function()
                    self.automaton.type = type_list[self.type_box:get('active')+1]
                    for tab_id, tab in self.gui.tab:ipairs() do
                        if tab.content and tab.content.automaton==self.automaton then
                            tab.content.type_box:set('active', self.type_box:get('active'))
                        end
                    end
                    if gui:get_current_content()==self and not self.automaton.undoing and not self.automaton.redoing then
                        self.automaton:write_log(function()
                            self.type_box:set('active', type_list[self.automaton.type])
                        end)
                    end
                end)
                self.automaton.type = type_list[self.type_box:get('active')+1]
--]]
                self.treeview_events      = Treeview.new( true )
                self.btn_add_event        = gtk.Button.new_from_icon_name ( 'gtk-add' )
                self.btn_copy_events      = gtk.Button.new_from_icon_name ( 'gtk-copy' )
                self.btn_delete_event     = gtk.Button.new_from_icon_name ( 'gtk-delete' )


    --~ self.drawing_area:add_events( gdk.POINTER_MOTION_MASK ) --movimento do mouse
    self.drawing_area:add_events( gdk.BUTTON_MOTION_MASK ) --movimento do mouse clicado
    self.drawing_area:add_events( gdk.BUTTON_PRESS_MASK ) --clique do mouse
    --self.drawing_area:add_events( gdk.BUTTON_RELEASE_MASK ) --"desclique" do mouse

    self.drawing_area:connect("motion_notify_event", self.drawing_area_move_motion, self )
    self.drawing_area:connect("button_press_event", self.drawing_area_press, self )
    --self.drawing_area:connect("button_press_event", self.drawing_area_move_motion, self )
    --self.drawing_area:connect("button_release_event", self.drawing_area_release, self )

    self.btn_add_event:connect('clicked', self.add_event, self )
    self.btn_copy_events:connect('clicked', self.copy_events, self )
    self.btn_delete_event:connect('clicked', self.delete_event, self )

    self.treeview_events:add_column_text("Events",100, self.edit_event, self)
    self.treeview_events:add_column_toggle("Con", 50, self.toggle_controllable, self )
    self.treeview_events:add_column_toggle("Obs", 50, self.toggle_observable,  self )
    self.treeview_events:add_column_toggle("Sha", 50, self.toggle_shared,  self )

    self.vbox:pack_start( self.toolbar, false, false, 0 )
    self.vbox:pack_start( self.hbox, true, true, 0 )
        self.hbox:pack_start( self.scrolled, true, true, 0 )
        self.hbox:pack_start( self.vbox2, false, false, 0 )
            --self.vbox2:pack_start( gtk.Label.new_with_mnemonic('Type:'), false, false, 0 )
            --self.vbox2:pack_start( self.type_box, false, false, 0 )
            self.vbox2:pack_start( self.treeview_events:build{ width = 236 }, true, true, 0 )
            self.vbox2:pack_start( self.btn_add_event, false, false, 0 )
            self.vbox2:pack_start( self.btn_copy_events, false, false, 0 )
            self.vbox2:pack_start( self.btn_delete_event, false, false, 0 )
            --self.treeview_events.columns[1]:set('sizing', gtk.TREE_VIEW_COLUMN_AUTOSIZE)

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

    --exportides
    self.img_act_idesexport = gtk.Image.new_from_file( './images/icons/ides_export.png' )
    self.btn_act_idesexport = gtk.ToolButton.new( self.img_act_idesexport, "IDES" )
    self.btn_act_idesexport:connect( 'clicked', self.set_act_ides_export, self )
    self.toolbar:insert( self.btn_act_idesexport, -1 )

    --exporttct
    self.img_act_tctexport = gtk.Image.new_from_file( './images/icons/tct_export.png' )
    self.btn_act_tctexport = gtk.ToolButton.new( self.img_act_tctexport, "TCT" )
    self.btn_act_tctexport:connect( 'clicked', self.set_act_tct_export, self )
    self.toolbar:insert( self.btn_act_tctexport, -1 )

    --png
    self.img_act_png = gtk.Image.new_from_file( './images/icons/png.png' )
    self.btn_act_png = gtk.ToolButton.new( self.img_act_png, "PNG" )
    self.btn_act_png:connect( 'clicked', self.set_act_png, self )
    self.toolbar:insert( self.btn_act_png, -1 )

    --separator
    self.sep = gtk.SeparatorToolItem.new()
    self.toolbar:insert( self.sep, -1 )

    --~ --undo
    --~ self.img_act_undo = gtk.Image.new_from_icon_name( 'gtk-go-back' )
    --~ self.btn_act_undo = gtk.ToolButton.new( self.img_act_undo, "Undo" )
    --~ self.btn_act_undo:connect( 'clicked', self.automaton.undo, self.automaton )
    --~ self.toolbar:insert( self.btn_act_undo, -1 )
--~ 
    --~ --redo
    --~ self.img_act_redo = gtk.Image.new_from_icon_name( 'gtk-go-forward' )
    --~ self.btn_act_redo = gtk.ToolButton.new( self.img_act_redo, "Redo" )
    --~ self.btn_act_redo:connect( 'clicked', self.automaton.redo, self.automaton )
    --~ self.toolbar:insert( self.btn_act_redo, -1 )

    --separator
    self.sep = gtk.SeparatorToolItem.new()
    self.toolbar:insert( self.sep, -1 )

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

    --move_motion
    self.img_act_move_motion = gtk.Image.new_from_file( './images/icons/move_motion.png' )
    self.btn_act_move_motion = gtk.ToggleToolButton.new( )
    self.btn_act_move_motion:set_icon_widget( self.img_act_move_motion )
    self.btn_act_move_motion:connect( 'toggled', self.set_act_move_motion, self )
    self.toolbar:insert( self.btn_act_move_motion, -1 )

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

    -- N-State
    self.img_act_state_n = gtk.Image.new_from_file( './images/icons/state_n.png' )
    self.btn_act_state_n = gtk.ToggleToolButton.new( )
    self.btn_act_state_n:set_icon_widget( self.img_act_state_n )
    self.btn_act_state_n:connect( 'toggled', self.set_act_state_n, self )
    self.toolbar:insert( self.btn_act_state_n, -1 )
    
    -- Y-State
    self.img_act_state_y = gtk.Image.new_from_file( './images/icons/state_y.png' )
    self.btn_act_state_y = gtk.ToggleToolButton.new( )
    self.btn_act_state_y:set_icon_widget( self.img_act_state_y )
    self.btn_act_state_y:connect( 'toggled', self.set_act_state_y, self )
    self.toolbar:insert( self.btn_act_state_y, -1 )

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

    --position states
    self.img_act_positionstates = gtk.Image.new_from_file( './images/icons/position_states.png' )
    self.btn_act_positionstates = gtk.ToolButton.new( self.img_act_positionstates, "" )
    self.btn_act_positionstates:connect( 'clicked', self.set_act_position_states, self )
    self.toolbar:insert( self.btn_act_positionstates, -1 )

    --renumber states
    self.img_act_renumber_states = gtk.Image.new_from_file( './images/icons/position_states.png' )
    self.btn_act_renumber_states = gtk.ToolButton.new( self.img_act_renumber_states, "" )
    self.btn_act_renumber_states:connect( 'clicked', self.set_act_renumber_states, self )
    self.toolbar:insert( self.btn_act_renumber_states, -1 )

    --factor
    self.scale_act_factor = gtk.Scale.new_with_range( gtk.ORIENTATION_HORIZONTAL, 0.2, 5.0, 0.2 )
    self.scale_act_factor:set_digits( 1 )
    --~ self.scale_act_factor:connect( 'change-value', function( s, scrollType, value )
        --~ s:change_radius_factor( value )
    --~ end, self )
    self.scale_act_factor:connect( 'value-changed', function( s)
        s:change_radius_factor( s.scale_act_factor:get_value() )
    end, self )
    self.tool_item        = gtk.ToolItem.new()
    self.tool_item:set_homogeneous( true )
    self.tool_item:add( self.scale_act_factor )
    self.toolbar:insert( self.tool_item, -1 )
    
    


    gui:add_tab( self.vbox, (automaton:get('file_name') or "-x-"), nil, nil, self )

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

---Updates the list of events.
--Clears the event treeview. For each event in the automaton, draws a row with its name. Resizes the treeview to fit the event names. Updates equivalent treeviews.
--@param self AutomatonEditor whose event list is updated.
--@see Treeview:clear_data
--@see Treeview:add_row
--@see Treeview:update
--function AutomatonEditor:update_treeview_events(hist)---???
function AutomatonEditor:update_treeview_events()
    --local max = 0 --???
    self.treeview_events:clear_data()
    for event_id, event in self.automaton.events:ipairs() do
        --if event.name and #event.name > max then
        --    max = #event.name
        --end
        --self.treeview_events:add_row{ event.name }
        self.treeview_events:add_row{ event.name, event.controllable, event.observable, event.shared }
    end

    --max = 7*max
    --if max < 36 then
    --    max = 36
    --end
    --self.treeview_events.scrolled:set('width-request', max+30)
    --self.treeview_events.render[1]:set('width', max)
    self.treeview_events:update()

    --Update other treeviews
    --hist = hist or {}
    --hist[self] = true
    --for tab_id, tab in self.gui.tab:ipairs() do
    --    if not hist[tab.content] and tab.content and tab.content.automaton==self.automaton then
    --        tab.content:update_treeview_events(hist)
    --    end
    --end
end

---Opens the window for editing a state.
--TODO
--@param self Automaton editor in which the operation is applied.
--@param state State to be edited.
--@see AutomatonRender:draw
--@see Automaton:write_log
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
        local name = entry:get_text()
        local exists
        local state_id
        for k_s, s in self.automaton.states:ipairs() do
            if s.name==name and s~=state then
                exists = true
                break
            end
            if s==state then
                state_id = k_s
            end
        end

        if not exists and #name>0 then
            self.automaton:state_set_name(state_id, entry:get_text())
            self.render:draw({},{})
            --self.automaton:write_log(function()
            --    self.render:draw({},{})
            --end)
            window:destroy()
        end
    end)

    window:show_all()
end




---Opens the window for editing a transition.
--TODO
--@param self Automaton editor in which the operation is applied.
--@param source Source state of the transition.
--@param target Target state of the transition.
--@see Treeview:clear_all
--@see Treeview:add_row
--@see Treeview:update
--@see Treeview:add_column_toggle
--@see Automaton:transition_remove
--@see Automaton:transition_add
--@see Treeview:add_column_text
--@see AutomatonRender:draw
--@see Automaton:write_log
function AutomatonEditor:edit_transition( source, target )
    local window          = gtk.Window.new(gtk.WINDOW_TOPLEVEL)
        local vbox        = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        local tree        = Treeview.new( true )
        local scale       = gtk.Scale.new_with_range( gtk.ORIENTATION_HORIZONTAL, 0.2, 5.0, 0.2 )
        local btnOk           = gtk.Button.new_with_mnemonic( "OK" )
    local events_toggle   = {}
    local transitions_map = {}
    local events_map      = {}

    scale:set_digits( 1 )

    --~ self.scale_act_factor:connect( 'value-changed', function( s)
        --~ s:change_radius_factor( s.scale_act_factor:get_value() )
    --~ end, self )

    for k_event, event in self.automaton.events:ipairs() do
        events_toggle[k_event] = source.event_target[event] and source.event_target[event][target] and true or false
        events_map[ k_event ] = event
        if source.event_target[event] and source.event_target[event][target] then
            for k_transition, transition in source.transitions_out:ipairs() do
                if transition.source == source and transition.target == target and transition.event == event then
                    transitions_map[ k_event ] = transition
                end
            end
        end
    end

    local function update()
        tree:clear_all()
        for k_event, toggle in ipairs(events_toggle) do
            tree:add_row{
                toggle,
                events_map[k_event].name
            }
        end
        tree:update()
    end

    tree:add_column_toggle("Tran", 50, function(self, row_id)
        local item = row_id + 1
        events_toggle[item] = not events_toggle[item]
        update()
    end, self )
    tree:add_column_text("Event", 100)

    window:add( vbox )
        vbox:pack_start(tree:build(), true, true, 0)
        vbox:pack_start(scale, false, false, 0)
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
        for k_event, toggle in ipairs(events_toggle) do
            if toggle then
                if not transitions_map[k_event] then
                    self.automaton:transition_add(source, target, events_map[k_event])
                end
            else
                if transitions_map[k_event] then
                    self.automaton:transition_remove(transitions_map[k_event])
                end
            end
        end

        source.target_trans_factor[ target ] = scale:get_value()

        self.render:draw({},{})
        --self.automaton:write_log(function() --???
        --  self.render:draw({},{})
        --end)
        window:destroy()
    end)

    window:show_all()
end

---Sets a mode to active, deactivating the others.
--TODO
--@param self Automaton editor in which the operation is applied.
--@param mode Mode to be activated.
--@see AutomatonRender:draw
function AutomatonEditor:toolbar_set_unset_operation( mode )
    --local btn      = {'edit','move','state','marked','initial','transition','delete','move_motion'}
    local btn      = {'edit','move','state','state_n','state_y','marked','initial','transition','delete','move_motion'}
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
            --TODO: CHECK IF NEEDEDself.render:draw({},{})
        end
    end
end

---Tries to save the automaton to its current file, showing error messages if necessary.
--TODO
--@param self Automaton editor in which the operation is applied.
--@see Automaton:save
--@see AutomatonEditor:set_act_save_as
--@see Object:get
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

---Opens the window for saving an automaton to a file.
--TODO
--@param self Automaton editor in which the operation is applied.
--@see Automaton:save_as
--@see Gui:set_tab_page_title
--@see Object:get
function AutomatonEditor:set_act_save_as()
    local dialog = gtk.FileChooserDialog.new(
        "Save AS", self.gui.window, gtk.FILE_CHOOSER_ACTION_SAVE,
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
            self.gui:set_tab_page_title( self.vbox, (self.automaton:get('file_name') or "-x-") )
        end
    end
end

---Opens the window for exporting an automaton to IDES.
--TODO
--@param self Automaton editor in which the operation is applied.
--@see Automaton:IDES_export
--@see Object:get
function AutomatonEditor:set_act_ides_export()
    local dialog = gtk.FileChooserDialog.new(
        "IDES Export", self.gui.window, gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.xmd")
    filter:set_name("IDES Automaton")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        local status, err, err_list = self.automaton:IDES_export( names[1] )
        if not status then
            if err == err_list.ACCESS_DENIED then
                gtk.InfoDialog.showInfo("Access denied for file: " .. tostring(self.automaton:get('full_file_name')) )
            end
        else
            if self.automaton:get( 'file_type' ) ~= 'nza' then
                self.gui:set_tab_page_title( self.vbox, (self.automaton:get('file_name') or "-x-") )
            end
        end
    end
end

---Opens the window for exporting an automaton to TCT.
--TODO
--@param self Automaton editor in which the operation is applied.
--@see Automaton:TCT_export
--@see Object:get
function AutomatonEditor:set_act_tct_export()
    local dialog = gtk.FileChooserDialog.new(
        "TCT Export", self.gui.window, gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    --~ filter:add_pattern("*.ADS")
    filter:add_pattern("*.ads")
    filter:set_name("TCT Automaton")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        --names[1] = string.upper(names[1]) --WTF, never do that
        local status, err, err_list = self.automaton:TCT_export( names[1] )
        if not status then
            if err == err_list.ACCESS_DENIED then
                gtk.InfoDialog.showInfo("Access denied for file: " .. tostring(self.automaton:get('full_file_name')) )
            end
        else
            if self.automaton:get( 'file_type' ) ~= 'nza' then
                self.gui:set_tab_page_title( self.vbox, (self.automaton:get('file_name') or "-x-") )
            end
        end
    end
end

---Opens the window for creating a png of the automaton.
--TODO
--@param self Automaton editor in which the operation is applied.
--@see AutomatonRender:draw_context
function AutomatonEditor:set_act_png()
    local dialog = gtk.FileChooserDialog.new(
        "Save AS", self.gui.window, gtk.FILE_CHOOSER_ACTION_SAVE,
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
        if not names[1]:match( '%.png$' ) then
            names[1] = names[1] .. '.png'
        end
        surface:write_to_png( names[1] )
        cr:destroy()
        surface:destroy()
    end
end

---Sets mode to 'edit'.
--Sets mode to 'edit'.
--@param self Automaton editor in which the operation is applied.
--@see AutomatonEditor:toolbar_set_unset_operation
function AutomatonEditor:set_act_edit()
    self:toolbar_set_unset_operation( 'edit' )
end

---Sets mode to 'move'.
--Sets mode to 'move'.
--@param self Automaton editor in which the operation is applied.
--@see AutomatonEditor:toolbar_set_unset_operation
function AutomatonEditor:set_act_move()
    self:toolbar_set_unset_operation( 'move' )
end

---Sets mode to 'move_motion'.
--Sets mode to 'move_motion'.
--@param self Automaton editor in which the operation is applied.
--@see AutomatonEditor:toolbar_set_unset_operation
function AutomatonEditor:set_act_move_motion()
    self:toolbar_set_unset_operation( 'move_motion' )
end

---Sets mode to 'state'.
--Sets mode to 'state'.
--@param self Automaton editor in which the operation is applied.
--@see AutomatonEditor:toolbar_set_unset_operation
function AutomatonEditor:set_act_state()
    self:toolbar_set_unset_operation( 'state' )
end

--- Sets mode to 'n-state'
-- Sets mode to 'n-state'
--@param self Automaton editor in which the operation is applied.
--@see AutomatonEditor:toolbar_set_unset_operation
function AutomatonEditor:set_act_state_n()
    self:toolbar_set_unset_operation( 'state_n' )
end

--- Sets mode to 'y-state'
-- Sets mode to 'y-state'
--@param self Automaton editor in which the operation is applied.
--@see AutomatonEditor:toolbar_set_unset_operation
function AutomatonEditor:set_act_state_y()
    self:toolbar_set_unset_operation( 'state_y' )
end


---Sets mode to 'initial'.
--Sets mode to 'initial'.
--@param self Automaton editor in which the operation is applied.
--@see AutomatonEditor:toolbar_set_unset_operation
function AutomatonEditor:set_act_initial()
    self:toolbar_set_unset_operation( 'initial' )
end

---Sets mode to 'marked'.
--Sets mode to 'marked'.
--@param self Automaton editor in which the operation is applied.
--@see AutomatonEditor:toolbar_set_unset_operation
function AutomatonEditor:set_act_marked()
    self:toolbar_set_unset_operation( 'marked' )
end

---Sets mode to 'transition'.
--Sets mode to 'transition'.
--@param self Automaton editor in which the operation is applied.
--@see AutomatonEditor:toolbar_set_unset_operation
function AutomatonEditor:set_act_transition()
    self:toolbar_set_unset_operation( 'transition' )
end

---Sets mode to 'delete'.
--Sets mode to 'delete'.
--@param self Automaton editor in which the operation is applied.
--@see AutomatonEditor:toolbar_set_unset_operation
function AutomatonEditor:set_act_delete()
    self:toolbar_set_unset_operation( 'delete' )
end

---Position states of the automaton.
--Position states of the automaton. Updates the screen.
--@param self AutomatonEditor in which the operation is applied.
--@see Automaton:position_states
--@see AutomatonRender:draw
function AutomatonEditor:set_act_position_states()
    self.automaton:position_states()
    self.render:draw()
    --self.automaton:write_log(function()
    --    for tab_id, tab in self.gui.tab:ipairs() do
    --        self.render:draw()
    --    end
    --end)
end

function AutomatonEditor:set_act_renumber_states()
    self:renumber_states()
    self.render:draw()
    --self.automaton:write_log(function()
    --    for tab_id, tab in self.gui.tab:ipairs() do
    --        self.render:draw()
    --    end
    --end)
end

local function scalar(v, u)
    return v.x*u.x + v.y*u.y
end

---Handles mouse moving in the editor.
--TODO
--@param self AutomatonEditor in which the operation is applied.
--@param event Mouse move event.
--@see AutomatonRender:draw
--@see Automaton:transition_set_factor
function AutomatonEditor:drawing_area_move_motion( event )
    local stats, coord_x, coord_y           = gdk.Event.get_coords( event )
    if self.operation == 'move_motion' then
        if self.last_element and self.last_element.type == 'state'  then
            --~ self.last_element.object.x = math.floor(coord_x) - (self.selected_component_move_motion_diff_x or 0)
            --~ self.last_element.object.y = math.floor(coord_y) - (self.selected_component_move_motion_diff_y or 0)
            local x = math.floor(coord_x) - (self.selected_component_move_motion_diff_x or 0)
            local y = math.floor(coord_y) - (self.selected_component_move_motion_diff_y or 0)
            self.automaton:state_set_position( self.last_element.id, x, y )
            self.render:draw({ [self.last_element.id] = {0.85,0,0} }, {})
        --[[  ---???      
        elseif self.last_element and self.last_element.type == 'transition' then
            local factor
            if self.last_element.source_obj~=self.last_element.target_obj then
                local proj, d, v
                --not selfloop
                d = {
                    x = coord_x - (self.last_element.source_obj.x + self.last_element.target_obj.x)/2,
                    y = coord_y - (self.last_element.source_obj.y + self.last_element.target_obj.y)/2,
                }
                v = {
                    --it is swapped on purpose
                    y = self.last_element.source_obj.x - self.last_element.target_obj.x,
                    x = -(self.last_element.source_obj.y - self.last_element.target_obj.y),
                }
                proj = scalar(v,v)/scalar(d,v)
                if proj>=0 then
                    factor = 2^proj/10
                else
                    factor = -2^-proj/10
                end
            else
                --selfloop
                factor = (self.last_element.source_obj.y - coord_y - 2*self.last_element.source_obj.r)/3
                if factor<0 then
                    factor = 0
                end
            end
            if factor>100 then
                factor = 100
            end
            if factor<-100 then
                factor = -100
            end
            for k, o in ipairs(self.last_element) do
                self.automaton:transition_set_factor(o.object, factor)
            end
            self.render:draw({},{[self.last_element.index] = {0.85,0,0}})
--]]
        end
    end
end

---Handles mouse click in the editor.
--TODO
--@param self AutomatonEditor in which the operation is applied.
--@param event Mouse click event.
--@see AutomatonRender:select_element
--@see AutomatonRender:draw
--@see AutomatonEditor:edit_state
--@see AutomatonEditor:edit_transition
--@see Automaton:state_add
--@see Automaton:state_set_position
--@see Automaton:state_set_initial
--@see Automaton:state_get_marked
--@see Automaton:state_set_marked
--@see Automaton:state_remove
--@see Automaton:transition_remove
--@see Treeview:get_selected
--@see Automaton:transition_add
--@see Automaton:write_log
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
    elseif self.operation == 'state_n' then
        local id = self.automaton:state_add('N')
        self.automaton:state_set_position( id, x, y )
        self.render:draw({},{})
        elseif self.operation == 'state_y' then
        local id = self.automaton:state_add('Y')
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
--[[
        elseif self.last_element and self.last_element.type == 'transition' then
            local factor
            if self.last_element.source_obj~=self.last_element.target_obj then
                local proj, d, v
                --not selfloop
                d = {
                    x = x - (self.last_element.source_obj.x + self.last_element.target_obj.x)/2,
                    y = y - (self.last_element.source_obj.y + self.last_element.target_obj.y)/2,
                }
                v = {
                    --it is swapped on purpose
                    y = self.last_element.source_obj.x - self.last_element.target_obj.x,
                    x = -(self.last_element.source_obj.y - self.last_element.target_obj.y),
                }
                proj = scalar(v,v)/scalar(d,v)
                if proj>=0 then
                    factor = 2^proj/10
                else
                    factor = -2^-proj/10
                end
            else
                --selfloop
                factor = (self.last_element.source_obj.y - y - 2*self.last_element.source_obj.r)/3
                if factor<0 then
                    factor = 0
                end
            end
            if factor>100 then
                factor = 100
            end
            if factor<-100 then
                factor = -100
            end
            for k, o in ipairs(self.last_element) do
                o.object.factor = factor
            end
            self.render:draw({},{[self.last_element.index] = {0,0,0}})
            self.last_element = nil
        elseif element and element.type == 'transition' then
            self.last_element               = element
            self.render:draw({},{[element.index] = {0.85,0,0}})
--]]
        end
    elseif self.operation == 'move_motion' then
        if element and element.type == 'state' then
            self.last_element               = element
            self.element_move_motion_diff_x = math.floor(x) - element.object.x
            self.element_move_motion_diff_y = math.floor(y) - element.object.y
            self.render:draw({ [element.id] = {0.85,0,0} }, {})
        elseif element and element.type == 'transition' then
            self.last_element               = element
            self.render:draw({},{[element.index] = {0.85,0,0}})
        end
    elseif self.operation == 'initial' then
        if element and element.type == 'state' then
            self.automaton:state_set_initial( element.id, true )
            self.render:draw({},{})
        end
    elseif self.operation == 'marked' then
        if element and element.type == 'state' then
            if self.automaton:state_get_marked( element.id ) then
                self.automaton:state_set_marked( element.id, false )
            else
                self.automaton:state_set_marked( element.id, true )
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

    --self.automaton:write_log(function() ---???
    --  for tab_id, tab in self.gui.tab:ipairs() do
    --      self.last_element = nil
    --      self.render:draw({},{})
    --  end
    --end)
end

---Handles mouse release in the editor.
--TODO
--@param self AutomatonEditor in which the operation is applied.
--@see AutomatonRender:draw
--@see Automaton:write_log
function AutomatonEditor:drawing_area_release( )
    --self.automaton:write_log(function()
    --    self.last_element = nil
    --    self.render:draw({},{})
    --end)
end


---Toggles the controllable property of an event.
--Not necessary anymore due to the workspace
--If the event is controllable, sets it to uncontrollable, otherwise, sets it to controllable. Updates the list of events. Updates the screen.
--@param self Automaton editor in which the operation is applied.
--@param row_id Row of the event.
--@see Automaton:event_get_controllable
--@see Automaton:event_set_controllable
--@see AutomatonEditor:update_treeview_events
--@see AutomatonRender:draw
function AutomatonEditor:toggle_controllable( row_id )
    local event_id     = row_id+1
    if self.automaton:event_get_controllable( event_id ) then
        self.automaton:event_set_controllable( event_id, false )
    else
        self.automaton:event_set_controllable( event_id, true )
    end
    self:update_treeview_events()
    self.render:draw()
end

---Toggles the observable property of an event.
--If the event is observable, sets it to unobservable, otherwise, sets it to observable. Updates the list of events. Updates the screen.ss
--@param self Automaton editor in which the operation is applied.
--@param row_id Row of the event.
--@see Automaton:event_get_observable
--@see Automaton:event_set_observable
--@see AutomatonEditor:update_treeview_events
--@see AutomatonRender:draw
function AutomatonEditor:toggle_observable( row_id )
    local event_id = row_id+1
    if self.automaton:event_get_observable( event_id ) then
        self.automaton:event_set_observable( event_id, false )
    else
        self.automaton:event_set_observable( event_id, true )
    end
    self:update_treeview_events()
    self.render:draw()
end

function AutomatonEditor:toggle_shared( row_id )
    local event_id = row_id+1
    if self.automaton:event_get_shared( event_id ) then
        self.automaton:event_set_shared( event_id, false )
    else
        self.automaton:event_set_shared( event_id, true )
    end
    self:update_treeview_events()
    self.render:draw()
end

--END WORKSPACE NOT NECESSARY

---Changes the name of an event.
--Change the event name to 'new_name'. Updates the list of events. Updates the screen.
--@param self Automaton editor in which the operation is applied.
--@param row_id Row of the event.
--@param new_name New name of the event.
--@see Automaton:event_set_name
--@see AutomatonEditor:update_treeview_events
--@see AutomatonRender:draw
function AutomatonEditor:edit_event( row_id, new_name )
    local event_id = row_id+1
    ---NOT The correct place to check if name is valid, must be inside automaton or event class
    --local event = self.automaton.events:get(event_id)

    --new_name = new_name:gsub('[^%&%w%_]','')
    --if new_name:find('%&') then
    --    new_name = '&'
    --end

    if event_id and new_name then
        --Verify if new_name is unique
        --for _, ev in self.automaton.events:ipairs() do
        --  if ev.name == new_name then
        --      return
        --  end
        --end
        --if self.automaton:event_set_workspace(event_id, new_name) then
        --  self:update_treeview_events()
        --  self.render:draw()
        --  self.automaton:write_log(function()
        --      self:update_treeview_events()
        --      self.render:draw()
        --  end)
        --end
        self.automaton:event_set_name( event_id, new_name )
    end
    --TODO: The next two lines were removed, caller function execute it?
    self:update_treeview_events()
    self.render:draw()
end

---Adds a new event to the editor.
--Adds an event to the automaton. Updates the list of events.
--@param self Automaton editor in which the operation is applied.
--@see Automaton:add_event
--@see AutomatonEditor:update_treeview_events
function AutomatonEditor:add_event()
    self.automaton:event_add("new")
    self:update_treeview_events()
end

function AutomatonEditor:copy_events()
    local window      = gtk.Window.new(gtk.WINDOW_TOPLEVEL)
        local vbox        = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
            local automataCombobox = gtk.ComboBoxText.new()
            local hbox1        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                local btn_select_all   = gtk.Button.new_from_icon_name ( 'gtk-select-all' )
                --~ local btn_select_marked   = gtk.Button.new_from_icon_name ( 'gtk-index' )
                local btn_select_clear   = gtk.Button.new_from_icon_name ( 'gtk-clear' )
            local eventsScroll   = gtk.ScrolledWindow.new()
                local eventsTree        = Treeview.new( true )
            local hbox2        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                local btn_ok = gtk.Button.new_from_icon_name ( 'gtk-apply' )
                local btn_cancel = gtk.Button.new_from_icon_name ( 'gtk-cancel' )


    local selectedEventsDef
    local function updateEventsTree()
        eventsTree:clear_all()
        if selectedEventsDef then
            for k_eventDef, eventDef in ipairs( selectedEventsDef ) do
                eventsTree:add_row{ eventDef.use, eventDef.event.name, eventDef.event.controllable, eventDef.event.observable }
            end
        end
        eventsTree:update()
    end
    function toggle_event( user_data, row_id )
        local event_id = row_id+1
        if selectedEventsDef and selectedEventsDef[ event_id ] then
            selectedEventsDef[ event_id ].use = not selectedEventsDef[ event_id ].use
        end
        updateEventsTree()
    end
    local function readEvents()
        selectedEventsDef = {}
        local element  = self.elements:get( automataCombobox:get_active() + 1 )
        for k_event, event in element.events:ipairs() do
            selectedEventsDef[ k_event ] = { use = true, event = event }
        end
        updateEventsTree()
    end
    eventsTree:add_column_toggle("Select", 40, toggle_event)
    eventsTree:add_column_text("Event", 200)
    eventsTree:add_column_toggle("Con", 40)
    eventsTree:add_column_toggle("Obs", 40)

    for k_el, el in self.elements:ipairs() do
        automataCombobox:append_text( el:get('file_name') or "-x-" )
    end
    automataCombobox:connect('changed', readEvents )

    btn_select_all:connect('clicked', function()
        if selectedEventsDef then
            for k_eventDef, eventDef in ipairs( selectedEventsDef ) do
                eventDef.use = true
            end
            updateEventsTree()
        end
    end)
    btn_select_clear:connect('clicked', function()
        if selectedEventsDef then
            for k_eventDef, eventDef in ipairs( selectedEventsDef ) do
                eventDef.use = false
            end
            updateEventsTree()
        end
    end)
    btn_cancel:connect('clicked', window.destroy, window)
    btn_ok:connect('clicked', function()
        if selectedEventsDef then
            for k_eventDef, eventDef in ipairs( selectedEventsDef ) do
                if eventDef.use then
                    --just in case to avoid repetition
                    eventDef.use = false
                    --self.automaton:event_add( eventDef.event.name, eventDef.event.observable, eventDef.event.controllable, eventDef.event.refinement  )
                    self.automaton:event_add_clone( eventDef.event )
                end
            end
            self:update_treeview_events()
            updateEventsTree()
        end
    end)

    window:add( vbox )
        vbox:pack_start(automataCombobox, false, false, 0)
        vbox:pack_start(hbox1, false, false, 0)
            hbox1:pack_start(btn_select_all, true, true, 0)
            --~ hbox1:pack_start(btn_select_marked, true, true, 0)
            hbox1:pack_start(btn_select_clear, true, true, 0)
        vbox:pack_start(eventsScroll, true, true, 0)
            eventsScroll:add(eventsTree:build())
        vbox:pack_start(hbox2, false, false, 0)
            hbox2:pack_start(btn_ok, true, true, 0)
            hbox2:pack_start(btn_cancel, true, true, 0)

    window:set_modal( true )
    window:set(
        'title', "Add events from",
        'width-request', 350,
        'height-request', 500,
        'window-position', gtk.WIN_POS_CENTER,
        'icon-name', 'gtk-about'
    )

    window:connect('delete-event', window.destroy, window)
    --~ btnOk:connect('clicked', function()
        --~ for k_event, toggle in ipairs(events_toggle) do
            --~ if toggle then
                --~ if not transitions_map[k_event] then
                    --~ self.automaton:transition_add(source, target, events_map[k_event])
                --~ end
            --~ else
                --~ if transitions_map[k_event] then
                    --~ self.automaton:transition_remove(transitions_map[k_event])
                --~ end
            --~ end
        --~ end
--~ 
        --~ source.target_trans_factor[ target ] = scale:get_value()
--~ 
        --~ self.render:draw({},{})
        --~ --self.automaton:write_log(function() --???
        --~ --  self.render:draw({},{})
        --~ --end)
        --~ window:destroy()
    --~ end)
    window:show_all()
    automataCombobox:set('active', 0)
end

---Deletes an event from the editor.
--Removes the selected events from the automaton. Updates the list of events. Updates the screen.
--@param self Automaton editor in which the operation is applied.
--@see Treeview:get_selected
--@see Automaton:event_remove
--@see AutomatonEditor:update_treeview_events
--@see AutomatonRender:draw
--@see Automaton:write_log
function AutomatonEditor:delete_event()
    local events = self.treeview_events:get_selected()
    for _, event_id in ipairs( events ) do
        self.automaton:event_remove( event_id )
    end
    --for diff, event_id in ipairs( events ) do
    --  local event = self.automaton.events:get(event_id-diff+1)
    --  local wev1 = event.workspace
    --  wev1.automata[self.automaton] = nil
    --  self.automaton:event_remove( event_id-diff+1 )
    --end
    self:update_treeview_events()
    self.render:draw()
    --self.automaton:write_log(function()
    --  self:update_treeview_events()
    --  self.render:draw()
    --end)
end

---Changes radius factor.
--Sets the radius factor of the automaton.
--@param self Automaton Editor in which the operation is applied.
--@param factor New factor.
--@see Automaton:set_radius_factor
--@see AutomatonRender:draw
--@see Automaton:write_log
function AutomatonEditor:change_radius_factor(factor)
    self.automaton:set_radius_factor(factor)
    self.render:draw()
    --self.automaton:write_log(function()
    --    self.render:draw()
    --end)
end

---Renames all states with their ids.
--For each state, changes it's name do it's id.
--@param self Automaton Editor in which the operation is applied.
--@see Automaton:state_set_name
--@see AutomatonRender:draw
--@see Automaton:write_log
function AutomatonEditor:renumber_states()
    for k_state, state in self.automaton.states:ipairs() do
        self.automaton:state_set_name(k_state, k_state)
    end
    self.render:draw()
    --self.automaton:write_log(function()
    --    self.render:draw()
    --end)
end
