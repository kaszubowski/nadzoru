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
Automaton = {}
Automaton_MT = { __index = Automaton }

setmetatable( Automaton, Object_MT )

function Automaton.new()
    local self       = Object.new()
    self.states      = {}
    self.events      = {}
    self.transitions = {}
    self.forbiden_ev = {}
    self.info        = {}
    self.initial     = nil

    return setmetatable( self , Automaton_MT )

end

------------------------------------------------------------------------
--               automaton manipulation and definition                --
------------------------------------------------------------------------

function Automaton:set_info( key, value )
    if key ~= nil then
        self.info[key] = value
    end
end

function Automaton:unset_info( key )
    if key ~= nil then
        self.info[key] = nil
    end
end

function Automaton:get_info( key )
    if key ~= nil then
        return self.info[key]
    end
end

function Automaton:state_add( name, marked, initial )
    self.states[#self.states +1] = {
        id           = id,
        initial      = initial or false,
        marked       = marked  or false,
        event_target = {},
        event_source = {},
        transitions  = {},
        forbiden_ev  = {},
        name         = name,
    }

    return #self.states
end

function Automaton:state_set_initial( id )
    if not self.states[id] then
        return false
    end

    for ch_sta, sta in ipairs( self.states ) do
        sta.initial = false
    end
    self.states[id].initial = true
    self.initial            = id

    return true
end

function Automaton:state_set_marked( id )
    if not self.states[id] then
        return false
    end

    self.states[id].marked = true

    return true
end

function Automaton:state_set_name( id, name )
    if not self.states[id] then
        return false
    end

    self.states[id].name = name

    return true
end

function Automaton:event_add(name, observable, controllable)
    self.events[#self.events +1] = {
        observable   = observable or false,
        controllable = controllable or false,
        name         = name,
        transitions  = {},
    }

    return #self.events
end

function Automaton:event_set_observable( id )
    if not self.events[id] then
        return false
    end

    self.events[id].observable = true

    return true
end

function Automaton:event_set_controllable( id )
    if not self.events[id] then
        return false
    end

    self.events[id].controllable = true

    return true
end

function Automaton:event_set_name( id, name )
    if not self.events[id] then
        return false
    end

    self.events[id].name = name

    return true
end

function Automaton:transition_add( source, target, event )
    self.states[source].event_target[event]         = target
    self.states[target].event_source[event]         = self.states[target].event_source[event] or {}
    self.states[target].event_source[event][source] = true

    local pos_transitions = #self.transitions +1

    self.transitions[ pos_transitions ] = {
        source = source,
        target = target,
        event  = event,
    }

    self.states[source].transitions = pos_transitions
    self.states[target].transitions = pos_transitions
    self.events[event].transitions  = pos_transitions
end

------------------------------------------------------------------------
--                          operations                               --
------------------------------------------------------------------------

function Automaton:read_IDES( file_name )
    local t         = { s = 1, e = 2, t = 3, }
    local sm        = 0
    local last_tag  = ''
    local last_id   = nil
    local last_ev   = nil
    local run       = false

    local map_state = {}
    local map_event = {}


    local callbacks = {

        EndElement = function (parser, name)

            if name == 'data' then run = false end

        end,

        StartElement = function (parser, name, tags)

            --State
            last_tag = name

            if name == 'data' then run = true end

            if not run then return end

            if name == 'state' then
                sm                      = t.s
                last_id                 = self:state_add( tags['id'], '' )
                map_state[ tags['id'] ] = last_id
            end

            if name == 'initial' and sm == t.s then
                self:state_set_initial( last_id )
            end

            if name == 'marked'  and sm == t.s then
                self:state_set_marked( last_id )
            end

            --Event
            if name == 'event' then
                sm                      = t.e
                last_ev                 = self:event_add()
                map_event[ tags['id'] ] = last_ev
            end

            if name == 'observable'   and sm == t.e then
                self:event_set_observable( last_ev )
            end

            if name == 'controllable' and sm == t.e then
                self:event_set_controllable( last_ev )
            end

            --Transition

            if name == 'transition' then
                local source = map_state[ tags['source'] ]
                local target = map_state[ tags['target'] ]
                local event  = map_event[ tags['event'] ]

                self:transition_add( source, target, event )
            end

        end,

        CharacterData = function (parser, text)

            --State:
            if last_tag == 'name' and sm == t.s and #select( 3, text:find( "([%a%d%p]*)" ) ) > 0 then
                self:state_set_name( last_id, text )
            end

            --Event:
            if last_tag == 'name' and sm == t.e and #select( 3, text:find( "([%a%d%p]*)" ) ) > 0 then
                self:event_set_name( last_ev, text )
            end

        end,

    }

    local p    = lxp.new(callbacks)
    local file = io.open(file_name)

    for l in file:lines() do
        p:parse(l)
        p:parse('\n')
    end

    p:parse()
    p:close()
    file:close()

    return self
end

--utils
function Automaton:get_event( ev_num )
    return self.events[ev_num]
end

function Automaton:get_event_name( ev_num )
    return self.events[ev_num].name
end
