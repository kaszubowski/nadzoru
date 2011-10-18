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

--Info
local info = {
    {'coaccessible', "Coaccessible"},
    {'length', "Length  "},
}

function info.length( self )
    gtk.InfoDialog.showInfo(
        "Automanton States: " .. self.automaton.states:len() .. "\n" ..
        "Automanton Events: " .. self.automaton.events:len() .. "\n" ..
        "Automanton Transitions: " .. self.automaton.transitions:len() .. "\n"
    )
end

function info.coaccessible( self )
    if not self.automaton.coaccessible_calc then
        gtk.InfoDialog.showInfo("Coaccessible are NOT processed!")
        return
    end
    local no_ca_states = {}
    local count        = 0
    for k,v in self.automaton.states:ipairs() do
        if v.no_coaccessible then
            if count % 20 == 0 then
                no_ca_states[#no_ca_states + 1] = {}
            end
            table.insert( no_ca_states[#no_ca_states], tostring(k) ) --v.name or '???'
            count = count + 1
        end
    end
    local text_lines = {}
    for k, v in ipairs( no_ca_states ) do
        text_lines[#text_lines + 1] = table.concat( v, ", " )
    end

    gtk.InfoDialog.showInfo( string.format("No Coaccessible States: (found: %i)\n", count) .. table.concat( text_lines, ", \n" ) )
end

GraphvizSimulator = letk.Class( function( self, gui, automaton )
    Simulator.__super( self, automaton )

    self.image         = nil
    self.hbox          = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
        self.scrolled      = gtk.ScrolledWindow.new()
            self.drawing_area  = gtk.DrawingArea.new( )
        self.vbox_leftmenu = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
            self.treeview      = Treeview.new()
                :add_column_text("Events",100)
                :add_column_text("State",60)
                :bind_ondoubleclick(GraphvizSimulator.state_change, self)
            self.hbox_jumpstate = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                self.sb_statejump = gtk.SpinButton.new_with_range(1, automaton.states:len(), 1)
                self.btn_statejump = gtk.Button.new_with_mnemonic ("Jump to State")
            self.hbox_info = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                self.cbx_info = gtk.ComboBoxText.new()
                self.btn_info = gtk.Button.new_with_mnemonic ("Show Info")
            self.hbox_draw_deep = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                self.lbl_draw_deep = gtk.Label.new_with_mnemonic("Deep")
                self.sb_draw_deep = gtk.SpinButton.new_with_range(1, 20, 1)
                --self.btn_statejump = gtk.Button.new_with_mnemonic ('Jump to State')

    for k, v in ipairs( info ) do
        self.cbx_info:append_text( v[2] )
    end
    self.btn_info:connect('clicked', self.info, self)
    if #info > 0 then
        self.cbx_info:set('active', 0)
    end

    self.scrolled:add_with_viewport(self.drawing_area)
    self.sb_statejump:set_digits( 0 )
    self.sb_draw_deep:set_digits( 0 )


    self.hbox:pack_start( self.vbox_leftmenu, false, false, 0 )
        self.vbox_leftmenu:pack_start( self.treeview:build(), true, true, 0 )
        self.vbox_leftmenu:pack_start( self.hbox_jumpstate, false, false, 0 )
            self.hbox_jumpstate:pack_start( self.sb_statejump, true, true, 0 )
            self.hbox_jumpstate:pack_start( self.btn_statejump, false, false, 0 )
        self.vbox_leftmenu:pack_start( self.hbox_info, false, false, 0 )
            self.hbox_info:pack_start( self.cbx_info, true, true, 0 )
            self.hbox_info:pack_start( self.btn_info, false, false, 0 )
        self.vbox_leftmenu:pack_start( self.hbox_draw_deep, false, false, 0 )
            self.hbox_draw_deep:pack_start( self.lbl_draw_deep, false, false, 0 )
            self.hbox_draw_deep:pack_start( self.sb_draw_deep, true, true, 0 )
    self.hbox:pack_start( self.scrolled, true, true, 0 )

    gui:add_tab( self.hbox, 'SG ' .. (automaton:get('file_name') or '-x-'), self.destroy, self )

    --Build
    self:update_treeview()
    self:draw()
    self.drawing_area:connect('draw', self.drawing_area_expose, self )
    self.btn_statejump:connect('clicked', self.statejump_cb, self)
end, Simulator )

function GraphvizSimulator.info( self )
    local fn_name = info[ self.cbx_info:get_active() + 1 ][1]
    info[fn_name]( self )
end

function GraphvizSimulator.statejump_cb( self )
    local st = self.sb_statejump:get_value()
    self.state = st
    self:update_treeview()
    self:draw()
end

function GraphvizSimulator.state_change(self, ud_treepath, ud_treeviewcolumn)
    local state_id, pos2   = self.treeview:get_selected( 2 )
    if not state_id then return true end
    self:change_state( state_id )
    self:update_treeview()
    self:draw()
    return true
end

function GraphvizSimulator:drawing_area_expose( cr )
    if not self.image then return false end

    cr = cairo.Context.wrap(cr)
    local iWidth, iHeight = self.image:get_width(), self.image:get_height()

    local surface = cairo.ImageSurface.create(cairo.FORMAT_ARGB32, iWidth, iHeight)
    local ic      = cairo.Context.create(surface)
    ic:rectangle(0, 0, iWidth, iHeight)
    ic:fill()

    cr:set_source_surface(self.image, 10, 10)
    cr:mask_surface(surface, 10, 10)
    surface:destroy()
    cr:destroy()
    ic:destroy()

    return false
end

function GraphvizSimulator:draw()
    local deep         = self.sb_draw_deep:get_value()
    local backwaredeep = true
    local dot  = self:generate_graphviz( deep, backwaredeep )
    if dot then
        local file_dot = io.open("temp.dot", "w+")
        file_dot:write( dot )
        file_dot:close()
        os.execute('dot -Tpng -otemp.png temp.dot')
        os.execute('rm temp.dot')
    end
    if self.image then
        self.image:destroy()
    end
    self.image  = cairo.ImageSurface.create_from_png("temp.png")
    os.execute('rm temp.png')
    self.drawing_area:set_size_request(self.image:get_width(), self.image:get_height())
    self.drawing_area:queue_draw()
end

function GraphvizSimulator:update_treeview()
    local events   = self:get_current_state_events_info(  )
    self.treeview:clear_data()

    for ch_ev, ev in ipairs( events ) do
        self.treeview:add_row{ ev.event.name, ev.target_index  }
    end
    self.treeview:update()
end

function get_state_color( s, current )
    if current then
        if s.no_coaccessible and s.no_accessible then return 'darkyellow'
        elseif s.no_coaccessible then return 'darkgreen'
        elseif s.no_accessible then return 'blueviolet'
        else return 'gray' end
    else
        if s.no_coaccessible and s.no_accessible then return 'yellow'
        elseif s.no_coaccessible then return 'green'
        elseif s.no_accessible then return 'blue'
        else return 'black' end
    end
end

function GraphvizSimulator:generate_graphviz( deep, backwaredeep )
    deep  = deep or 1
    local state_index, node            = self:get_current_state()
    local used, list, list_p, list_tam = { [state_index] = {} }, { state_index }, 1, nil
    local graphviz_nodes = {
        [[    INICIO [shape = box, height = .001, width = .001, color = white, fontcolor = white, fontsize = 1];]],
        string.format( [[    S%i [shape=%s, color = %s];]],
            state_index,
            node.marked and [[doublecircle, style="bold"]] or [[circle]],
            get_state_color( node, true )
        ),
    }
    local graphviz_edges = {}
    if node.initial then
        graphviz_edges[#graphviz_edges +1] = string.format([[    INICIO -> S%i;]],
            state_index)
    end

    local first = true

    function add_node_transition( source, event, target, insert_source )
        event_index  = self.event_map[ event ]
        target_index = self.state_map[ target ]
        source_index = self.state_map[ source ]
        if not used[target_index] then
                used[target_index] = {}
                list[#list +1]     = target_index

                graphviz_nodes[#graphviz_nodes +1] = string.format(
                    [[    S%i [shape=%s, color = %s];]],
                    target_index,
                    target.marked and [[doublecircle, style="bold"]] or [[circle]],
                    get_state_color( target )
                )
                if target.initial then
                    graphviz_edges[#graphviz_edges +1] = string.format([[    INICIO -> S%i;]], target_index)
                end
        end
        if not used[source_index] then
                used[source_index] = {}
                if insert_source then
                    list[#list +1] = source_index
                end

                graphviz_nodes[#graphviz_nodes +1] = string.format(
                    [[    S%i [shape=%s, color = %s];]],
                    source_index,
                    source.marked and [[doublecircle, style="bold"]] or [[circle]],
                    get_state_color( source )
                )
                if source.initial then
                    graphviz_edges[#graphviz_edges +1] = string.format([[    INICIO -> S%i;]], source_index)
                end
        end

        if not used[source_index][event_index] then
            used[source_index][event_index] = true
            graphviz_edges[#graphviz_edges +1] = string.format(
                [[    S%i -> S%i [label="%s", color = %s, style = %s];]],
                source_index,--list[ source_index ],
                target_index,
                event.name,
                event.controllable and 'black' or 'red',
                first and 'bold' or 'dashed' --solid
            )
        end
    end


    while deep > 0 do
        deep = deep - 1
        list_tam = #list
        for i = list_p, list_tam do
            local current = self.automaton.states:get( list[i] )

            for event, target_list in pairs( current.event_target ) do
                for target, _ in pairs( target_list ) do
                    add_node_transition( current, event, target, false)
                end
            end
            first = false
            if backwaredeep then
                for event, sources in pairs( current.event_source ) do
                    for source, _ in pairs( sources ) do
                        add_node_transition( source, event, current, true)
                    end
                end
            end
        end
        list_p = list_tam + 1
    end

    local dot = [[
digraph test123 {
    rankdir=LR;
]] ..
    table.concat( graphviz_nodes, '\n') .. '\n' ..
    table.concat( graphviz_edges, '\n') .. '\n' ..
    [[}]]

    return dot
end

function GraphvizSimulator:destroy()
    self:trigger('destroy')
    if self.image then
        self.image:destroy()
    end
end
