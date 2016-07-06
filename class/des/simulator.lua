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
module "Simulator"
--]]
Simulator = letk.Class( function( self, automaton )
    Object.__super( self )
    self.gui            = gui
    self:automaton_load( automaton )
end, Object )

---Loads an automaton to the simulator.
--TODO
--@param self Simulator in which the automaton will be loaded.
--@param automaton Automaton to be loaded.
function Simulator:automaton_load( automaton )
    self.automaton        = automaton or self.automaton
    self.event_name_map   = {}
    self.event_map        = {}
    self.state_map        = {}
    self.current_state_id = self.automaton.initial or 1
    self.state_event_map  = {}

    --Events
    for event_index, event in automaton.events:ipairs() do
        self.event_name_map[event.name] = event_index
        self.event_map[event]           = event_index
        self.event_map[event_index]     = event
    end

    --States
    for state_index, state in automaton.states:ipairs() do
        self.state_map[state]               = state_index
        self.state_map[state_index]         = state
        self.state_event_map[ state_index ] = {}
    end
    
    --State Event Map
    for state_index, state in automaton.states:ipairs() do
        --~ self.state_event_map[ state_index ] = {}
        for pos, transition in state.transitions_out:ipairs() do
            local event_index  = self.event_map[ transition.event ]
            local target_index = self.state_map[ transition.target ]
            if not self.state_event_map[ state_index ][  event_index ] then
                self.state_event_map[ state_index ][ event_index ] = {} --Can be a Non-Deterministic Automaton
            end
            
            local newPosition = #self.state_event_map[state_index][event_index]+1
            self.state_event_map[ state_index ][ event_index ][ newPosition ] = target_index
        end
    end
end

---Returns current state of the simulator.
--TODO
--@param self Simulator whose current state is returned.
--@return Id of the current state.
--@return TODO
function Simulator:get_current_state()
    --~ local node  = self.automaton.states:get( self.current_state_id )
    local state  = self.state_map[ self.current_state_id ]
    return self.current_state_id, state
end

---Returns informations about the current state of the simulator.
--TODO
--@param self Simulator whose informations about current state are returned.
--@return Table with index, name, initial property and marked property of the state.
--@see Simulator:get_current_state
function Simulator:get_current_state_info()
    local state_index, node = self:get_current_state()
    return {
        state_index   = state_index,
        name          = node.name,
        initial       = node.initial,
        marked        = node.marked,
    }
end

---Returns informations about the events of the current state of the simulator.
--TODO
--@param self Simulator whose informations about events are returned.
--@return Table with the events and index, target state, source state, target index and source index of each event.
--@see Simulator:get_current_state
function Simulator:get_current_state_events_info()
    local state_index, state = self:get_current_state()
    local events            = {}
    for k_trans, trans in state.transitions_out:ipairs() do
                events[#events +1] = {
                    event        = trans.event,
                    event_index  = self.event_map[ trans.event ],
                    target_state = trans.target,
                    target_index = self.state_map[trans.target],
                    source_state = trans.state,
                    source_index = self.state_map[trans.state],
                }
    end

    return events
end

---Returns controllable events of the current state of the simulator.
--@param self Simulator whose events are returned.
--@return Table with controllable events of the current state.
--@see Simulator:get_current_state
function Simulator:get_current_state_controllable_events()
    local state_index, state = self:get_current_state()
    local events             = {}
    for k_trans, trans in state.transitions_out:ipairs() do
        if trans.event.controllable then
            events[#events +1] = trans.event
        end
    end
    
    return events
end

---Returns controllable events of the automaton of the simulator.
--TODO
--@param self Simulator whose events are returned.
--@return Table with controllable events of the automaton.
function Simulator:get_controllable_events()
    local events            = {}
    for event_index, event in self.automaton.events:ipairs() do
        if event.controllable then
            events[#events +1] = event
        end
    end
    
    return events
end

---Returns non controllable events of the automaton of the simulator.
--TODO
--@param self Simulator whose events are returned.
--@return Table with non controllable events of the automaton.
function Simulator:get_non_controllable_events()
    local events            = {}
    for event_index, event in self.automaton.events:ipairs() do
        if not event.controllable then
            events[#events +1] = event
        end
    end
    
    return events
end

---Returns all events of the automaton of the simulator.
--TODO
--@param self Simulator whose events are returned.
--@return Table with all events of the automaton.
function Simulator:get_events()
    local events            = {}
    for event_index, event in self.automaton.events:ipairs() do
        events[#events +1] = event
    end
    
    return events
end

---Changes current state of the simulator.
--TODO
--@param self Simulator in which the operation is applied.
--@param state_index Index of the new state.
--@return True if the state is valid, false otherwise.
function Simulator:change_state( state_index )
    state_index = tonumber( state_index )
    if not state_index then return false end

    self.current_state_id = state_index
    
    return true
end

---TODO
--TODO
--@param self TODO
--@param event_index TODO
--@return Always false.
--@see Simulator:get_current_state
function Simulator:get_event_options( event_index )
    local t_ev_id = type( event_index )
    local state_index, node = self:get_current_state()
    
    if  t_ev_id == 'table' then
        event_index = self.event_map[ event_index ] 
    elseif  t_ev_id == 'string' then
        event_index = self.event_name_map[ event_index ] 
    end
    event_index = tonumber( event_index )
    
    if not event_index then return false end
    
    if self.state_event_map[ state_index ][  event_index ] then
        local target_index_options = self.state_event_map[ state_index ][  event_index ]
        return target_index_options
    end
    
    return false
end

---Change state of the simulator according to the occurrence of an event.
--TODO
--@param self Simulator in which the operation is applied.
--@param event_index Index of the event used to change state.
--@return True if no problems occurred, false otherwise.
--@see Simulator:get_event_options
--@see Simulator:change_state
function Simulator:event_evolve( event_index )
    local target_index_options = self:get_event_options( event_index )
    if target_index_options and target_index_options[1] then
        return self:change_state( target_index_options[1] )
    end
    
    return false
end

---Verifies if an event exists.
--TODO
--@param self Simulator in which the operation is applied.
--@param ev_name Name of the event to be verified.
--@return True if the event exists, false otherwise.
function Simulator:event_exists( ev_name )
    return self.event_name_map[ ev_name ] and true or false
end


