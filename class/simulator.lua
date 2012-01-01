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

Simulator = letk.Class( function( self, automaton )
    Object.__super( self )
    self.gui            = gui
    self:automaton_load( automaton )
end, Object )

function Simulator:automaton_load( automaton )
    self.automaton        = automaton or self.automaton
    self.event_name_map   = {}
    self.event_map        = {}
    self.state_map        = {}
    self.current_state_id = self.automaton.initial or 1

    --Events
    for event_index, event in automaton.events:ipairs() do
        self.event_name_map[event.name] = event_index
        self.event_map[event]           = event_index
        self.event_map[event_index]     = event
    end

    --States
    for state_index, state in automaton.states:ipairs() do
        self.state_map[state]       = state_index
        self.state_map[state_index] = state
    end
end

function Simulator:get_current_state()
    --~ local node  = self.automaton.states:get( self.current_state_id )
    local node  = self.state_map[ self.current_state_id ]
    return self.current_state_id, node
end

function Simulator:get_current_state_info()
    local state_index, node = self:get_current_state()
    return {
        state_index   = state_index,
        name          = node.name,
        initial       = node.initial,
        marked        = node.marked,
    }
end

function Simulator:get_current_state_events_info()
    local state_index, node = self:get_current_state()
    local events            = {}
    for event_index, event in self.automaton.events:ipairs() do
        if node.event_target[ event ] then
            for target, _ in pairs( node.event_target[ event ] ) do
                events[#events +1] = {
                    event        = event,
                    event_index  = event_index,
                    target_state = target,
                    target_index = self.state_map[target],
                    source_state = node,
                    source_index = self.state_map[node],
                }
            end
        end
    end

    return events
end

function Simulator:change_state( state_index )
    state_index = tonumber( state_index )
    if not state_index then return end

    self.current_state_id = state_index
end


