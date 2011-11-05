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
Automaton = letk.Class( function( self )
    Object.__super( self )
    self.states      = letk.List.new()
    self.events      = letk.List.new()
    self.transitions = letk.List.new()
    --~ self.info        = {}
    self.initial     = nil
    self:set('file_name', '*new' )
end, Object )

Automaton.__TYPE = 'automaton'

------------------------------------------------------------------------
--                         Private utils                              --
------------------------------------------------------------------------
function remove_states_fn( A, fn )

        local removed_states = A.states:iremove( fn )
        --remove in/out transition to/from bad states
        local transitions_to_remove = {}
        for ksrm, srm in ipairs( removed_states ) do
            for kt, t in srm.transitions_out:ipairs() do
                transitions_to_remove[ t ] = true
                t.target.event_source[t.event]           = t.target.event_source[t.event] or {}
                t.target.event_source[t.event][t.source] = nil
            end
            for kt, t in srm.transitions_in:ipairs() do
                transitions_to_remove[ t ] = true
                t.source.event_target[t.event]           = t.source.event_target[t.event] or {}
                t.source.event_target[t.event][t.target] = nil
            end
        end
        A.transitions:iremove( function( t )
            return transitions_to_remove[ t ] or false
        end )
        for k_s, s in A.states:ipairs() do
            s.transitions_in:iremove( function( t )
                return transitions_to_remove[ t ] or false
            end )
            s.transitions_out:iremove( function( t )
                return transitions_to_remove[ t ] or false
            end )
        end
        for k_e, e in A.events:ipairs() do
            e.transitions:iremove( function( t )
                return transitions_to_remove[ t ] or false
            end )
        end
end

------------------------------------------------------------------------
--               automaton manipulation and definition                --
------------------------------------------------------------------------

--States
function Automaton:state_add( name, marked, initial )
    local new_state = {
        initial         = initial or false,
        marked          = marked  or false,
        event_target    = {},
        event_source    = {},
        transitions_in  = letk.List.new(),
        transitions_out = letk.List.new(),
        name            = name or tostring( self.states:len() + 1 ),
    }
    local id = self.states:append( new_state )
    if initial then
        self:state_set_initial( id )
    end

    return id, new_state
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
    local new_event = {
        observable   = observable or false,
        controllable = controllable or false,
        name         = name,
        transitions  = letk.List.new(),
    }

    local id = self.events:append( new_event )

    return id, new_event
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
    name = name:gsub('[^%&%w%_]','')
    if name:find('%&') then
        name = '&'
    end
    if name:find('EMPTYWORD') then
        name = '&'
    end

    event.name = name

    return true
end


--Transitions
function Automaton:transition_add( source_id, target_id, event_id, isdata )
    local event  = not isdata and self.events:find( event_id )  or event_id
    local source = not isdata and self.states:find( source_id ) or source_id
    local target = not isdata and self.states:find( target_id ) or target_id

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
    trans.source.event_target[trans.event] = trans.source.event_target[trans.event] or {}
    trans.target.event_source[trans.event] = trans.target.event_source[trans.event] or {}
    trans.source.event_target[trans.event][trans.target] = nil
    trans.target.event_source[trans.event][trans.source] = nil
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
    local last_obj  = nil
    local last_ev   = nil
    local run       = false

    local map_state, map_state_obj = {}, {}
    local map_event, map_event_obj = {}, {}


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
                sm                          = t.s
                last_id, last_obj           = self:state_add( tags['id'], false, false )
                map_state[ tags['id'] ]     = last_id
                map_state_obj[ tags['id'] ] = last_obj
            end

            if run == 'data' and name == 'initial' and sm == t.s then
                self:state_set_initial( last_id )
            end

            if run == 'data' and name == 'marked'  and sm == t.s then
                self:state_set_marked( last_id )
            end

            --Event
            if run == 'data' and name == 'event' then
                sm                          = t.e
                last_ev, last_obj           = self:event_add()
                map_event[ tags['id'] ]     = last_ev
                map_event_obj[ tags['id'] ] = last_obj
            end

            if run == 'data' and name == 'observable'   and sm == t.e then
                self:event_set_observable( last_ev )
            end

            if run == 'data' and name == 'controllable' and sm == t.e then
                self:event_set_controllable( last_ev )
            end

            --Transition

            if run == 'data' and name == 'transition' then
                local source = map_state_obj[ tags['source'] ]
                local target = map_state_obj[ tags['target'] ]
                local event  = map_event_obj[ tags['event'] ]

                self:transition_add( source, target, event, true )
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

    self:set('full_file_name', file_name)
    self:set('file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
    self:set('file_type', 'xmd')

    return self
end

function Automaton:save_serialize()
    local data                 = {
        states      = {},
        events      = {},
        transitions = {},
    }
    local state_map, event_map = {}, {}

    for k_state, state in self.states:ipairs() do
        state_map[state] = k_state
        data.states[ #data.states + 1 ] = {
            name    = state.name,
            initial = state.initial or false,
            marked  = state.marked  or false,
            x  = state.x,
            y  = state.y,
            r  = state.r,
        }
    end

    for k_event, event in self.events:ipairs() do
        event_map[ event ] = k_event
        data.events[ #data.events + 1 ] = {
            name         = event.name,
            controllable = event.controllable or false,
            observable   = event.observable  or false,
        }
    end

    for k_transition, transition in self.transitions:ipairs() do
        data.transitions[ #data.transitions + 1 ] = {
            source = state_map[ transition.source ],
            target = state_map[ transition.target ],
            event = event_map[ transition.event ],
        }
    end

    return letk.serialize( data )
end

local FILE_ERROS = {}
FILE_ERROS.ACCESS_DENIED     = 1
FILE_ERROS.NO_FILE_NAME      = 2
FILE_ERROS.INVALID_FILE_TYPE = 3

function Automaton:save()
    local file_type = self:get( 'file_type' )
    local file_name = self:get( 'full_file_name' )
    if file_type == 'nza' and file_name then
        if not file_name:match( '%.nza$' ) then
            file_name = file_name .. '.nza'
        end
        local file = io.open( file_name, 'w')
        if file then
            local code = self:save_serialize()
            file:write( code )
            file:close()
            return true
        end
        return false, FILE_ERROS.ACCESS_DENIED, FILE_ERROS
    elseif not file_type then
        return false, FILE_ERROS.NO_FILE_NAME, FILE_ERROS
    else
        return false, FILE_ERROS.INVALID_FILE_TYPE, FILE_ERROS
    end
end

function Automaton:save_as( file_name )
    if file_name then
        if not file_name:match( '%.nza$' ) then
            file_name = file_name .. '.nza'
        end
        local file = io.open( file_name, 'w')
        if file then
            local code = self:save_serialize()
            file:write( code )
            file:close()
            self:set( 'file_type', 'nza' )
            self:set( 'full_file_name', file_name )
            self:set( 'file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
            return true
        end
        return false, FILE_ERROS.ACCESS_DENIED, FILE_ERROS
    else
        return false, FILE_ERROS.NO_FILE_NAME, FILE_ERROS
    end
end

function Automaton:load_file( file_name )
    local file = io.open( file_name, 'r')
    if file then
        local s    = file:read('*a')
        local data = loadstring('return ' .. s)()
        local state_map, event_map = {}, {}
        if data then
            for k_state, state in ipairs( data.states ) do
                local id, new_state = self:state_add( state.name, state.marked, state.initial )
                new_state.x         = state.x
                new_state.y         = state.y
                new_state.r         = state.r
                state_map[id]       = new_state
            end
            for k_event, event in ipairs( data.events ) do
                local id, new_event = self:event_add( event.name, event.observable, event.controllable )
                event_map[id]       = new_event
            end
            for k_transition, transition in ipairs( data.transitions ) do
                self:transition_add( state_map[transition.source], state_map[transition.target], event_map[transition.event], true )
            end
            self:set( 'file_type', 'nza' )
            self:set( 'full_file_name', file_name )
            self:set( 'file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
        end
    end
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



-- *** Operations *** --
function Automaton:check()
    local problems = {}
    local ok       = true
    if self.initial then
        problems.initial = false
    else
        problems.initial = true
        ok               = false
    end

    return ok, problems
end

function Automaton:clone()
    local new_automaton   = Automaton.new()
    local state_map = {}
    local event_map = {}
    local _
    for c, v in self.states:ipairs() do
        _, state_map[v] = new_automaton:state_add( v.name, v.marked, v.initial )
    end
    for c, v in self.events:ipairs() do
        _, event_map[v]= new_automaton:event_add(v.name, v.observable, v.controllable)
    end
    for c, v in self.transitions:ipairs() do
        new_automaton:transition_add( state_map[v.source], state_map[v.target], event_map[v.event], true )
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

function Automaton:accessible( remove_states, keep )
    local newautomaton = keep and self or self:clone()
    newautomaton.accessible_calc = true
    for k_s, s in newautomaton.states:ipairs() do
        s.no_accessible = true
    end

    local si = newautomaton.states:get( newautomaton.initial )
    if si then
        accessible_search( si )
    end

    if remove_states then
        remove_states_fn( newautomaton, function( s )
            return s.no_accessible or false
        end )
    end

    return newautomaton
end

local function coaccessible_search( s )
    if s.no_coaccessible then
        s.no_coaccessible = nil
        for k_t_in, t_in in s.transitions_in:ipairs() do
            coaccessible_search( t_in.source )
        end
    end
end

function Automaton:coaccessible( remove_states, keep )
    local newautomaton = keep and self or self:clone()
    --make all states as no_coaccessible
    newautomaton.coaccessible_calc = true
    for k_s, s in newautomaton.states:ipairs() do
        s.no_coaccessible = true
    end

    for k_s, s in newautomaton.states:ipairs() do
        if s.no_coaccessible and s.marked then
            coaccessible_search( s )
        end
    end

    if remove_states then
        remove_states_fn( newautomaton, function( s )
            return s.no_coaccessible or false
        end )
    end

    return newautomaton
end

function Automaton:join_no_coaccessible_states( keep )
    local newautomaton = self:coaccessible( false, keep )

    -- the new no_coaccessible state
    local Snca, Snca_state            = newautomaton:state_add( 'Snca', false, false )
    Snca_state.no_coaccessible        = true
    Snca_state.no_coaccessible_remove = true

    --repeat all transition to/from a no_coaccessible
    for k, state in newautomaton.states:ipairs() do
        if k < Snca and state.no_coaccessible then
            --from
            for k_t, t in state.transitions_out:ipairs() do
                if t.target.no_coaccessible then
                    newautomaton:transition_add( Snca_state, Snca_state, t.event, true )
                else
                    --yeah, I know it's never be make, but ...
                    newautomaton:transition_add( Snca_state, t.target, t.event, true )
                end
            end
            --to
            for k_t, t in state.transitions_in:ipairs() do
                if t.source.no_coaccessible then
                    newautomaton:transition_add( Snca_state, Snca_state, t.event, true )
                else
                    newautomaton:transition_add( t.source, Snca_state, t.event, true )
                end
            end

            if state.initial then
                newautomaton:state_set_initial( Snca_state )
            end
        end
    end

    remove_states_fn( newautomaton, function( s )
        return (s.no_coaccessible and not s.no_coaccessible_remove ) and true or false
    end )

    return newautomaton
end

function Automaton:trim( remove_states, keep )
    return self:coaccessible( remove_states, keep ):accessible( remove_states, true )
end

function Automaton:selfloop( keep, ... )
    local newautomaton = keep and self or self:clone()
    local all          = { ... }
    local self_events  = {}
    local loop_events  = {}

    for k_event, event in newautomaton.events:ipairs() do
        self_events[ event.name ] = true
    end

    for k_a, a in ipairs( all ) do
        for k_event, event in a.events:ipairs() do
            if not self_events[ event.name ] and not loop_events[ event.name ] then
               loop_events[ event.name ] = newautomaton:event_add(
                    event.name, event.observable, event.controllable
                )
            end
        end
    end

    for k_state, state in newautomaton.states:ipairs() do
        for nm_event, id_event in pairs( loop_events ) do
            newautomaton:transition_add( k_state, k_state, id_event )
        end
    end

    return newautomaton
end

local function selfloopall( ... )
    local all           = { ... }
    local map_events    = {}
    local all_events    = {}
    local new_events    = {}

    for k_a, a in ipairs( all ) do
        map_events[ k_a ] = {}
        for k_event, event in a.events:ipairs() do
            map_events[ k_a ][ event.name ] = true
            all_events[ event.name ]        = event
        end
    end

    for k_a, a in ipairs( all ) do
        new_events[ k_a ] = {}
        for nm_event, event in pairs( all_events ) do
            if not map_events[ k_a ][ event.name ] then
                new_events[ k_a ][ event.name ] = a:event_add(
                    event.name, event.observable, event.controllable
                )
            end
        end
    end

    for k_a, a in ipairs( all ) do
        for k_state, state in a.states:ipairs() do
            for nm_event, id_event in pairs( new_events[ k_a ]  ) do
                a:transition_add( k_state, k_state, id_event )
            end
        end
    end
end

--parallel composition
function Automaton:synchronization( ... )
    local all           = { self, ... }
    local new_all       = {}

    for k_a, a in ipairs( all ) do
        new_all[ k_a ] = a:clone()
    end

    selfloopall( unpack( new_all ) )

    return Automaton.product( unpack( new_all ) )
end

--intersection or meet
function Automaton:product( ... )
    local all           = { self, ... }
    local new_automaton = Automaton:new()

    --find common events:
    local events        = {}
    local events_count  = {}
    for k_a, a in ipairs( all ) do
        for k_e, e in a.events:ipairs() do
            events[ e.name ]       = e
            if events_count[ e.name ] then
                events_count[ e.name ] = events_count[ e.name ] + 1
            else
                events_count[ e.name ] = 1
            end
        end
    end
    local events_names_id,  events_names_data = {}, {}
    for e_nm, count in pairs( events_count ) do
        if count == #all then
            events_names_id[ e_nm ], events_names_data[ e_nm ] = new_automaton:event_add(
                events[ e_nm ].name, events[ e_nm ].observable, events[ e_nm ].controllable
            )
        else
            events[ e_nm ] = nil
        end
    end

    --Create transitions map
    local transitions_map    = {}
    local state_num_data_map = {}
    for k_a, a in ipairs( all ) do
        transitions_map[ k_a ]    = {}
        state_num_data_map[ k_a ] = {}
        local states_map       = {}
        for k_s, s in a.states:ipairs() do
            transitions_map[ k_a ][ k_s ]    = {}
            states_map[ s ]                  = k_s
            state_num_data_map[ k_a ][ k_s ] = s
        end
        for k_s, s in a.states:ipairs() do
            for k_e, e in s.transitions_out:ipairs() do
                if events_names_id[ e.event.name ] then
                    transitions_map[ k_a ][ k_s ][ e.event.name ] = states_map[ e.target ]
                end
            end
        end
    end

    --Generate states and transitions
    local state_stack, ss_top = {}, 0
    local created_states_data = {}, 0
    local created_states_id   = nil

    --init
    local new_stack = {}
    local marked    = true
    for k_a,a in ipairs( all ) do
        new_stack[ k_a ] = a.initial
        if not state_num_data_map[ k_a ][ a.initial ].marked then
            marked = false
        end
    end
    ss_top              = ss_top + 1
    state_stack[ss_top] = new_stack
    state_map_id        = table.concat( new_stack, ',' )
    created_states_id, created_states_data[ state_map_id ] = new_automaton:state_add(
        state_map_id, marked, true
    )

    --loop
    while ss_top > 0 do
        --pop
        local current            = state_stack[ss_top]
        local current_state_data = created_states_data[ table.concat( current, ',' ) ]
        state_stack[ss_top]      = nil
        ss_top                   = ss_top - 1

        --create states
        for e_nm, e in pairs( events ) do
            local ok = true
            new_stack   = {}
            marked      = true
            for k_a, a in ipairs( all ) do
                local target = transitions_map[ k_a ][ current[k_a] ][ e_nm ]
                if  target then
                    new_stack[ k_a ] = target
                    if not state_num_data_map[ k_a ][ target ].marked then
                        marked = false
                    end
                else
                    ok = false
                    break
                end
            end
            if ok then
                state_map_id = table.concat( new_stack, ',' )
                if not created_states_data[ state_map_id ] then
                    created_states_id, created_states_data[ state_map_id ] = new_automaton:state_add(
                        state_map_id, marked, false
                    )
                    ss_top              = ss_top + 1
                    state_stack[ss_top] = new_stack
                end
                new_automaton:transition_add(
                    current_state_data,
                    created_states_data[ state_map_id ],
                    events_names_data[ e_nm ],
                    true
                )
            end
        end
    end

    return new_automaton
end

function Automaton.supC(G, K)
    local R          = K:clone()
    local mapG, mapR = {}, {}, {}

    for k_s, s in G.states:ipairs() do
        mapG[k_s] = s
        mapG[s]   = k_s
    end

    for k_s, s in R.states:ipairs() do
        mapR[k_s] = s
        mapR[s]   = k_s
    end

    local count, totalc = 0, R.states:len()

    local last_R_len  = -1
    local atual_R_len = R.states:len()
    while last_R_len ~= atual_R_len do
        last_R_len = atual_R_len
        -- find all (x,.) and bad states
        local visited    = {}
        local stack      = {{G.states:get(G.initial), R.states:get(R.initial)}}
        local i          = 1
        local bad_states = {}

        while i > 0 do
            --pop
            local current = stack[ i ]
            i             = i - 1
            if not current[1] or not current[2] then
                break
            end

            local id_g, id_r = mapG[ current[1] ], mapR[ current[2] ]
            local s_g, s_r   = current[1], current[2]
            local id     = id_g .. '_' .. id_r
            if not visited[id] then
                visited[id] = true
                local R_t   = {}
                local G_t   = {}
                for id_t, t in s_g.transitions_out:ipairs() do
                    G_t[t.event.name] = t.target
                end
                for id_t, t in s_r.transitions_out:ipairs() do
                    R_t[t.event.name] = t.target
                    i = i + 1
                    stack[i] = {
                        G_t[t.event.name] or s_g, --G
                        t.target,                 --R
                    }
                end
                for id_e, e in R.events:ipairs() do
                    if
                        not bad_states[ s_r ] and
                        not e.controllable    and
                        G_t[ e.name ]         and
                        not R_t[ e.name ]
                    then
                        s_r.bad_state         = true
                        bad_states[ s_r ]     = true
                    end
                end
            end
        end
        --recursive check bad_states
        i = 1
        while i <= #bad_states do
            local bs = bad_states[i]
            i        = i + 1
            for id_t, t in bs.transitions_in:ipairs() do
                if not t.event.controllable and not t.source.bad_state then
                    t.source.bad_state          = true
                end
            end
        end

        --remove bad states
        remove_states_fn( R, function( s )
            return s.bad_state or false
        end )

        --trim
        R:trim( true, true )

        atual_R_len = R.states:len()
    end

    return R
end

function Automaton:check_choice_problem( keep )
    local newautomaton = keep and self or self:clone()

    --create a map(s_ce) Q,e --> Qa
    local s_ce = {}
    for k_s, s in newautomaton.states:ipairs() do
        s_ce[ s ] = {}
        for k_t, t in s.transitions_out:ipairs() do
            if  t.event.controllable then
                s_ce[ s ][ t.event ] = t.target
            end
        end
    end

    --check the choice problem
    for Q, t in pairs( s_ce ) do
        local ok = true
        for e, Qa in pairs( t ) do
            for ev_ch, _ in pairs( t ) do
                if ev_ch ~= e and not s_ce[Qa][ev_ch] then
                    ok = false
                    break
                end
            end
            if not ok then break end
        end
        if not ok then
            Q.choice_problem = true
        end
    end

    newautomaton.choice_problem_calc = true

    return newautomaton
end

function Automaton:check_avalanche_effect( keep, uncontrollable_only )
    local newautomaton = keep and self or self:clone()

    --create a map(s_ce) Q,e --> Qa
    local s_ce      = {}
    local state_map = {}
    for k_s, s in newautomaton.states:ipairs() do
        s_ce[ s ]      = {}
        state_map[ s ] = k_s
        for k_t, t in s.transitions_out:ipairs() do
            if  not t.event.controllable or not uncontrollable_only then
                s_ce[ s ][ t.event ] = t.target
            end
        end
    end

    --check avalanche effect
    for Q, t in pairs( s_ce ) do
        for e, Qa in pairs( t ) do
            if s_ce[ Qa ][ e ] then
                Q.avalanche_effect           = Q.avalanche_effect or {}
                Q.avalanche_effect[ e.name ] = state_map[ Qa ]
            end
        end
    end

    newautomaton.avalanche_effect_calc = true

    return newautomaton
end

function Automaton:check_inexact_synchronization( keep )
    local newautomaton = keep and self or self:clone()

    --create a map(s_ce) Q,e --> Qa
    local s_ce      = {}
    for k_s, s in newautomaton.states:ipairs() do
        s_ce[ s ]      = {}
        for k_t, t in s.transitions_out:ipairs() do
                s_ce[ s ][ t.event ] = t.target
        end
    end

    --check inexact synchronization
    --
    -- Q--|---ec----->Qa------eu----->Qc
    -- |
    -- |----- eu----->Qb--|---ec----->Qd
    --
    --if (Qc == Qd) then OK else NOT
    for Q, t in pairs( s_ce ) do
        for ec, Qa in pairs( t ) do
            if ec.controllable then
                for eu, Qb in pairs( t ) do
                    if not eu.controllable then
                        local Qc = s_ce[ Qa ][ eu ]
                        local Qd = s_ce[ Qb ][ ec ]
                        if not Qc or not Qd or Qc ~= Qd then
                            Q.inexact_synchronization = Q.inexact_synchronization or {}
                            table.insert( Q.inexact_synchronization, {
                                controlable   = ec,
                                uncontrolable = eu,
                                target_c_u    = Qc,
                                target_u_c    = Qd,
                            })
                        end
                    end
                end
            end
        end
    end

    newautomaton.inexact_synchronization_calc = true

    return newautomaton
end

function Automaton:check()
    print'Check start...'
    local sinit       = self.states:get( self.initial )
    local states      = {}
    local events      = {}
    local transitions = {}
    if sinit then
        print'[ OK ] Init find'
    else
        print'[ ERRO ] Init NOT find'
    end

    for k_s, s in self.states:ipairs() do
        states[ k_s ] = s
        states[ s ]   = k_s
    end

    for k_e, e in self.events:ipairs() do
        events[ k_e ] = e
        events[ e ]   = k_e
    end

    print'check main transitions...'
    for k_t, t in self.transitions:ipairs() do
        transitions[ k_t ] = t
        transitions[ t ]   = k_t
        if not events[ t.event ] then
            print( string.format('[ ERRO ] Event %s not found in transition %i',
                tostring( t.event ), k_t
            ), states[t.source], events[ t.event ], states[t.target])
        end
        if not states[ t.target ] then
            print( string.format('[ ERRO ] State %s (T) not found in transition %i',
                tostring( t.target ), k_t
            ), states[t.source], events[ t.event ], states[t.target])
        end
        if not states[ t.source ] then
            print( string.format('[ ERRO ] State %s (S) not found in transition %i',
                tostring( t.source ), k_t
            ), states[t.source], events[ t.event ], states[t.target])
        end
    end

    print'check state transitions...'
    for k_s, s in self.states:ipairs() do
        for k_t, t in s.transitions_out:ipairs() do
            if not transitions[ t ] then
                print( string.format('[ERRO] Transition OUT %s not found in state %i',
                    tostring( t ), k_s
                ))
            end
            if t.source ~= s then
                print( string.format('[ERRO] Invalid self in Transition OUT %s in state %i',
                    tostring( t ), k_s
                ), t.source, s)
            end
            if not states[ t.target ] then
                print( string.format('[ERRO] Invalid target in Transition OUT %s in state %i',
                    tostring( t ), k_s
                ))
            end
            if not events[ t.event ] then
                print( string.format('[ERRO] Invalid event in Transition OUT %s in state %i',
                    tostring( t ), k_s
                ))
            end
        end
        for k_t, t in s.transitions_in:ipairs() do
            if not transitions[ t ] then
                print( string.format('[ERRO] Transition IN %s not found in state %i',
                    tostring( t ), k_s
                ))
            end
            if t.target ~= s then
                print( string.format('[ERRO] Invalid self in Transition IN %s in state %i',
                    tostring( t ), k_s
                ),t.target,s)
            end
            if not states[ t.source ] then
                print( string.format('[ERRO] Invalid target in Transition IN %s in state %i',
                    tostring( t ), k_s
                ))
            end
            if not events[ t.event ] then
                print( string.format('[ERRO] Invalid event in Transition IN %s in state %i',
                    tostring( t ), k_s
                ))
            end
        end
    end
    print'Check finish.'
end
