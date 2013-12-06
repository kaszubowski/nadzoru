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

Gui = letk.Class( function( self )
    self.note         = gtk.Notebook.new()
    self.tab          = letk.List.new()

    self.window       = gtk.Window.new(gtk.WINDOW_TOPLEVEL)
    self.vbox         = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)

    self.menubar      = gtk.MenuBar.new()

    --~ self.actions   = {}
    self.menu      = {}
    self.menu_item = {}

    --Menu
    self:append_menu('file', "_File")
    self:append_menu_item('file', "Quit nadzoru", "Quit nadzoru", 'gtk-quit', gtk.main_quit )
    self:append_menu_item('file', "Remove Tab", "Remove The Active Tab", 'gtk-delete', function( data ) data.gui:remove_current_tab() end, self )

    --** Packing it! (vbox) **--
    self.vbox:pack_start(self.menubar, false, false, 0)
    self.vbox:pack_start(self.note   , true, true, 0)
    self.window:add(self.vbox)

    --** window defines **--
    self.window:set("title", "nadzoru", "width-request", 800,
        "height-request", 600, "window-position", gtk.WIN_POS_CENTER,
        "icon-name", "gtk-about")

    self.window:connect("delete-event", gtk.main_quit)

    self.note:set('enable-popup', true, 'scrollable', true, 'show-border', true)
end, Object )

function Gui:run()
    self.window:show_all()
end

function Gui:append_menu( name, caption )
    self.menu[name] = gtk.Menu.new()
    local menu_item = gtk.MenuItem.new_with_mnemonic( caption )
    menu_item:set_submenu( self.menu[name] )
    self.menubar:append( menu_item )
    self.window:show_all()

    self.menu_item[name] = {}

    return menu_item
end

function Gui:prepend_menu( name, caption )
    self.menu[name] = gtk.Menu.new()
    local menu_item = gtk.MenuItem.new_with_mnemonic( caption )
    menu_item:set_submenu( self.menu[name] )
    self.menubar:prepend( menu_item )
    self.window:show_all()

    self.menu_item[name] = {}

    return menu_item
end

function Gui:append_sub_menu( parent, name, caption )
    self.menu[name] = gtk.Menu.new()
    local menu_item = gtk.MenuItem.new_with_mnemonic( caption )
    menu_item:set_submenu( self.menu[name] )
    self.menu[parent]:append( menu_item )
    self.window:show_all()

    self.menu_item[name] = {}

    return menu_item
end

function Gui:prepend_sub_menu( parent, name, caption )
    self.menu[name] = gtk.Menu.new()
    local menu_item = gtk.MenuItem.new_with_mnemonic( caption )
    menu_item:set_submenu( self.menu[name] )
    self.menu[parent]:prepend( menu_item )
    self.window:show_all()

    self.menu_item[name] = {}

    return menu_item
end

function Gui:append_menu_separator( name )
    local separator = gtk.SeparatorMenuItem.new()
    self.menu[name]:append( separator )
end

function Gui:prepend_menu_separator( name )
    local separator = gtk.SeparatorMenuItem.new()
    self.menu[name]:prepend( separator )
end

function Gui:remove_menu( menu )
    self.menubar:remove( menu )
    self.menu_item[name] = nil
end

function Gui:append_menu_item( menu_name, caption, hint, icon, callback, param, ... )
    local menu_item
    if not icon then
        menu_item = gtk.MenuItem.new_with_label( caption )
    else
        menu_item = gtk.MenuItem.new_with_label( caption ) --TODO
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
    if not icon then
        menu_item = gtk.MenuItem.new_with_label( caption )
    else
        menu_item = gtk.MenuItem.new_with_label( caption ) --TODO
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

    return note
end

function Gui:remove_current_tab( )
    local id = self.note:get_current_page()
    if id then
        self.note:remove_page( id )
        local destroy = self.tab:remove( id + 1 )
        if destroy and destroy.destroy_callback then
            destroy.destroy_callback( destroy.param )
        end
    end
    self.window:show_all()
end

function Gui:set_tab_page_title( widget, title )
    local page_label = self.note:get_tab_label( widget )

    page_label:set_text( title )

    self.window:show_all()
end

