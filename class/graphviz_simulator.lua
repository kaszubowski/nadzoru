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

GraphvizSimulator = {}
GraphvizSimulator_MT = { __index = GraphvizSimulator }

setmetatable( GraphvizSimulator, Simulator_MT )

function GraphvizSimulator.new( gui, automaton )
    local self = Simulator.new( gui, automaton )
    setmetatable( self, GraphvizSimulator_MT )

    self.image     = nil

    self.scrolled     = gtk.ScrolledWindow.new()
    self.drawing_area = gtk.DrawingArea.new( )
    self.treeview     = Treeview.new()
        :add_column_text("Eventos",150)
        :bind_ondoubleclick(GraphvizSimulator.state_change, self)
    self.hbox         = gtk.HBox.new(false, 0)

    self.scrolled:add_with_viewport(self.drawing_area)
    self.hbox:pack_start( self.treeview:build(), false, false, 0 )
    self.hbox:pack_start( self.scrolled, true, true, 0 )
    gui:add_tab( self.hbox, 'SG ' .. (automaton:get_info('short_file_name') or '-x-'), self.destroy, self )

    --Build
    self:update_treeview()
    self:draw()
    self.drawing_area:connect("expose-event", self.drawing_area_expose, self )

    return self
end

function GraphvizSimulator.state_change(self, ud_treepath, ud_treeviewcolumn)
    local event_name  = self.treeview:get_select( 1 )
    if not event_name then return true end
    local ev_num = self.event_map[ event_name ]
    self:execute_event( ev_num )
    self:update_treeview()
    self:draw()
    return true
end

function GraphvizSimulator:drawing_area_expose()
    if not self.image then return false end

    local cr = gdk.cairo_create( self.drawing_area:get_window() )
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
    local deep = 2
    local dot  = self:generate_graphviz( deep )
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
        self.treeview:add_row{ ev.event.name }
    end
    self.treeview:update()
end

function GraphvizSimulator:generate_graphviz( forward_deep )
    local state, node = self:get_current_state()
    local used, list, list_p, list_tam = { [state] = {} }, { state }, 1, nil
    local graphviz_nodes = {
        [[    INICIO [shape = box, height = .001, width = .001, color = white, fontcolor = white, fontsize = 1];]],
        string.format(
            [[    S%i [shape=%s, color = blue];]],
            state-1,
            node.marked and [[doublecircle, style="bold"]] or [[circle]]
        ),
    }
    local graphviz_edges = {}
    if node.initial then
        graphviz_edges[#graphviz_edges +1] = string.format([[    INICIO -> S%i;]],
            state-1)
    end

    local first = true

    while forward_deep > 0 do
        forward_deep = forward_deep - 1
        list_tam = #list
        for i = list_p, list_tam do
            for num_event, num_target in pairs( self.automaton.states[ list[i] ].event_target ) do
                if not used[num_target] then
                    used[num_target] = {}
                    list[#list +1]   = num_target
                    local target_node = self.automaton.states[num_target]
                    graphviz_nodes[#graphviz_nodes +1] = string.format(
                        [[    S%i [shape=%s];]],
                        num_target-1,
                        target_node.marked and [[doublecircle, style="bold"]] or [[circle]]
                    )
                    if target_node.initial then
                        graphviz_edges[#graphviz_edges +1] = string.format([[    INICIO -> S%i;]], num_target-1)
                    end
                end
                if not used[num_target][num_event] then
                    used[num_target][num_event] = true
                    graphviz_edges[#graphviz_edges +1] = string.format(
                        [[    S%i -> S%i [label="%s", color = %s, style = %s];]],
                        list[i]-1,
                        num_target-1,
                        self.automaton.events[num_event].name,
                        self.automaton.events[num_event].controllable and 'black' or 'red',
                        first and 'bold' or 'dashed' --solid
                    )
                end
            end
        end
        list_p = list_tam + 1
        first = false
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

