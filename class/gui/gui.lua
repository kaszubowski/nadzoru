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

    Copyright (C) 2011-2012 Yuri Kaszubowski Lopes, Eduardo Harbs, Andre Bittencourt Leal and Roberto Silvio Ubertino Rosso Jr.
    Copyright (C) 2013 Yuri Kaszubowski Lopes
--]]

--[[
module "Gui"
--]]
--~ Gui = letk.Class( function( self, fn, data )
Gui = letk.Class( function( self )
    
    self.tab          = letk.List.new()

    self.window       = gtk.Window.new(gtk.WINDOW_TOPLEVEL)
        self.vbox         = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
            self.menubar      = gtk.MenuBar.new()
        self.note         = gtk.Notebook.new()
        --self.statusbar    = gtk.Statusbar.new()

    --~ self.actions   = {}
    self.menu      = {}
    self.menu_item = {}

    --self.context      = self.statusbar:get_context_id("default")
    --self.statusbar:push(self.context, "Statusbar message")

    --Menu
    self:append_menu('file', "_File")
    self:append_menu_item('file', "_Close Tab", "Close The Active Tab", 'gtk-delete', function( data ) data.gui:remove_current_tab() end, self )
    self:append_menu_separator('file')
    self:append_menu_item('file', "_Quit nadzoru", "Quit nadzoru", 'gtk-quit', gtk.main_quit )




    --[[
    -- ** Workspace ** --
    self.level_box = gtk.ComboBoxText.new()
    local level_list = get_list('level')
    for _,t in ipairs(level_list) do
        self.level_box:append_text(t)
    end
    self.level_box:set('active', 0)
    
    local atm_flag = false
    self.level_box:connect('changed', function(data)
        local editor
        if not atm_flag then
            editor = self:get_current_content()
        end
        fn.change_level(data, level_list[self.level_box:get('active')+1], editor and editor.automaton)
    end, data)
    
    self.note:connect('switch-page', function(data, _, tab)
        atm_flag = true
        local editor = self.tab:get(tab+1) and self.tab:get(tab+1).content
        if editor and editor.automaton then
            self.level_box:set('active', level_list[editor.automaton.level])
        end
        atm_flag = false
    end, data)
    
    self.treeview_events      = Treeview.new( true )
    self.btn_to_automaton     = gtk.Button.new()
    self.ta_box               = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    self.img_to_automaton     = gtk.Image.new_from_file( './images/icons/to_automaton.png' )
    self.ta_box:pack_start(self.img_to_automaton, true, true, 0)
    self.btn_to_automaton:add(self.ta_box)
    
    self.btn_add_event        = gtk.Button.new_from_stock( 'gtk-add' )
    self.btn_delete_event     = gtk.Button.new_from_stock( 'gtk-delete' )
    self.btn_to_automaton:connect('clicked', fn.to_automaton, data )
    self.btn_add_event:connect('clicked', fn.add_event, data )
    self.btn_delete_event:connect('clicked', fn.delete_event, data )
    
    self.treeview_events:add_column_text("Events",100, fn.edit_event, data)
    self.treeview_events:add_column_toggle("Con", 50, fn.toggle_controllable, data )
    self.treeview_events:add_column_toggle("Obs", 50, fn.toggle_observable, data )
    self.treeview_events:add_column_text("Ref", 50, fn.edit_refinement, data )
    
    self.treeview_events.columns[1]:set('sizing', gtk.TREE_VIEW_COLUMN_AUTOSIZE)
    self.treeview_events.columns[2]:set('sizing', gtk.TREE_VIEW_COLUMN_AUTOSIZE)
    self.treeview_events.columns[3]:set('sizing', gtk.TREE_VIEW_COLUMN_AUTOSIZE)
    self.treeview_events.render[2]:set('width', 32)
    self.treeview_events.render[3]:set('width', 32)
    
    self.event_box:pack_start( gtk.Label.new_with_mnemonic('Level:'), false, false, 0 )
    self.event_box:pack_start( self.level_box, false, false, 0 )
    self.event_box:pack_start( self.treeview_events:build(), true, true, 0 )
    self.event_box:pack_start( self.btn_to_automaton, false, false, 0 )
    self.event_box:pack_start( self.btn_add_event, false, false, 0 )
    self.event_box:pack_start( self.btn_delete_event, false, false, 0 )
    
    self.treeview_events.scrolled:set('width-request', 165)
    self.treeview_events.render[1]:set('width', 36)
    self.treeview_events:update()
   --]]




    --** Packing it! (vbox) **--
    self.vbox:pack_start(self.menubar, false, false, 0)
    self.vbox:pack_start(self.note   , true, true, 0)
    self.window:add(self.vbox)

    --** window defines **--
    self.window:set("title", "nadzoru", "width-request", 1000,
        "height-request", 800, "window-position", gtk.WIN_POS_CENTER,
        "icon-name", "gtk-about")

    self.window:connect("delete-event", gtk.main_quit)

    self.note:set('enable-popup', true, 'scrollable', true, 'show-border', true)
end, Object )

---Refreshs the Gui.
--Refreshs the gtk window.
--@param self Gui in which the operation is applied.
function Gui:run()
    self.window:show_all()
end


---Appends a new menu to the gui.
--TODO
--@param self Gui in which the menu is added.
--@param name Name of the menu.
--@param caption TODO
--@return New menu.
function Gui:append_menu( name, caption )
    self.menu[name] = gtk.Menu.new()
    local menu_item = gtk.MenuItem.new_with_mnemonic( caption )
    menu_item:set_submenu( self.menu[name] )
    self.menubar:append( menu_item )
    self.window:show_all()

    self.menu_item[name] = {}

    return menu_item
end

---Prepends a new menu to the gui.
--TODO
--@param self Gui in which the menu is added.
--@param name Name of the menu.
--@param caption TODO
--@return New menu.
function Gui:prepend_menu( name, caption )
    self.menu[name] = gtk.Menu.new()
    local menu_item = gtk.MenuItem.new_with_mnemonic( caption )
    menu_item:set_submenu( self.menu[name] )
    self.menubar:prepend( menu_item )
    self.window:show_all()

    self.menu_item[name] = {}

    return menu_item
end

---Appends a new submenu to a menu.
--TODO
--@param self Gui in which the submenu is added.
--@param parent Parent menu in which the submenu is added.
--@param name Name of the menu.
--@param caption TODO
--@return New menu.
function Gui:append_sub_menu( parent, name, caption )
    self.menu[name] = gtk.Menu.new()
    local menu_item = gtk.MenuItem.new_with_mnemonic( caption )
    menu_item:set_submenu( self.menu[name] )
    self.menu[parent]:append( menu_item )
    self.window:show_all()

    self.menu_item[name] = {}

    return menu_item
end

---Prepend a new submenu to a menu.
--TODO
--@param self Gui in which the submenu is added.
--@param parent Parent menu in which the submenu is added.
--@param name Name of the menu.
--@param caption TODO
--@return New menu.
function Gui:prepend_sub_menu( parent, name, caption )
    self.menu[name] = gtk.Menu.new()
    local menu_item = gtk.MenuItem.new_with_mnemonic( caption )
    menu_item:set_submenu( self.menu[name] )
    self.menu[parent]:prepend( menu_item )
    self.window:show_all()

    self.menu_item[name] = {}

    return menu_item
end

---Appends a separator line to a menu.
--Creates a separator and appends it to the menu 'name'.
--@param self Gui in which the separator is created.
--@param name Name of the menu in which th separator is added.
function Gui:append_menu_separator( name )
    local separator = gtk.SeparatorMenuItem.new()
    self.menu[name]:append( separator )
end

---Prepend a separator line to a menu.
--Creates a separator and prepends it to the menu 'name'.
--@param self Gui in which the separator is created.
--@param name Name of the menu in which th separator is added.
function Gui:prepend_menu_separator( name )
    local separator = gtk.SeparatorMenuItem.new()
    self.menu[name]:prepend( separator )
end

---Removes a menu from the gui.
--@param self Gui in which the menu is removed.
--@param menu Menu to be removed.
function Gui:remove_menu( name )
    self.menubar:remove( name )
    self.menu_item[name] = nil
end

---get image from file or icon-name
function Gui:getImage( name )
    local f = io.open( name, 'r' )
    if f then
        return gtk.Image.new_from_file( name )
    else 
        return gtk.Image.new_from_icon_name( name )
    end
end

function Gui:append_menu_item( menu_name, caption, hint, icon, callback, param, ... )
    local menu_item
    if icon then
        local box = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            local image = self:getImage( icon )
            local label = gtk.Label.new()
        label:set_markup_with_mnemonic( caption )
        label:set_justify( gtk.JUSTIFY_LEFT )
        box:pack_start( image, false, false, 0 )
        box:pack_start( label, false, false, 5 )
        menu_item   = gtk.MenuItem.new()
        menu_item:add( box )
    else
        menu_item = gtk.MenuItem.new_with_mnemonic( caption )
    end
    menu_item:connect('activate', callback, { gui = self, param = param } )
    
    if self.menu[menu_name] then
        self.menu[menu_name]:append ( menu_item )
        self.menu_item[menu_name][ #self.menu_item[menu_name] +1] = menu_item
        self.window:show_all()
    end
    if (...) then
        return menu_item, self:append_menu_item( menu_name, ... )
    end

    return menu_item
end

function Gui:prepend_menu_item( menu_name, caption, hint, icon, callback, param, ... )
    local menu_item
    if icon then
        local box = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            local image = self:getImage( icon )
            local label = gtk.Label.new()
        label:set_markup_with_mnemonic( caption )
        label:set_justify( gtk.JUSTIFY_LEFT )
        box:pack_start( image, false, false, 0 )
        box:pack_start( label, false, false, 5 )
        menu_item   = gtk.MenuItem.new()
        menu_item:add( box )
    else
        menu_item = gtk.MenuItem.new_with_mnemonic( caption )
    end
    menu_item:connect('activate', callback, { gui = self, param = param } )
    
    if self.menu[menu_name] then
        self.menu[menu_name]:prepend ( menu_item )
        self.menu_item[menu_name][ #self.menu_item[menu_name] +1] = menu_item
        self.window:show_all()
    end
    if (...) then
        return menu_item, self:prepend_menu_item( menu_name, ... )
    end

    return menu_item
end

---TODO
--TODO
--@param self Gui in which the operation is applied.
--@param menu_name TODO
--@param menu_item TODO
function Gui:remove_menu_item( menu_name, menu_item )
    self.menu[menu_name]:remove( menu_item )
    local pos
    for ch, val in ipairs( self.menu_item[menu_name] ) do
        if val == menu_item then
            pos = ch
        end
    end
    if pos then
        local last = #self.menu_item[menu_name]
        self.menu_item[menu_name][pos] = nil
        self.menu_item[menu_name][pos] = self.menu_item[menu_name][last]
    end
end

function Gui:add_tab( widget, title, destroy_callback, param )
    local note =  self.note:insert_page( widget, gtk.Label.new(title), -1)
    self.tab:add({ destroy_callback = destroy_callback, param = param, widget = widget }, note + 1)
    self.window:show_all()
    self.note:set_current_page(note)

    return note
end

---Closes current selected tab.
--Finds the id of the current tab and removes it.
--@param self Gui in which the operation is applied.
function Gui:remove_current_tab( )
    local id = self.note:get_current_page()
    self:remove_tab(id)
end

---Closes a tab.
--Finds the tab represented by id, removes it from the gtk notebook, calls it's destroy callback with it's destroy parameter and refreshs the window.
--@param self Gui in which the operation is applied.
--@param id Id of the tab.
function Gui:remove_tab( id )
    if id then
        self.note:remove_page( id )
        local destroy = self.tab:remove( id + 1 )
        if destroy and destroy.destroy_callback then
            destroy.destroy_callback( destroy.param )
        end
    end
    self.window:show_all()
end

---Changes the name of a tab.
--TODO
--@param self Gui in which the operation is applied.
--@param widget TODO
--@param title New name of the tab.
function Gui:set_tab_page_title( widget, title )
    local page_label = self.note:get_tab_label( widget )
    page_label:set_text( title )

    self.window:show_all()
end

