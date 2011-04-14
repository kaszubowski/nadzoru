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

Simulator = {}
Simulator_MT = { __index = Simulator }

setmetatable( Simulator, Object_MT )

function Simulator.new( gui, automaton )
    local self = Object.new()
    setmetatable( self, Simulator_MT )
    self.gui       = gui
    self.automaton = automaton
    self.event_map = {}
    self.state     = self.automaton.initial

    --Events
    for ch_ev, ev in ipairs( automaton.events ) do
        self.event_map[ev.name] = ch_ev
    end

    return self
end

function Simulator:get_current_state()
    local node  = self.automaton.states[self.state]
    return self.state, node
end

function Simulator:get_current_state_info()
    local state, node = self:get_current_state()
    return {
        state   = state,
        name    = node.name,
        initial = node.initial,
        marked  = node.marked,
    }
end

function Simulator:get_current_state_events_info()
    local state, node = self:get_current_state()
    local events = {}
    for i in ipairs( self.automaton.events ) do
        if node.event_target[i] then
            local ev = self.automaton.events[i]
            local ts = self.automaton.states[ node.event_target[i] ]
            events[#events +1] = {
                target_state_num = node.event_target[i],
                num_ev           = i,
                event            = ev,
                target_state     = ts,
                source_state     = node,
            }
        end
    end

    return events
end

function Simulator:execute_event( event )
    event = tonumber( event )
    if not event then return end

    local state, node   = self:get_current_state()
    if node.event_target[event] then
        self.state = node.event_target[event]
        return true
    end
    return false
end


