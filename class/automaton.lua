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
    self.states      = letk.List.new()
    self.events      = letk.List.new()
    self.transitions = letk.List.new()
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
    local id = self.states:append{
        initial         = initial or false,
        marked          = marked  or false,
        event_target    = {},
        event_source    = {},
        transitions_in  = letk.List.new(),
        transitions_out = letk.List.new(),
        name            = name or tostring( self.states:len() + 1 ),
    }
    if initial then
        self:state_set_initial( id )
    end

    return id
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
    local state, state_index = self.states:find( id )
    if not state then return end

    for ch_sta, sta in self.states:ipairs() do
        sta.initial = false
    end
    state.initial = true
    self.initial  = state_index

    return true
end

function Automaton:state_set_marked( id )
    local state = self.states:find( id )
    if not state then return end

    state.marked = true

    return true
end

function Automaton:state_unset_marked( id )
    local state = self.states:find( id )
    if not state then return end

    state.marked = false

    return true
end

function Automaton:state_get_marked( id )
    local state = self.states:find( id )
    if not state then return end

    return state.marked
end

function Automaton:state_set_name( id, name )
    local state = self.states:find( id )
    if not state then return end

    state.name = name

    return true
end

function Automaton:state_set_position( id, x, y )
    local state = self.states:find( id )
    if not state then return end

    state.x = x
    state.y = y

    return true
end

function Automaton:state_get_position( id )
    local state = self.states:find( id )
    if not state then return end

    return state.x, state.y
end

function Automaton:state_set_radios( id, r )
    local state = self.states:find( id )
    if not state then return end

    state.r = r

    return true
end

function Automaton:state_get_radios( id, r )
    local state = self.states:find( id )
    if not state then return end

    return state.r
end


--Events
function Automaton:event_add(name, observable, controllable)
    return self.events:append{
        observable   = observable or false,
        controllable = controllable or false,
        name         = name,
        transitions  = letk.List.new(),
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

function Automaton:event_get_observable( id )
    local event = self.events:find( id )
    if not event then return end

    return event.observable

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

function Automaton:event_get_controllable( id )
    local event = self.events:find( id )
    if not event then return end

    return event.controllable

end

function Automaton:event_set_name( id, name )
    local event = self.events:find( id )
    if not event then return end

    event.name = name

    return true
end


--Transitions
function Automaton:transition_add( source_id, target_id, event_id )
    local event  = self.events:find( event_id )
    local source = self.states:find( source_id )
    local target = self.states:find( target_id )

    source.event_target[event] = source.event_target[event] or {}
    target.event_source[event] = target.event_source[event] or {}

    if not event or not source or not target then return end --some invalid state/event
    if source.event_target[event][target]  then return end --you can NOT add a same transition twice
    --Index by the table because the id can change, eg if remove a state, or event

    source.event_target[event][target] = true
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

function Automaton:IDES_import( file_name, get_layout )
    get_layout      = true
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

            if name == 'data' or name == 'meta' then run = false end

        end,

        StartElement = function (parser, name, tags)

            --State
            last_tag = name

            if name == 'data' then run = 'data' end
            if name == 'meta' and tags['tag'] == 'layout' then run = 'layout' end

            --~ if not run then return end

            ---*** DATA ***---
            if run == 'data' and name == 'state' then
                sm                      = t.s
                last_id                 = self:state_add( tags['id'], false, false )
                map_state[ tags['id'] ] = last_id
            end

            if run == 'data' and name == 'initial' and sm == t.s then
                self:state_set_initial( last_id )
            end

            if run == 'data' and name == 'marked'  and sm == t.s then
                self:state_set_marked( last_id )
            end

            --Event
            if run == 'data' and name == 'event' then
                sm                      = t.e
                last_ev                 = self:event_add()
                map_event[ tags['id'] ] = last_ev
            end

            if run == 'data' and name == 'observable'   and sm == t.e then
                self:event_set_observable( last_ev )
            end

            if run == 'data' and name == 'controllable' and sm == t.e then
                self:event_set_controllable( last_ev )
            end

            --Transition

            if run == 'data' and name == 'transition' then
                local source = map_state[ tags['source'] ]
                local target = map_state[ tags['target'] ]
                local event  = map_event[ tags['event'] ]

                self:transition_add( source, target, event )
            end

            ---*** LAYOUT ***---
            if run == 'layout' and get_layout and name == 'state' then
                last_id = map_state[ tags['id'] ]
                sm      = t.s
            end

            if run == 'layout' and get_layout and name == 'transition' then
                sm      = t.t
            end

            if run == 'layout' and get_layout and name == 'event' then
                sm      = t.e
            end

            if run == 'layout' and get_layout and name == 'circle' and sm == t.s then
                local x,y = select( 3, tags['x']:find('(%d+)') ),  select( 3, tags['y']:find('(%d+)') )
                self:state_set_position( last_id, x, y)
            end
        end,

        CharacterData = function (parser, text)

            --State:
            if run == 'data' and last_tag == 'name' and sm == t.s and #select( 3, text:find( "([%a%d%p]*)" ) ) > 0 then
                self:state_set_name( last_id, text )
            end

            --Event:
            if run == 'data' and  last_tag == 'name' and sm == t.e and #select( 3, text:find( "([%a%d%p]*)" ) ) > 0 then
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

local function accessible_search( s )
    if s.no_accessible then
        s.no_accessible = nil
        for k_t_out, t_out in s.transitions_out:ipairs() do
            accessible_search( t_out.target )
        end
    end
end

function Automaton:accessible( remove_states )
    self.accessible_calc = true
    for k_s, s in self.states:ipairs() do
        s.no_accessible = true
    end
    local s = self.states:get( self.initial )

    accessible_search( s )
end

local function coaccessible_search( s )
    if s.no_coaccessible then
        s.no_coaccessible = nil
        for k_t_in, t_in in s.transitions_in:ipairs() do
            coaccessible_search( t_in.source )
        end
    end
end

function Automaton:coaccessible( remove_states )
    --make all states as no_coaccessible
    self.coaccessible_calc = true
    for k_s, s in self.states:ipairs() do
        s.no_coaccessible = true
    end

    for k_s, s in self.states:ipairs() do
        if s.no_coaccessible and s.marked then
            coaccessible_search( s )
        end
    end
end

function Automaton:join_no_coaccessible_states()
    if not self.coaccessible_calc then
        self:coaccessible( false )
    end

    -- the new no_coaccessible state
    local Snca                 = self:state_add( 'Snca', false, false )
    local Snca_state           = self.states:get( Snca )
    Snca_state.no_coaccessible = true

    --repeat all transition to/from a no_coaccessible
    for k, state in self.states:ipairs() do
        if k < Snca and state.no_coaccessible then
            --from
            for k_t, t in state.transitions_out:ipairs() do
                if t.target.no_coaccessible then
                    self:transition_add( Snca, Snca, t.event )
                else
                    --yeah, I know it's never be make, but ...
                    self:transition_add( Snca, t.target, t.event )
                end
            end
            --to
            for k_t, t in state.transitions_in:ipairs() do
                if t.source.no_coaccessible then
                    self:transition_add( Snca, Snca, t.event )
                else
                    self:transition_add( t.source, Snca, t.event )
                end
            end

            if state.initial then
                self:state_set_initial( Snca_state )
            end
        end
    end

    for k, state in self.states:ipairs() do
        if k < Snca and state.no_coaccessible then
            self:state_remove( k )
        end
    end
end

function Automaton:syncronize( p2, ... )
    --~ local p1     = self
    --~ local new    = Automaton.new()
    --~ local map_t  = {}
    --~ local map_s1 = {}
    --~ local map_s2 = {}
    --~ local map_e1 = {}
    --~ local map_e2 = {}
    --~ for k_event, event in p1.events:ipairs() do
        --~ map_e1[event.name]  = event
    --~ end
    --~ for k_event, event in p2.events:ipairs() do
        --~ map_e2[event.name] = event
    --~ end
    --~ for k_s, s in p1.states:ipairs() do
        --~ map_s1[s] = k_s
    --~ end
    --~ for k_s, s in p2.states:ipairs() do
        --~ map_s2[s] = k_s
    --~ end
--~
    --~ for k_s1, s1 in p1.states:ipairs() do
        --~ for k_s2, s2 in p1.states:ipairs() do
            --~ local e1 = {}
            --~ local e2 = {}
            --~ for k_t, t in s1.transitions_out:ipairs() do
                --~ e1[t.event.name] = map_s1[t.target]
            --~ end
            --~ for k_t, t in s2.transitions_out:ipairs() do
                --~ e2[t.event.name] = map_s2[t.target]
            --~ end
        --~ end
    --~ end

end

