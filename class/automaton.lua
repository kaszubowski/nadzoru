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
    self.states      = List.new()
    self.events      = List.new()
    self.transitions = List.new()
    self.info        = {}
    self.initial     = nil

    return setmetatable( self , Automaton_MT )

end

------------------------------------------------------------------------
--                        automaton informations                      --
------------------------------------------------------------------------
function Automaton:info_set( key, value )
    if key ~= nil then
        self.info[key] = value
    end
end

function Automaton:info_unset( key )
    if key ~= nil then
        self.info[key] = nil
    end
end

function Automaton:info_get( key )
    if key ~= nil then
        return self.info[key]
    end
end

------------------------------------------------------------------------
--               automaton manipulation and definition                --
------------------------------------------------------------------------

--States
function Automaton:state_add( name, marked, initial )
    return self.states:append{
        --~ id           = id,
        initial         = initial or false,
        marked          = marked  or false,
        event_target    = {},
        event_source    = {},
        transitions_in  = List.new(),
        transitions_out = List.new(),
        name            = name,
    }
end

function Automaton:state_remove( id )
    local state, state_id = self.states:find( id )
    if not state  then return end

    while true do
        local trans = state.transitions_in:find( function() return true end )
        if not trans then break end

        self:transition_remove( trans )
    end
    while true do
        local trans = state.transitions_out:find( function() return true end )
        if not trans then break end

        self:transition_remove( trans )
    end

    self.states:remove( state_id )
end

function Automaton:state_set_initial( id )
    local state = self.states:find( id )
    if not state then return end

    for ch_sta, sta in self.states:ipairs() do
        sta.initial = false
    end
    state.initial = true
    self.initial  = id

    return true
end

function Automaton:state_set_marked( id )
    local state = self.states:find( id )
    if not state then return end

    state.marked = true

    return true
end

function Automaton:state_set_name( id, name )
    local state = self.states:find( id )
    if not state then return end

    state.name = name

    return true
end

--Events
function Automaton:event_add(name, observable, controllable)
    return self.events:append{
        observable   = observable or false,
        controllable = controllable or false,
        name         = name,
        transitions  = List.new(),
    }
end

function Automaton:event_remove( id )
    local event, event_id = self.events:find( id )
    if not event  then return end

    while true do
        local trans = event.transitions:find( function() return true end )
        if not trans then break end

        self:transition_remove( trans )
    end

    self.events:remove( event_id )
end

function Automaton:event_set_observable( id )
    local event = self.events:find( id )
    if not event then return end

    event.observable = true

    return true
end

function Automaton:event_unset_observable( id )
    local event = self.events:find( id )
    if not event then return end

    event.observable = false

    return true
end

function Automaton:event_set_controllable( id )
    local event = self.events:find( id )
    if not event then return end

    event.controllable = true

    return true
end

function Automaton:event_unset_controllable( id )
    local event = self.events:find( id )
    if not event then return end

    event.controllable = false

    return true
end

function Automaton:event_set_name( id, name )
    local event = self.events:find( id )
    if not event then return end

    event.name = name

    return true
end


--Transitions
function Automaton:transition_add( source_id, target_id, event_id )
    event  = self.events:find( event_id )
    source = self.states:find( source_id )
    target = self.states:find( target_id )
    if not event or not source or not target then return end

    --Index by the table because the id can change, eg if remove a state, or event
    source.event_target[event]         = target
    target.event_source[event]         = target.event_source[event] or {}
    target.event_source[event][source] = true

    local transition = {
        source = source,
        target = target,
        event  = event,
    }
    self.transitions:append( transition )

    source.transitions_out:append( transition )
    target.transitions_in:append( transition )
    event.transitions:append( transition )
end

function Automaton:transition_remove( id )
    local trans, trans_id = self.transitions:find( id )
    if not trans then return end

    trans.event.transitions:find_remove( trans )
    trans.source.transitions_out:find_remove( trans )
    trans.target.transitions_in:find_remove( trans )
    self.transitions:remove( trans_id )

end

------------------------------------------------------------------------
--                          operations                               --
------------------------------------------------------------------------

function Automaton:IDES_import( file_name )
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
function Automaton:state_len( )
    return self.states:len()
end

function Automaton:event_len( )
    return self.events:len()
end

function Automaton:event_get( ev_num )
    return self.events:get(ev_num)
end

function Automaton:event_get_name( ev_num )
    return self.events:get(ev_num).name
end

function Automaton:transition_len( )
    return self.transitions:len()
end



--Operations :)
function Automaton:clone()
    local new_automaton = Automaton.new()
    local state_map = {}
    local event_map = {}
    for c, v in self.states:ipairs() do
        state_map[v] = new_automaton:state_add( v.name, v.marked, v.initial )
    end
    for c, v in self.events:ipairs() do
        event_map[v] = new_automaton:event_add(v.name, v.observable, v.controllable)
    end
    for c, v in self.transitions:ipairs() do
        new_automaton:transition_add( state_map[v.source], state_map[v.target], event_map[v.event] )
    end

    return new_automaton

end

function Automaton:accessible( remove_states )

end

local function coaccessible_search( s )
    if not s.no_coaccessible then
        s.no_coaccessible = true
        for k_t_in, t_in in s.transitions_in:ipairs() do
            coaccessible_search( t_in.source )
        end
    end
end

function Automaton:coaccessible( remove_states )
    --uncleck all states
    local total = self.states:len()
    for k_s, s in self.states:ipairs() do
        s.no_coaccessible = nil
    end
    for k_s, s in self.states:ipairs() do
        if not s.no_coaccessible and s.marked then
            coaccessible_search( s )
            print(k_s, total)
        end
    end
end

--test
--~ require('object')
--~ require('list')
--~ require('lxp')
--~ local test = Automaton.new()
--~ test:IDES_import('../examples/G3.xmd')
--~ print(test:state_len())
--~ print(test:event_len())
--~ print(test:transition_len())
--~ for c,v in test.transitions:ipairs() do
    --~ print(c, v.event.name )
--~ end
--~ test:state_remove(2)
--~ print(test:state_len())
--~ print(test:event_len())
--~ print(test:transition_len())
--~ for c,v in test.transitions:ipairs() do
    --~ print(c, v.event.name )
--~ end

