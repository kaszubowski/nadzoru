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
Gui          = {}
Gui_MT = { __index = Gui }

setmetatable( Gui, Object_MT )

---
-- Constructor
--
-- @return A new Gui instance
function Gui.new()
    local self     = Object.new()
    setmetatable( self, Gui_MT )

    self.note         = gtk.Notebook.new()
    self.tab          = List.new()

    self.window       = gtk.Window.new(gtk.WINDOW_TOPLEVEL)
    self.vbox         = gtk.VBox.new(false, 0)

    self.menubar      = gtk.MenuBar.new()
    -- self.toolbar      = gtk.Toolbar.new()
    self.hbox         = gtk.HBox.new(false, 0)
    self.statusbar    = gtk.Statusbar.new()

    self.context      = self.statusbar:get_context_id("default")
    self.statusbar:push(self.context, "Statusbar message")

    self.actions   = {}
    self.menu      = {}
    self.menu_item = {}

    --Actions
    self:add_action('quit', nil, "Quit nadzoru", 'gtk-quit', gtk.main_quit )
    self:add_action('remove_current_tab', "Remove Tab", "Remove The Active Tab", 'gtk-delete', function( data ) data.gui:remove_current_tab() end, self )

    --ToolBar
    --~ self:add_toolbar('quit')
    --~ self:add_toolbar('remove_current_tab')

    --Menu
    self:append_menu('file', "_File")
    self:append_menu_item('file', 'quit')

    --** Packing it! (vbox) **--
    self.vbox:pack_start(self.menubar, false, false, 0)
    --self.vbox:pack_start(self.toolbar, false, false, 0)
    self.vbox:pack_start(self.note   , true, true, 0)
    self.vbox:pack_start(self.statusbar, false, false, 0)
    self.window:add(self.vbox)

    --** window defines **--
    self.window:set("title", "nadzoru - simulator", "width-request", 800,
        "height-request", 600, "window-position", gtk.WIN_POS_CENTER,
        "icon-name", "gtk-about")

    self.window:connect("delete-event", gtk.main_quit)

    return self
end

function Gui:run()
    self.window:show_all()
end

function Gui:add_action(name, caption, hint, icon, callback, param)
    self.actions[name] = gtk.Action.new( name, caption, hint, icon)
    self.actions[name]:connect("activate", callback, { gui = self, param = param })
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

function Gui:remove_menu( menu )
    self.menubar:remove( menu )
    self.menu_item[name] = nil
end

function Gui:append_menu_item( menu_name, action_name, ...  )
    local menu_item

    if type( action_name ) == 'string' then
        menu_item = self.actions[action_name]:create_menu_item()
    elseif type( action_name ) == 'table' then
        if action_name.type and action_name.type == 'check' then
            menu_item = gtk.CheckMenuItem.new_with_label( action_name.caption or '?' )
            menu_item:connect("activate", action_name.fn, { gui = self, param = action_name.param })
        elseif action_name.type and action_name.type == 'radio' then
            local ra = gtk.RadioAction.new( '', action_name.caption or '?' )
            if self.menu_item[menu_name].radioaction then
                ra:set( 'group', self.menu_item[menu_name].radioaction )
            end
            self.menu_item[menu_name].radioaction = ra
            menu_item = ra:create_menu_item()
            ra:connect("toggled", action_name.fn, { gui = self, param = action_name.param })
        else
            menu_item = gtk.MenuItem.new_with_label( action_name.caption or '?' )
            menu_item:connect("activate", action_name.fn, { gui = self, param = action_name.param })
        end
    else
        return
    end
    self.menu[menu_name]:append ( menu_item )
    self.menu_item[menu_name][ #self.menu_item[menu_name] +1] = menu_item
    self.window:show_all()
    if (...) then
        return menu_item, self:append_menu_item( menu_name, ... )
    end

    return menu_item
end

function Gui:prepend_menu_item( menu_name, action_name, ...  )
    local menu_item

    if type( action_name ) == 'string' then
        menu_item = self.actions[action_name]:create_menu_item()
    elseif type( action_name ) == 'table' then
        if action_name.type and action_name.type == 'check' then
            menu_item = gtk.CheckMenuItem.new_with_label( action_name.caption or '?' )
        elseif action_name.type and action_name.type == 'radio' then
            local ra = gtk.RadioAction.new( '', "Automaton" )
            if self.menu_item[menu_name].radioaction then
                ra:set( 'group', self.menu_item[menu_name].radioaction )
            end
            self.menu_item[menu_name].radioaction = ra
            menu_item = ra:create_menu_item()
        else
            menu_item = gtk.MenuItem.new_with_label( action_name.caption or '?' )
        end
        menu_item:connect("activate", action_name.fn, { gui = self, param = action_name.param })
    else
        return
    end
    self.menu[menu_name]:prepend ( menu_item )
    self.menu_item[menu_name][ #self.menu_item[menu_name] +1] = menu_item
    self.window:show_all()
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

--~ function Gui:add_toolbar( action_name, ... )
    --~ self.toolbar:add( self.actions[action_name]:create_tool_item() )
    --~ self.window:show_all()
    --~ if (...) then
        --~ self:add_toolbar( ... )
    --~ end
--~ end

function Gui:add_tab( widget, title, destroy_callback, param )
    local note =  self.note:insert_page( widget, gtk.Label.new(title), -1)
    self.tab:add({ destroy_callback = destroy_callback, param = param }, note + 1)
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

