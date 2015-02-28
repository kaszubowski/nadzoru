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
module "Automaton"
--]]
Automaton = letk.Class( function( self )
    Object.__super( self )
    self.states      = letk.List.new()
    self.events      = letk.List.new()
    self.transitions = letk.List.new()
    --~ self.info        = {}
    self.initial     = nil
    self.radius_factor = 1
    self:set('file_name', '*new automaton' )
    --self.controller  = controller
    --self.type        = get_list('type')[1]
    --self.level       = get_list('level')[1]
    --self:create_log()
end, Object )

Automaton.__TYPE = 'automaton'

------------------------------------------------------------------------
--                         Private utils                              --
------------------------------------------------------------------------

---Removes states from an automaton according to a function.
--Removes states from the state list of the automaton according to 'fn'. Removes transitions that have these states as source or target.
--@param A Automaton in which the operation is applied.
--@param fn Function used to determine which states are removed.
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

---We check all states' numbers that can be converted to number,
--then we mark the used one and return the first unused (the first hole in the table)
--@param self Automaton in which the operation is applied.
--@return A number representing the first available number to name a state.
function Automaton:getNextAvailableNumber()
    local tookNumbers = {}
    for k_state, state in self.states:ipairs() do
        local n = tonumber(state.name)
        if n then
            tookNumbers[ n ] = true
        end
    end
    
    return table.icount( tookNumbers ) + 1
end

---Adds a new state to the automaton.
--Creates a state with no transitions, with properties according to the arguments 'name', 'marked' and 'initial' (if name is not provided, it will be a number relative to the number of states of the automaton). Inserts the new state in the automaton. If initial is true, the initial state of the automaton is set to the new state.
--@param self Automaton in which the operation is applied.
--@param name Name of the new state.
--@param marked If true, the new state is marked.
--@param initial If true, the new state becomes the initial state.
--@param id Forced id of the state.
--@return Id of the new state.
--@return New state itself.
--@see Automaton:state_set_initial
function Automaton:state_add( name, marked, initial, id )
    local new_state = {
        initial             = initial or false,
        marked              = marked  or false,
        event_target        = {},
        event_source        = {},
        transitions_in      = letk.List.new(),
        transitions_out     = letk.List.new(),
        name                = tostring( name or self:getNextAvailableNumber() ),
        target_trans_factor = {}
    }

    if not id then
        id = self.states:append( new_state )
    else
        self.states:add(new_state, id)
    end

    if initial then
        self:state_set_initial( id )
    end

    return id, new_state
end

---Removes a state from the automaton.
--Verifies if the state represented by 'id' exists. Removes from the automaton every transition that has this state as soruce or target. Removes the state from the state list of the automaton.
--@param self Automaton in which the operation is applied.
--@param id Id of the state to be removed.
--@see Automaton:transition_remove
function Automaton:state_remove( id )
    local state, state_id = self.states:find( id )
    if not state then return end

    if state.initial then
        self.initial = nil
    end
    while true do
        local trans = state.transitions_in:find( function() return true end )
        if not trans then break end
        trans.source.target_trans_factor[ state ] = nil

        self:transition_remove( trans )
    end
    while true do
        local trans = state.transitions_out:find( function() return true end )
        if not trans then break end

        self:transition_remove( trans )
    end

    self.states:remove( state_id )
end

---Sets the initial state of the automaton.
--Verifies if the state represented by 'id' exists. Sets any other state to no initial. Sets the state to initial. Sets the initial state of the automaton to the state.
--@param self Automaton in which the operation is applied.
--@param id Id of the state to be set.
--@return True if no problems occurred, false/nil otherwise.
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

---Unsets the initial state of the automaton.
--Sets all states initial property to false. Unsets the initial state of the automaton.
--@param self Automaton in which the operation is applied.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:state_unset_initial( )
    for ch_sta, sta in self.states:ipairs() do
        sta.initial = false
    end
    self.initial = nil

    return true
end

---Sets a state of the automaton to marked.
--Verifies if the state represented by 'id' exists. Sets the state to marked.
--@param self Automaton in which the operation is applied.
--@param id Id of the state to be set.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:state_set_marked( id )
    local state = self.states:find( id )
    if not state then return end

    state.marked = true

    return true
end

---Sets a state of the automaton to unmarked.
--Verifies if the state represented by 'id' exists. Sets the state to unmarked.
--@param self Automaton in which the operation is applied.
--@param id Id of the state to be set.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:state_unset_marked( id )
    local state = self.states:find( id )
    if not state then return end

    state.marked = false

    return true
end

---Return if a state of the automaton is marked or not.
--Verifies if the state represented by 'id' exists. Returns its marked property.
--@param self Automaton in which the operation is applied.
--@param id Id of the state to be verified.
--@return True if the state is marked, false/nil otherwise.
function Automaton:state_get_marked( id )
    local state = self.states:find( id )
    if not state then return end

    return state.marked
end

--Teste do id-name
function Automaton:state_get_name( id )
    local state = self.states:find( id )
    if not state then return end
    
    return state.name

end

---Sets the name of a state of the automaton.
--Verifies if the state represented by 'id' exists. Sets its name to 'name'.
--@param self Automaton in which the operation is applied.
--@param id Id of the state to be set.
--@param name New name of the state.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:state_set_name( id, name )
    local state = self.states:find( id )
    if not state then return end

    state.name = tostring( name )

    return true
end

---Sets the position of a state of the automaton.
--Verifies if the state represented by 'id' exists. Sets its x coordinate to 'x' and its y coordinate to 'y'.
--@param self Automaton in which the operation is applied.
--@param id Id of the state whose position is set.
--@param x New x coordinate of the state.
--@param y New y coordinate of the state.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:state_set_position( id, x, y )
    local state = self.states:find( id )
    if not state then return end

    state.x = x
    state.y = y

    return true
end

---Returns the position of a state of the automaton.
--Verifies if the state represented by 'id' exists. Returns its x and y coordinates.
--@param self Automaton in which the operation is applied.
--@param id Id of the state whose position is returned.
--@return X coordinate of the state.
--@return Y coordinate of the state.
function Automaton:state_get_position( id )
    local state = self.states:find( id )
    if not state then return end

    return state.x, state.y
end

---Sets the radius of a state of the automaton.
--Verifies if the state represented by 'id' exists. Sets its radius to 'r'.
--@param self Automaton in which the operation is applied.
--@param id Id of the state to be set.
--@param r New radius of the state.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:state_set_radius( id, r )
    local state = self.states:find( id )
    if not state then return end

    state.r = r

    return true
end

---Returns the radius of a state of the automaton.
--Verifies if the state represented by 'id' exists. Returns its radius.
--@param self Automaton in which the operation is applied.
--@param id Id of the state whose radius is returned.
--@return Radius of the state.
function Automaton:state_get_radius( id )
    local state = self.states:find( id )
    if not state then return end

    return state.r
end

---Position the states of the automaton in an intelligent way.
--Defines constants to the forces. Treats each state of the automaton as a node and each transition as an edge. Creates repulsion forces between nodes and attraction forces based on the edges and the distance from a node to the center of the screen. When the simulation is steady (or an iteration limit is reached), sets the states positions to the nodes positions.
function Automaton:position_states()
    local nodes = self.states:len()
    local desac = 0.9
    local vmax = 3
    local vmin = 0.01

    local force = {}
    force.center = 6*10^-3
    force.vertex = 3*10^4
    force.edge = 0.3

    local v = {}
    local m = {}
    local smap = {}
    for i,state in self.states:ipairs() do
        v[i] = {}
        v[i].x = state.x
        v[i].y = state.y
        v[i].vx = 0
        v[i].vy = 0
        m[i] = {}
        smap[state] = i
    end

    for _,transition in self.transitions:ipairs() do
        local i = smap[transition.source]
        local j = smap[transition.target]
        if i~=j then
            m[i][j] = true
            m[j][i] = true
        end
    end

    for frame=1,500*nodes do

        local dx, dy, hip
        local unstable = false

        for i in ipairs(v) do
            --Center
            dx = v[i].x
            dy = v[i].y
            hip = (dx^2 + dy^2) ^ 0.5
            if hip>0 then
                v[i].vx = v[i].vx - force.center*dx
                v[i].vy = v[i].vy - force.center*dy
            end

            --Vertex
            for j in ipairs(v) do
                dx = v[i].x-v[j].x
                dy = v[i].y-v[j].y
                hip = (dx^2 + dy^2) ^ 0.5
                if hip>0 then
                    v[i].vx = v[i].vx + force.vertex*dx/(hip^3)
                    v[i].vy = v[i].vy + force.vertex*dy/(hip^3)
                end
            end

            --Edge
            for j in pairs(m[i]) do
                dx = v[i].x-v[j].x
                dy = v[i].y-v[j].y
                hip = (dx^2 + dy^2) ^ 0.5
                if hip>0 then
                    v[i].vx = v[i].vx - force.edge*dx/hip
                    v[i].vy = v[i].vy - force.edge*dy/hip
                end
            end

            --Limit velocity
            v[i].vx = v[i].vx*desac
            v[i].vy = v[i].vy*desac
            dx = v[i].vx
            dy = v[i].vy
            hip = (dx^2 + dy^2) ^ 0.5
            if hip>vmax then
                v[i].vx = dx/hip*vmax
                v[i].vy = dy/hip*vmax
            end
            if hip>vmin then
                unstable = true
            end
        end

        if not unstable then
            break
        end

        --Apply velocity
        for i=1,nodes do
            v[i].x = v[i].x + v[i].vx
            v[i].y = v[i].y + v[i].vy
        end

    end

    local minx = 1/0
    local miny = 1/0
    for i,state in self.states:ipairs() do
        state.x = v[i].x + 400
        state.y = v[i].y + 300
        --~ if state.x - state.r < minx then
        if state.x < minx then
            --~ minx = state.x - state.r
            minx = state.x
        end
        --~ if state.y - state.r < miny then
        if state.y < miny then
            --~ miny = state.y - state.r
            miny = state.y
        end
    end
    for i,state in self.states:ipairs() do
        state.x = state.x - minx + 30
        state.y = state.y - miny + 30
    end
end

--Events

---Adds a new event to the automaton.
--Creates a event that is not in any transitions, with properties according to the arguments 'name', 'observable' and 'controllable'. Inserts the new event in the automaton.
--@param self Automaton in which the operation is applied.
--@param name Name of the new event.
--@param observable If true, the new event is observable.
--@param controllable If true, the new event is controllable.
--@param refinement Name of the event refined by the new event.
--@param id Forced id of the event.
--@return Id of the new event.
--@return New event itself.
function Automaton:event_add(name, observable, controllable, refinement, id)
    if observable == nil   then observable = true end
    if controllable == nil then controllable = true end
    local new_event = {
        name         = name or 'new',
        observable   = observable or false,
        controllable = controllable or false,
        refinement   = refinement or '',
        --workspace    = workspace,
        transitions  = letk.List.new(),
    }

    if not id then
        id = self.events:append( new_event )
    else
        self.events:add(new_event, id)
    end

    --TODO: change the workspace concept for an EventSet architecture
    --if workspace then
    --  workspace.automata[self] = new_event
    --end

    return id, new_event
end

---Removes an event from the automaton.
--Verifies if the event identified by 'id' exists. Removes any transition with this event from the automaton. Removes the event from the event list of the automaton.
--@param self Automaton in which the operation is applied.
--@param id Id of the event to be removed.
--@see Automaton:transition_remove
function Automaton:event_remove( id )
    local event, event_id = self.events:find( id )
    if not event then return end

    while true do
        local trans = event.transitions:find( function() return true end )
        if not trans then break end

        self:transition_remove( trans )
    end

    --event.workspace.automata[self] = nil

    self.events:remove( event_id )
end

---Sets an event of the automaton to observable.
--Verifies if the event represented by 'id' exists. Sets it to observable.
--@param self Automaton in which the operation is applied.
--@param id Id of the event to be set.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:event_set_observable( id )
    local event = self.events:find( id )
    if not event then return end

    event.observable = true

    return true
end

---Verifies if an event of the automaton is observable.
--Verifies if the event represented by 'id' exists. Returns its observable property.
--@param self Automaton in which the operation is applied.
--@param id Id of the event to be verified.
--@return True if the event is observable. False/nil otherwise.
function Automaton:event_get_observable( id )
    local event = self.events:find( id )
    if not event then return end

    return event.observable
end

---Sets an event of the automaton to unobservable.
--Verifies if the event represented by 'id' exists. Sets it to unobservable.
--@param self Automaton in which the operation is applied.
--@param id Id of the event to be set.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:event_unset_observable( id )
    local event = self.events:find( id )
    if not event then return end

    event.observable = false

    return true
end

---Sets an event of the automaton to controllable.
--Verifies if the event represented by 'id' exists. Sets it to controllable.
--@param self Automaton in which the operation is applied.
--@param id Id of the event to be set.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:event_set_controllable( id )
    local event = self.events:find( id )
    if not event then return end

    event.controllable = true

    return true
end

---Sets an event of the automaton to uncontrollable.
--Verifies if the event represented by 'id' exists. Sets it to controllable.
--@param self Automaton in which the operation is applied.
--@param id Id of the event to be set.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:event_unset_controllable( id )
    local event = self.events:find( id )
    if not event then return end

    event.controllable = false

    return true
end

---Verifies if an event of the automaton is controllable.
--Verifies if the event represented by 'id' exists. Returns its controllable property.
--@param self Automaton in which the operation is applied.
--@param id Id of the event to be verified.
--@return True if the event is controllable. False/nil otherwise.
function Automaton:event_get_controllable( id )
    local event = self.events:find( id )
    if not event then return end

    return event.controllable

end

---Sets the name of an event of the automaton.
--Verifies if the event identified by 'id' exists. Filters 'name', removing any characters that are not alphanumeric, "_", or "&". If 'name' has the susbstring "&" or "EMPTYWORD", it is set to "&". The event name is set to 'name'.
--@param self Automaton in which the operation is applied.
--@param id Id of the event to be set.
--@param name New name of the event.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:event_set_name( id, name )
    local event = self.events:find( id )
    if not event then return end
    if name ~= '&' then
        name = name:gsub('[^%w%_]','')
    end
    --~ name = name:gsub('[^%&%w%_]','')
    --~ if name:find('%&') then
        --~ name = '&'
    --~ end
    --~ if name:find('EMPTYWORD') then
        --~ name = '&'
    --~ end

    event.name = name

    return true
end

---Sets the refinement of an event of the automaton.
--Verifies if the event identified by 'id' exists. Filters 'ref', removing any characters that are not alphanumeric, "_", or "&". If 'ref' has the susbstring "&" or "EMPTYWORD", it is set to "&". The event refinement is set to 'ref'.
--@param self Automaton in which the operation is applied.
--@param id Id of the event to be set.
--@param ref New refinement of the event.
--@return True if no problems occurred, false/nil otherwise.
function Automaton:event_set_refinement( id, ref )
    local event = self.events:find( id )
    if not event then return end
    if ref ~= '&' then
        ref = ref:gsub('[^%w%_]','')
    end
    --~ ref = ref:gsub('[^%&%w%_]','')
    --~ if ref:find('%&') then
        --~ ref = '&'
    --~ end
    --~ if ref:find('EMPTYWORD') then
        --~ ref = '&'
    --~ end

    event.refinement = ref

    return true
end

---Sets the reference of an event of the automaton.
--Verifies if the event identified by 'id' exists. Gets the current reference of the event. Verifies if the new reference exists in the workspace. Sets the reference and copies its properties to the event.
--@param self Automaton in which the operation is applied.
--@param id Id of the event to be set.
--@param ref New refinement of the event.
--@return True if no problems occurred, false/nil otherwise.
--function Automaton:event_set_workspace(id, ws_name)
--  local event = self.events:get(id)
--  local wev1 = event.workspace
--  local wev2 = self.controller.events:find(function(ev)
--      return ev.name==ws_name
--  end)
--  if not wev2 then
--      return
--  end
--
--  wev1.automata[self] = nil
--  wev2.automata[self] = event
--  event.workspace = wev2
--  self:event_set_name(id, ws_name)
--  if wev2.controllable then
--      self:event_set_controllable(id)
--  else
--      self:event_unset_controllable(id)
--  end
--  if wev2.observable then
--      self:event_set_observable(id)
--  else
--      self:event_unset_observable(id)
--  end
--  self:event_set_refinement(id, wev2.refinement)
--
--  return true
--end


--Transitions

---Adds a transition to the automaton.
--Searchs fot the states represented by 'source_id' and 'target_id' and for the event represented by 'event_id'. If 'isdata' is true, the ids are treated as the states/event themselves. Sets the combination event-target on the source state and event-source on the target state to true. Adds the transition to the transition lists of the source state, target state and event.
--@param self Automaton in which the operation is applied.
--@param source_id Id of the source state.
--@param target_id Id of the target state.
--@param event_id Id of the event used in the transition.
--@param isdata If true, the id's are interpreted as id's. Otherwise, they are interpreted as what they represent (e.g. state_id represents a state).
--@param id Forced id of the transition.
--@return Id of the new transition.
--@return New transition itself.
function Automaton:transition_add( source_id, target_id, event_id, isdata, id )
    local event  = not isdata and self.events:find( event_id )  or event_id
    local source = not isdata and self.states:find( source_id ) or source_id
    local target = not isdata and self.states:find( target_id ) or target_id

    source.event_target[event] = source.event_target[event] or {}
    target.event_source[event] = target.event_source[event] or {}
    source.target_trans_factor[ target ] = source.target_trans_factor[ target ] or 2.0

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

    if not id then
        id = self.transitions:append( transition )
    else
        self.transitions:add(transition, id)
    end

    source.transitions_out:append( transition )
    target.transitions_in:append( transition )
    event.transitions:append( transition )

    return id, transition
end

---Removes a transition from the automaton.
--Finds the transition represented by 'id' in the transition list. Removes that transition from the transition list of the source state, target state, event and automaton. Sets the combination event-target on the source state and event-source on the target state to nil.
--@param self Automaton in which the operation is applied.
--@param id Id of the transition to be removed.
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
    --source.target_trans_factor[ target ] still there
end

---Changes the factor of a transition
--Finds the transition represented by 'id'. Sets it's factor to 'factor'.
--@param id Id of the transition.
--@param factor New factor.
function Automaton:transition_set_factor( id, factor )
    local trans, trans_id = self.transitions:find( id )
    if not trans then return end

    trans.factor = factor

    return true
end

------------------------------------------------------------------------
--                          operations                               --
------------------------------------------------------------------------

---Imports an automaton from IDES.
--TODO
--@param self Automaton in which the operation is applied.
--@param file_name Name of the file to be imported.
--@param get_layout For some reason, it is always set to true. TODO
--@return Imported automaton.
--@see Automaton:state_add
--@see Automaton:state_set_initial
--@see Automaton:state_set_marked
--@see Automaton:event_add
--@see Automaton:event_set_observable
--@see Automaton:event_set_controllable
--@see Automaton:transition_add
--@see Automaton:state_set_position
--@see Automaton:state_set_name
--@see Automaton:event_set_name
--@see Object:set
--@see Automaton:create_log
function Automaton:IDES_import( file_name, get_layout )
    if get_layout == nil then
        get_layout      = true
    end
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

--  local file  = io.open(file_name)
--  local doc = luaxml2es.parse(file:read('*a'))
--  file:close()
--
--  for data_child in doc.root:find('data').children do
--      if data_child.name == 'state' then
--          sm                          = t.s
--            last_id, last_obj           = self:state_add( data_child:prop('id'), false, false )
--            map_state[ data_child:prop('id') ]     = last_id
--            map_state_obj[ data_child:prop('id') ] = last_obj
--
--          if data_child:find('properties'):find('initial') then
--              self:state_set_initial( last_id )
--          end
--          if data_child:find('properties'):find('marked') then
--              self:state_set_marked( last_id )
--          end
--          self:state_set_name( last_id, data_child:find('name').content )
--      end
--      if data_child.name == 'event' then
--              sm                          = t.e
--                last_ev, last_obj           = self:event_add()
--                map_event[ data_child:prop('id') ]     = last_ev
--                map_event_obj[ data_child:prop('id') ] = last_obj
--
--              if data_child:find('properties'):find('observable') then
--                  self:event_set_observable( last_ev )
--              end
--              if data_child:find('properties'):find('controllable') then
--                  self:event_set_controllable( last_ev )
--              end
--
--              self:event_set_name( last_id , data_child:find('name').content )
--      end
--      if data_child.name == 'transition' then
--          local source = map_state_obj[ data_child:prop('source') ]
--            local target = map_state_obj[ data_child:prop('target') ]
--            local event  = map_event_obj[ data_child:prop('event') ]
--            self:transition_add( source, target, event, true )
--      end
--  end
--
--  for meta_child in doc.root:find('meta').children do
--      if meta_child.name == 'state' then
--          last_id = map_state[ meta_child:prop('id') ]
--            sm      = t.s
--          if get_layout then
--              --print(meta_child:find('circle'):prop('x'))
--              local x,y = select( 3, meta_child:find('circle'):prop('x'):find('(%d+)') ),  select( 3, meta_child:find('circle'):prop('y'):find('(%d+)') )
--              self:state_set_position( last_id, x, y)
--          end
--      end
--      if meta_child.name == 'transition' then
--          sm      = t.t
--      end
--      if meta_child.name == 'event' then
--          sm      = t.e
--      end
--  end

    self:set('full_file_name', file_name)
    self:set('file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
    self:set('file_type', 'xmd')

    --self:create_log()

    return self
end

local function calculate_angle(x, y)
    local angle
    local r = math.pow(x*x + y*y, 0.5)
    if r==0 then
        return 0, r
    end
    angle = math.acos(x/r)
    if y<0 then
        angle = 2*math.pi-angle
    end
    return angle, r
end

local FILE_ERRORS = {}
FILE_ERRORS.ACCESS_DENIED     = 1
FILE_ERRORS.NO_FILE_NAME      = 2
FILE_ERRORS.INVALID_FILE_TYPE = 3

---Exports the automaton to IDES.
--Verifies if 'file_name' has sulfix .xmd, if not, adds it. Opens the file and writes the header. For each state, writes its id, name and properties initial and marked. For each event, writes its id, name and properties controllable and observable. For each transition, writes its id, source, target and event. Then, for each state, writes its radius, x and y. For each transition, writes its source, target and control coordinates.
--@param self Automaton in which the operation is applied.
--@param file_name Name of the file to be exported.
--@return True if no problems occurred, false otherwise.
--@return Ids of any errors that occurred.
--@see Object:get
--@see Object:set
function Automaton:IDES_export( file_name )
    local smap, emap, ctrlx1, ctrly1, ctrlx2, ctrly2, angle, r, sx, sy, tx, ty, name, _

    if not file_name and self:get('file_type')=='xmd' then
        file_name = self:get('full_file_name')
    end

    if file_name then
        if not file_name:match( '%.xmd$' ) then
            file_name = file_name .. '.xmd'
        end
        local file = io.open( file_name, 'w')
        if file then
            name = file_name:match('(.*)%.xmd$')
            while name:match('\\(.-)$') do
                name = name:match('\\(.-)$')
            end
            file:write('<?xml version="1.0" encoding="UTF-8"?>\n')
            file:write('<model version="2.1" type="FSA" id="', name, '">\n')
            file:write('<data>\n')
            smap = {}
            for k_state, state in self.states:ipairs() do
                smap[state] = k_state
                file:write('\t<state id="', k_state, '">\n')
                if state.initial or state.marked then
                    file:write('\t\t<properties>\n')
                    if state.initial then
                        file:write('\t\t\t<initial />\n')
                    end
                    if state.marked then
                        file:write('\t\t\t<marked />\n')
                    end
                    file:write('\t\t</properties>\n')
                else
                    file:write('\t\t<properties/>\n')
                end
                file:write('\t\t<name>', state.name, '</name>\n')
                file:write('\t</state>\n')
            end
            emap = {}
            for k_event, event in self.events:ipairs() do
                emap[event] = k_event
                file:write('\t<event id="', k_event, '">\n')
                if event.controllable or event.observable then
                    file:write('\t\t<properties>\n')
                    if event.controllable then
                        file:write('\t\t\t<controllable />\n')
                    end
                    if event.observable then
                        file:write('\t\t\t<observable />\n')
                    end
                    file:write('\t\t</properties>\n')
                else
                    file:write('\t\t<properties/>\n')
                end
                file:write('\t\t<name>', event.name, '</name>\n')
                file:write('\t</event>\n')
            end
            for k_transition, transition in self.transitions:ipairs() do
                file:write('\t<transition id="', k_transition, '" source="', smap[transition.source], '" target="', smap[transition.target], '" event="', emap[transition.event], '">\n')
                file:write('\t</transition>\n')
            end
            file:write('</data>\n')
            file:write('<meta tag="layout" version="2.1">\n')
            file:write('\t<font size="16.0"/>\n')
            file:write('\t<layout uniformnodes="false"/>\n')
            for k_state, state in self.states:ipairs() do
                file:write('\t<state id="', k_state, '">\n')
                file:write('\t\t<circle r="', state.r, '" x="', state.x, '" y="', state.y, '" />\n')
                file:write('\t\t<arrow x="1.0" y="0.0" />\n')
                file:write('\t</state>\n')
            end
            for k_transition, transition in self.transitions:ipairs() do
                file:write('\t<transition id="', k_transition, '">\n')
                sx = transition.source.x
                sy = transition.source.y
                tx = transition.target.x
                ty = transition.target.y
                if transition.source~=transition.target then
                    --normal transition
                    angle, r = calculate_angle(tx-sx, ty-sy)
                    ctrlx1 = sx - r/3*math.cos(angle+math.pi-math.pi/6)
                    ctrly1 = sy - r/3*math.sin(angle+math.pi-math.pi/6)
                    ctrlx2 = tx - r/3*math.cos(angle+math.pi/6)
                    ctrly2 = ty - r/3*math.sin(angle+math.pi/6)
                else
                    --self-loop
                    ctrlx1 = sx - 3*transition.source.r
                    ctrly1 = sy - 3*transition.source.r
                    ctrlx2 = sx + 3*transition.source.r
                    ctrly2 = ctrly1
                end
                file:write('\t\t<bezier x1="', sx, '" y1="', sy, '" x2="', tx, '" y2="', ty, '" ctrlx1="', ctrlx1, '" ctrly1="', ctrly1, '" ctrlx2="', ctrlx2, '" ctrly2="', ctrly2, '" />\n')
                file:write('\t\t<label x="5.0" y="5.0" />\n')
                file:write('\t</transition>\n')
            end
            file:write('</meta>\n')
            file:write('</model>\n')

            file:close()

            if self:get( 'file_type' ) ~= 'nza' then
                self:set( 'file_type', 'xmd' )
                self:set( 'full_file_name', file_name )
                self:set( 'file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
            end

            return true
        end
        return false, FILE_ERRORS.ACCESS_DENIED, FILE_ERRORS
    else
        return false, FILE_ERRORS.NO_FILE_NAME, FILE_ERRORS
    end
end

---Imports an automaton from TCT.
--Verifies if the file 'file_name' exists. Parses the file. Copies the states, events and transitions from the file to the automaton.
--@param file_name Name of the file to be imported.
--@param workspace_events Workspace events list.
--@see Automaton:state_add
--@see Automaton:state_set_initial
--@see Automaton:state_set_marked
--@see Controller.add_event
--@see Automaton:event_add
--@see Automaton:transition_add
--@see Object:set
--@see Automaton:create_log
function Automaton:TCT_import( file_name )
    local workspace_events = self.controller.events
    local file = io.open( file_name, 'r')
    if file then
        local s    = file:read('*a')

        --clean code
        s = string.gsub(s, '\r', ' ')       --remove \r
        s = string.gsub(s, '  +', ' ')      --remove double spaces
        s = string.gsub(s, '\n +', '\n')    --remove spaces on the beggining of new lines
        s = string.gsub(s, ' +\n', '\n')    --remove spaces on the end of new lines
        s = string.gsub(s, '^ +', '')       --remove spaces on the beggining of the file
        s = string.gsub(s, ' +$', '')       --remove spaces on the end of the file
        s = string.gsub(s, '\n+$', '\n')    --remove empty lines
        s = string.gsub(s, '^\n+', '')      --remove empty lines at the beggining of the file
        s = string.gsub(s, '\n*$', '\n')    --remove empty lines at the end of the file
        if not string.match(s, '\n$') then
            s = s .. '\n'                   --add '\n' to the end of the file
        end
        s = string.gsub(s, '#.-\n', '')     --delete lines whose first caracter is '#'
        s = string.lower(s)                 --lower letters

        local state_num = tonumber(string.match(s, 'state size.-\n(.-)\n')) or 0
        if state_num>0 then
            for i=0,state_num-1 do
                self:state_add(tostring(i), false, false)
            end
            self:state_set_initial(1)
            for id in string.gmatch(string.match(s, 'marker states.-\n(.-)vocal states'), '%d+') do
                self:state_set_marked(id+1)
            end
        end

        local event_map = {}
        local n,c = 0,1
        for k_event, event in workspace_events:ipairs() do
            if event.controllable then
                event_map[c] = event
                c = c + 2
            else
                event_map[n] = event
                n = n + 2
            end
        end

        local atm_ev_map = {}
        for trans in string.gmatch(string.match(s, 'transitions.-\n(.-)$'), '%d+ %d+ %d+') do
            local source, event, target = string.match(trans, '(%d+) (%d+) (%d+)')
            source = tonumber(source)
            event = tonumber(event)
            target = tonumber(target)
            if not event_map[event] then
                event_map[event] = self.controller:add_event('$' .. event, event%2~=0, nil, nil)
            end
            local e = event_map[event]
            if not atm_ev_map[e] then
                atm_ev_map[e] = self:event_add(e.name, e.observable, e.controllable, e.refinement, e)
            end
            self:transition_add(source+1, target+1, atm_ev_map[e], false)
        end

        self:set( 'file_type', 'ADS' )
        self:set( 'full_file_name', file_name )
        self:set( 'file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )

        file:close()

        --~ self:create_log()
    end
end

---Exports an automaton to TCT.
--TODO
--@param file_name Name of the file to be exported.
--@param workspace_events Workspace events list.
--@see Object:get
--@see Object:set
function Automaton:TCT_export( file_name )
    --local workspace_events = self.controller.events
    local smap = {}
    local s = 1
    for k_state, state in self.states:ipairs() do
        if k_state~=self.initial then
            smap[state] = s
            s = s + 1
        else
            smap[state] = 0
        end
    end

    local emap = {}
    local n,c = 0,1
    for k_event, event in self.events:ipairs() do
        if event.controllable then
            --if event.automata[self] then
            --    emap[ event.automata[self] ] = c
            --end
            emap[ event ] = c
            c = c + 2
        else
            --if event.automata[self] then
            --    emap[ event.automata[self] ] = n
            --end
            emap[ event ] = n
            n = n + 2
        end
    end

    if not file_name and self:get('file_type')=='ADS' then
        file_name = self:get('full_file_name')
    end

    if file_name then --TODO: fix extension case to lower case.
        if not file_name:match( '%.ads$' ) then
            file_name = file_name .. '.ads'
        end
        --print('TCS export opens', file_name)
        local file = io.open( file_name, 'w')
        if file then
            name = file_name:match('(.*)%.ADS$')
            while name:match('\\(.-)$') do
                name = name:match('\\(.-)$')
            end
            file:write('# CTCT ADS auto-generated\n')
            file:write('\n' .. string.match(file_name, '([^\\]+)%.ADS$') .. '\n')
            file:write('\nState size (State set will be (0,1....,size-1)):\n')
            file:write('# <-- Enter state size, in range 0 to 2000000, on line below.\n')
            file:write(self.states:len() .. '\n')
            file:write('\nMarker states:\n')
            file:write('# <-- Enter marker states, one per line.\n')
            file:write('# To mark all states, enter *.\n')
            file:write('# If no marker states, leave line blank.\n')
            file:write('# End marker list with blank line.\n')
            for k_state, state in self.states:ipairs() do
                if state.marked then
                    file:write(smap[state] .. '\n')
                end
            end
            file:write('\nVocal states:\n')
            file:write('# <-- Enter vocal output states, one per line.\n')
            file:write('# Format: State  Vocal_Output.  Vocal_Output in range 10 to 99.\n')
            file:write('# Example: 0 10\n')
            file:write('# If no vocal states, leave line blank.\n')
            file:write('# End vocal list with blank line.\n')
            file:write('\nTransitions:\n')
            file:write('# <-- Enter transition triple, one per line.\n')
            file:write('# Format: Exit_(Source)_State  Transition_Label  Entrance_(Target)_State.\n')
            file:write('# Transition_Label in range 0 to 999.\n')
            file:write('# Example: 2 0 1 (for transition labeled 0 from state 2 to state 1).\n')
            for k_transition, transition in self.transitions:ipairs() do
                file:write(smap[transition.source] .. ' ' .. emap[transition.event] .. ' ' .. smap[transition.target] .. '\n')
            end
            file:write('\n')

            file:close()

            if self:get( 'file_type' ) ~= 'nza' then
                self:set( 'file_type', 'ADS' )
                self:set( 'full_file_name', file_name )
                self:set( 'file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
            end

            return true
        end
        return false, FILE_ERRORS.ACCESS_DENIED, FILE_ERRORS
    else
        return false, FILE_ERRORS.NO_FILE_NAME, FILE_ERRORS
    end
end

---Serializes the automaton, so it can be saved.
--TODO
--@param self Automaton to be serialized.
--@return Serialized automaton.
function Automaton:save_serialize()
    local data                 = {
        states        = {},
        events        = {},
        transitions   = {},
        --type        = self.type,
        --level       = self.level,
        radius_factor = self.radius_factor,
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
            refinement   = event.refinement or '',
        }
    end

    for k_transition, transition in self.transitions:ipairs() do
        data.transitions[ #data.transitions + 1 ] = {
            source = state_map[ transition.source ],
            target = state_map[ transition.target ],
            event = event_map[ transition.event ],
            factor = transition.factor,
        }
    end

    return letk.serialize( data )
end

---Saves the automaton in its current file.
--Gets the file of the automaton. If it hasn't the format .nza, this format is added. Saves the automaton to the file.
--@param self Automaton to be saved.
--@return True if no problems occurred, false otherwise.
--@return Ids of any errors that occurred.
--@see Automaton:save_serialize
--@see Object:get
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
        return false, FILE_ERRORS.ACCESS_DENIED, FILE_ERRORS
    elseif not file_type then
        return false, FILE_ERRORS.NO_FILE_NAME, FILE_ERRORS
    else
        return false, FILE_ERRORS.INVALID_FILE_TYPE, FILE_ERRORS
    end
end

---Saves the automaton to a file.
--TODO
--@param self Automaton to be saved.
--@param file_name Name of the file where the automaton will be saved.
--@return True if no problems occurred, false otherwise.
--@return Ids of any errors that occurred.
--@see Automaton:save_serialize
--@see Object:set
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
        return false, FILE_ERRORS.ACCESS_DENIED, FILE_ERRORS
    else
        return false, FILE_ERRORS.NO_FILE_NAME, FILE_ERRORS
    end
end

---Loads the automaton from a file.
--TODO
--@param self Automaton where informations will be loaded.
--@param file_name Name of the file to be loaded.
--@see Automaton:state_add
--@see Automaton:event_add
--@see Automaton:transition_add
--@see Object:set
--@see Automaton:create_log
function Automaton:load_file( file_name )
    local file = io.open( file_name, 'r')
    if file then
        local s    = file:read('*a')
        local data = loadstring('return ' .. s)()
        local state_map, event_map = {}, {}
        if data then
--            self.type          = data.type or self.type
--          self.level         = data.level or self.level
            self.radius_factor = data.radius_factor or self.radius_factor
            for k_state, state in ipairs( data.states ) do
                local id, new_state = self:state_add( state.name, state.marked, state.initial )
                new_state.x         = state.x
                new_state.y         = state.y
                --~ new_state.r         = state.r
                state_map[id]       = new_state
            end
            for k_event, event in ipairs( data.events ) do
                local id, new_event = self:event_add( event.name, event.observable, event.controllable, event.refinement )
                event_map[id]       = new_event
            end
            for k_transition, transition in ipairs( data.transitions ) do
                self:transition_add( state_map[transition.source], state_map[transition.target], event_map[transition.event], true )
            end
            self:set( 'file_type', 'nza' )
            self:set( 'full_file_name', file_name )
            self:set( 'file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
        end
        file:close()

        --self:create_log()
    end
end

---Returns number of states in the automaton.
--Returns the number of elements in the state list of the automaton.
--@param self Automaton in which the operation is applied.
--@return Number of states in the automaton.
function Automaton:state_len( )
    return self.states:len()
end

---Returns number of events in the automaton.
--Returns the number of elements in the event list of the automaton.
--@param self Automaton in which the operation is applied.
--@return Number of events in the automaton.
function Automaton:event_len( )
    return self.events:len()
end

---Returns an event from the automaton.
--Returns the ev_num-th element in the event list of the automaton.
--@param self Automaton in which the operation is applied.
--@param ev_num Number of the event to be returned.
--@return An event from the automaton.
function Automaton:event_get( ev_num )
    return self.events:get(ev_num)
end

---Returns the name of an event from the automaton.
--Returns the name of the ev_num-th element in the event list of the automaton.
--@param self Automaton in which the operation is applied.
--@param ev_num Number of the event whose number is returned.
--@return Name of an event from the automaton.
function Automaton:event_get_name( ev_num )
    return self.events:get(ev_num).name
end

---Returns number of transitions in the automaton.
--Returns the number of elements in the event list of the automaton.
--@param self Automaton in which the operation is applied.
--@return Number of transitions in the automaton.
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

---Creates a copy of the automaton.
--Creates a new automaton and copies all states, events and transitions of 'self' to that automaton.
--@param self Automaton to be cloned.
--@return Copy of the automaton.
--@see Automaton:state_add
--@see Automaton:event_add
--@see Automaton:transition_add
--@see Controller.add_events_from_automaton
--@see Automaton:create_log
function Automaton:clone()
    --local new_automaton   = Automaton.new( self.controller )
    local new_automaton   = Automaton.new()
    local state_map = {}
    local event_map = {}
    local _
    for c, v in self.states:ipairs() do
        _, state_map[v] = new_automaton:state_add( v.name, v.marked, v.initial )
        --state_map[v].x = v.x
        --state_map[v].y = v.y
        --state_map[v].no_accessible = v.no_accessible
        --state_map[v].no_coaccessible = v.no_coaccessible
        --state_map[v].choice_problem = v.choice_problem
        --state_map[v].avalanche_effect = v.avalanche_effect
        --state_map[v].inexact_synchronization = v.inexact_synchronization
        --state_map[v].simultaneity = v.simultaneity
    end
    for c, v in self.events:ipairs() do
        _, event_map[v]= new_automaton:event_add(v.name, v.observable, v.controllable, v.refinement, v.workspace)
    end
    for c, v in self.transitions:ipairs() do
        new_automaton:transition_add( state_map[v.source], state_map[v.target], event_map[v.event], true )
    end

    --new_automaton.accessible_calc = self.accessible_calc
    --new_automaton.coaccessible_calc = self.coaccessible_calc
    --new_automaton.choice_problem_calc = self.choice_problem_calc
    --new_automaton.avalanche_effect_calc = self.avalanche_effect_calc
    --new_automaton.inexact_synchronization_calc = self.inexact_synchronization_calc
    --new_automaton.simultaneity_calc = self.simultaneity_calc
    --new_automaton.type = self.type
    --new_automaton.level = self.level
    --new_automaton.radius_factor = self.radius_factor

    --Controller.add_events_from_automaton(new_automaton.controller, new_automaton)

    --new_automaton:create_log()

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

---Calculates the accessible component of the automaton.
--All states of the automaton are initialized as no accessible. Accessible states are recursively calculated. If 'remove_states' is true, no accessible states are removed.
--@param self Automaton in which the operation is applied.
--@param remove_states If true, no accessible states of the automaton are removed.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@return Accessible component of the automaton.
--@see Automaton:clone
--@see remove_states_fn
--@see Automaton:create_log
function Automaton:accessible( remove_states, keep )
    if not self.initial then
        --gtk.InfoDialog.showInfo("Automaton doesn't have initial state. Operation can't be applied.")
        return
    end

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

    --if not keep then
    --  newautomaton:create_log()
    --end

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

---Calculates the coaccessible component of the automaton.
--All states of the automaton are initialized as no coaccessible. Coaccessible states are recursively calculated. If 'remove_states' is true, no coaccessible states are removed.
--@param self Automaton in which the operation is applied.
--@param remove_states If true, no coaccessible states of the automaton are removed.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@return Coaccessible component of the automaton.
--@see Automaton:clone
--@see remove_states_fn
--@see Automaton:create_log
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

    --if not keep then
    --  newautomaton:create_log()
    --end

    return newautomaton
end

---Joins in one unique state every no coaccessible state of the automaton.
--Calculates the coaccessible component of the automaton using function 'Automaton:coaccessible', but doesn't remove no coaccessible states. Creates a new state that will join all no coaccessible states. For every transition from a no coaccessible state to a no coaccessible state, adds a self-loop with this transition in the new state. For every transition from a coaccessible state to a no coaccessible state, adds this transition to that coaccessible state, having the new state as target. If the initial state is no coaccessible, makes the new state state become the initial state. Removes all no coaccessible states, except the new state.
--@param self Automaton in which the operation is applied.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@return Automaton with unique no coaccessible state.
--@see Automaton:coaccessible
--@see Automaton:state_add
--@see Automaton:transition_add
--@see Automaton:state_set_initial
--@see Automaton:remove_states_fn
--@see Automaton:create_log
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
                --if t.target.no_coaccessible then
                    newautomaton:transition_add( Snca_state, Snca_state, t.event, true )
                --end
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

    --if not keep then
    --  newautomaton:create_log()
    --end

    return newautomaton
end

---Calculates the trim component of the automaton.
--Calculates the coaccessible component of the automaton using function 'Automaton:coaccessible'. Calculates the accessible component of the automaton using function 'Automaton:accessible'. If 'remove_states' is true, no coaccessible or no accessible states are removed.
--@param self Automaton in which the operation is applied.
--@param remove_states If true, no coaccessible or no accessible states of the automaton are removed.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@return Trim component of the automaton.
--@see Automaton:coaccessible
--@see Automaton:accessible
--@see Automaton:create_log
function Automaton:trim( remove_states, keep )
    if not self.initial then
        --gtk.InfoDialog.showInfo("Automaton doesn't have initial state. Operation can't be applied.")
        return
    end

    local newautomaton = self:coaccessible( remove_states, keep ):accessible( remove_states, true )

    --if not keep then
    --  newautomaton:create_log()
    --end

    return newautomaton
end

---Creates self-loops in automaton 'self' according to the events in automata '...'.
--Maps all events of 'self'. For each event that is not in 'self' and is in at least one of the other automata, adds that event to the resulting automaton and creates a self-loop with this event in all states of the resulting automaton.
--@param self Automaton in which the operation is applied.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@param ... Automata whose events are used to create the self-loops.
--@return Automaton with self-loops.
--@see Automaton:clone
--@see Automaton:event_add
--@see Automaton:transition_add
--@see Automaton:create_log
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
                   event.name, event.observable, event.controllable, event.refinement, event.workspace
               )
            end
        end
    end

    for k_state, state in newautomaton.states:ipairs() do
        for nm_event, id_event in pairs( loop_events ) do
            newautomaton:transition_add( k_state, k_state, id_event, false )
        end
    end

    --if not keep then
    --  newautomaton:create_log()
    --end

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
                    event.name, event.observable, event.controllable, event.refinement, event.workspace
                )
            end
        end
    end

    for k_a, a in ipairs( all ) do
        for k_state, state in a.states:ipairs() do
            for nm_event, id_event in pairs( new_events[ k_a ]  ) do
                a:transition_add( k_state, k_state, id_event, false )
            end
        end
    end
end

---Check if all automata have an initial state.
--@param ... Automata in which test is performed
--@return status<boolean> true if all automata have initial state, false if one or more do not have
--@return table list of automata name without initial state or nil if all are ok.
local function checkForInitialState( ... )
    local all           = { ... }
    local errorAutomata = {}
    for k_a, a in ipairs( all ) do
        if not a.initial then
            table.insert( errorAutomata, a:get( 'file_name' ) )
        end
    end

    if #errorAutomata > 0 then
        return false, errorAutomata
    else
        return true
    end
end

---Calculates the synchronization/parallel composition of the automata '...' and 'self'.
--Creates self-loops in the automata. Calculates the product of the automata using 'Automaton:product'.
--@param self Automaton in which the operation is applied.
--@param ... Automata in which the operation is applied.
--@return Synchronized automaton.
--@see Automaton:clone
--@see Automaton:product
--@see Automaton:create_log
function Automaton:synchronization( ... )
    local allHaveInitialState, noInitialStateList = checkForInitialState( self, ... )
    if not allHaveInitialState then
        return false, noInitialStateList
    end

    local all           = { self, ... }
    local new_all       = {}

    for k_a, a in ipairs( all ) do
        new_all[ k_a ] = a:clone()
    end

    selfloopall( unpack( new_all ) )

    local newautomaton = Automaton.product( unpack( new_all ) )
    --newautomaton:create_log()
    return newautomaton
end

---Calculates the product/intersection/meet of the automata '...' and 'self'.
--TODO
--@param self Automaton in which the operation is applied.
--@param ... Automata in which the operation is applied.
--@return Product automaton.
--@see Automaton:event_add
--@see Automaton:state_add
--@see Automaton:create_log
function Automaton:product( ... )
    local allHaveInitialState, noInitialStateList = checkForInitialState( self, ... )
    if not allHaveInitialState then
        return false, noInitialStateList
    end

    local all           = { self, ... }
    local new_automaton = Automaton.new()
    new_automaton.level = self.level

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
                events[ e_nm ].name, events[ e_nm ].observable, events[ e_nm ].controllable, events[ e_nm ].refinement
            )
        else
            events[ e_nm ] = nil
        end
    end

    --Create transitions map
    local transitions_map    = {}
    local state_num_data_map = {}
    local tabini             = {} --???
    local tab_states         = {} --???
    local posit=1                 --???
    for k_a, a in ipairs( all ) do
        transitions_map[ k_a ]    = {}
        state_num_data_map[ k_a ] = {}
        local states_map       = {}
        tab_states[k_a]={} --???
        local flagini=0 --???
        for k_s, s in a.states:ipairs() do
            for teta,zeta in pairs(s) do --??? CHECK THIS BLOCK     
                zeta=tostring(zeta) --???
                if teta == "initial" and zeta == "true" then --???
                    flagini=1 --???
                end              --???
                if teta == "name" and flagini==1 then --???
                    tabini[posit]=zeta --???
                    flagini=0 --???
                    posit=posit+1 --???
                end --???
                if teta=="name" then --???
                    tab_states[k_a][k_s] = zeta --???
                end --???
            end --???                                                   
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
    local name_ini      = table.concat(tabini, ',') --???
    created_states_id, created_states_data[ state_map_id ] = new_automaton:state_add(
        name_ini, marked, true
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
            new_stack_names={} --???
            marked      = true
            for k_a, a in ipairs( all ) do
                local target = transitions_map[ k_a ][ current[k_a] ][ e_nm ]
                if  target then
                    new_stack[ k_a ] = target
                    new_stack_names[k_a] = tab_states[k_a][target]  --???
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
                new_name_id = table.concat(new_stack_names, ',') --???
                if not created_states_data[ state_map_id ] then
                    created_states_id, created_states_data[ state_map_id ] = new_automaton:state_add(
                        new_name_id, marked, false
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

    --new_automaton:create_log()

    return new_automaton
end

---Calculates the projection of the sequence of some pre selected events.  .
--TODO
function Automaton:projection( ... )
    local map_events = { ... }
    local transitions_map=   {}
    local states_map       = {}
    local new_transitions_map= {}
    local new_stack= {}
    local n_fim,var_event
    local bixo_feio         ={}
    local j=1
    
    local new_automaton = Automaton.new(self.controller)
    new_automaton.level = self.level
    
    local events        = {}
    local events_count  = {}
    
     local events        = {}
    local events_count  = {}
    for k_a, a in ipairs( self ) do
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
                events[ e_nm ].name, events[ e_nm ].observable, events[ e_nm ].controllable, events[ e_nm ].refinement, events[ e_nm ].workspace
            )
        else
            events[ e_nm ] = nil
        end
    end
    
    for k_s, s in self.states:ipairs() do                                               
            transitions_map[ k_s ]    = {}
            states_map[ s ]                  = k_s
    end
    var_event="a"   
    for k_s, s in self.states:ipairs() do
        for k_e, e in s.transitions_out:ipairs() do
            if (e.event.name) then
                transitions_map[ k_s ][ e.event.name ] = states_map[ e.target ] --coloca os eventos e afins em uma tabela
                if (e.event.name)== var_event then
                    print(k_s .. "," ..  states_map[ e.target ])
                    bixo_feio=states_map[e.target]
                    print(bixo_feio)
                end
            end
        end
    end
    print (table.concat(transitions_map[bixo_feio], ','))
    
end



---Calculates the max controllable language of a plant and a language.
--TODO
--@param G Plant in which the operation is applied.
--@param K Language in which the operation is applied.
--@return Max controllable language.
--@see Automaton:clone
--@see Automaton:create_log
function Automaton.supC(G, K)
    local allHaveInitialState, noInitialStateList = checkForInitialState( G, K )
    if not allHaveInitialState then
        return false, noInitialStateList
    end

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

    --R:create_log()

    return R
end

local function show_problem_result(problem_name, problem_list)
    if problem_list:len()==0 then
        --gtk.InfoDialog.showInfo("The automaton doesn't have the " .. problem_name .. " problem.")
    else
        --Selector.new({
        --    title = problem_name,
        --    success_fn = function( results, numresult ) end,
        --    no_cancel = true,
        --})
        --:add_multipler{
        --    list = problem_list,
        --    text_fn  = function( a )
        --        return a.state
        --    end,
        --    filter_fn = function( v )
        --        return true
        --    end,
        --    text = "States:"
        --}
        --:add_multipler{
        --    list = problem_list,
        --    text_fn  = function( a )
        --        return a.events
        --    end,
        --    filter_fn = function( v )
        --        return true
        --    end,
        --    text = "Events:"
        --}
        --:run()
    end
end

---Verifies if the automaton has the choice problem.
--For each state that has at least two transitions with controllable events, verifies if after the occurrence of an controllable event in this state, any other controllable event from the original state can still occur, reaching the same target state.
--@param self Automaton in which the operation is applied.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@return Automaton with choice problem checked.
--@see Automaton:clone
--@see Automaton:create_log
function Automaton:check_choice_problem( keep )
    local newautomaton = keep and self or self:clone()
    local problem_list = letk.List.new()

    --create a map(s_ce) Q,e --> Qa
    local s_ce = {}
    for k_s, s in newautomaton.states:ipairs() do
        s_ce[ s ] = {}
        for k_t, t in s.transitions_out:ipairs() do
            if t.event.controllable then
                s_ce[ s ][ t.event ] = t.target
            end
        end
    end

    --check the choice problem
    for Q, t in pairs( s_ce ) do
        local ev_hist = {}
        local ok = true
        local problem = {}
        for e, Qa in pairs( t ) do
            ev_hist[e] = true
            for ev_ch, Qb in pairs( t ) do
                if not ev_hist[ev_ch] then
                    local Qc = s_ce[Qa][ev_ch]
                    local Qd = s_ce[Qb][e]
                    if not Qc or not Qd or Qc~=Qd then
                        ok = false
                        problem[e] = true
                        problem[ev_ch] = true
                    end
                end
            end
            if not ok then break end
        end
        if not ok then
            Q.choice_problem = true
            local problem_table = {}
            problem_table.state = Q.name
            problem_table.events = ''

            local flag = false
            for e in pairs(problem) do
                if flag then
                    problem_table.events = problem_table.events .. ', '
                end
                problem_table.events = problem_table.events .. e.name
                flag = true
            end

            problem_list:append(problem_table)
        end
    end

    --show_problem_result('choice', problem_list)

    newautomaton.choice_problem_calc = true

    --if not keep then
    --  newautomaton:create_log()
    --end

    return newautomaton
end

---Verifies if the automaton has the avalanche effect.
--For each state that has a transition that is not a self-loop, verifies if the target state from that transition has another no self-loop transition with that event.
--@param self Automaton in which the operation is applied.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@param uncontrollable_only If true, only the uncontrollable events are considered in the checking.
--@return Automaton with avalanche effect checked.
--@see Automaton:clone
--@see Automaton:create_log
function Automaton:check_avalanche_effect( keep, uncontrollable_only )
    local newautomaton = keep and self or self:clone()
    local problem_list = letk.List.new()

    --create a map(s_ce) Q,e --> Qa
    local s_ce      = {}
    local state_map = {}
    for k_s, s in newautomaton.states:ipairs() do
        s_ce[ s ]      = {}
        state_map[ s ] = k_s
        for k_t, t in s.transitions_out:ipairs() do
            if (not t.event.controllable or not uncontrollable_only) and s~=t.target then
                s_ce[ s ][ t.event ] = t.target
            end
        end
    end

    --check avalanche effect
    for Q, t in pairs( s_ce ) do
        local problem = {}
        for e, Qa in pairs( t ) do
            if s_ce[ Qa ][ e ] then
                Q.avalanche_effect           = Q.avalanche_effect or {}
                Q.avalanche_effect[ e.name ] = state_map[ Qa ]
                problem[e] = true
            end
        end
        if Q.avalanche_effect then
            local problem_table = {}
            problem_table.state = Q.name
            problem_table.events = ''

            local flag = false
            for e in pairs(problem) do
                if flag then
                    problem_table.events = problem_table.events .. ', '
                end
                problem_table.events = problem_table.events .. e.name
                flag = true
            end

            problem_list:append(problem_table)
        end
    end

    --show_problem_result('avalanche effect', problem_list)

    newautomaton.avalanche_effect_calc = true

    --if not keep then
    --  newautomaton:create_log()
    --end

    return newautomaton
end

---Verifies if the automaton has the inexact synchronization problem.
--For each state that has at least one transitions with an uncontrollable event and one transition with a controllable event, verifies if after the occurrence of an event in this state, any other event (of a different type) from the original state can still occur, reaching the same target state.
--@param self Automaton in which the operation is applied.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@return Automaton with inexact synchronization checked.
--@see Automaton:clone
--@see Automaton:create_log
function Automaton:check_inexact_synchronization( keep )
    local newautomaton = keep and self or self:clone()
    local problem_list = letk.List.new() --???

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
        local problem = {} --???
        for ec, Qa in pairs( t ) do
            if ec.controllable then
                for eu, Qb in pairs( t ) do
                    if not eu.controllable then
                        local Qc = s_ce[ Qa ][ eu ]
                        local Qd = s_ce[ Qb ][ ec ]
                        if not Qc or not Qd or Qc ~= Qd then
                            Q.inexact_synchronization = Q.inexact_synchronization or {}
                            Q.inexact_synchronization[#Q.inexact_synchronization+1] = {
                                controllable   = ec,
                                uncontrollable = eu,
                                target_c_u    = Qc,
                                target_u_c    = Qd,
                            }
                            problem[ec] = true
                            problem[eu] = true
                        end
                    end
                end
            end
        end

        --TODO: check this if block
        if Q.inexact_synchronization then
            local problem_table = {}
            problem_table.state = Q.name
            problem_table.events = ''

            local flag = false
            for e in pairs(problem) do
                if flag then
                    problem_table.events = problem_table.events .. ', '
                end
                problem_table.events = problem_table.events .. e.name
                flag = true
            end

            problem_list:append(problem_table)
        end
    end

    --show_problem_result('inexact synchronization', problem_list)

    newautomaton.inexact_synchronization_calc = true

    --if not keep then
    --  newautomaton:create_log()
    --end

    return newautomaton
end

---Verifies if the automaton has the simultaneity problem.
--For each state that has at least two transitions with uncontrollable events, verifies if after the occurrence of an uncontrollable event in this state, any other uncontrollable event can still occur, reaching the same target state.
--@param self Automaton in which the operation is applied.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@return Automaton with simultaneity checked.
--@see Automaton:clone
--@see Automaton:create_log
function Automaton:check_simultaneity( keep )
    local newautomaton = keep and self or self:clone()
    local problem_list = letk.List.new()

    --create a map(s_ce) Q,e --> Qa
    local s_ce      = {}
    for k_s, s in newautomaton.states:ipairs() do
        s_ce[ s ]      = {}
        for k_t, t in s.transitions_out:ipairs() do
            if not t.event.controllable then
                s_ce[ s ][ t.event ] = t.target
            end
        end
    end

    --check simultaneity
    --
    -- Q------u1----->Qa------u2----->Qc
    -- |
    -- |------u2----->Qb------u1----->Qd
    --
    --if (Qc == Qd) then OK else NOT
    for Q, t in pairs( s_ce ) do
        local event_flag = {}
        local problem = {}
        for u1, Qa in pairs( t ) do
            event_flag[u1] = true
            for u2, Qb in pairs( t ) do
                if not event_flag[u2] then
                    local Qc = s_ce[ Qa ][ u2 ]
                    local Qd = s_ce[ Qb ][ u1 ]
                    if not Qc or not Qd or Qc~=Qd then
                        Q.simultaneity = simultaneity or {}
                        Q.simultaneity[#Q.simultaneity+1] = {
                            event1 = u1,
                            event2 = u2,
                            target_u1 = Qc,
                            target_u2 = Qd,
                        }
                        problem[u1] = true
                        problem[u2] = true
                    end
                end
            end
        end
        if Q.simultaneity then
            local problem_table = {}
            problem_table.state = Q.name
            problem_table.events = ''

            local flag = false
            for e in pairs(problem) do
                if flag then
                    problem_table.events = problem_table.events .. ', '
                end
                problem_table.events = problem_table.events .. e.name
                flag = true
            end

            problem_list:append(problem_table)
        end
    end

    show_problem_result('simultaneity', problem_list)

    newautomaton.simultaneity_calc = true

    --~ if not keep then
        --~ newautomaton:create_log()
    --~ end

    return newautomaton
end

local function empty_closure_calc(self, closure, id, smap)
    if not closure[id] then
        closure[id] = {}
        closure[id][id] = true
        for k_transition, transition in self.states:get(id).transitions_out:ipairs() do
            if transition.event.name=='&' then
                empty_closure_calc(self, closure, smap[transition.target], smap)
                for k_state in pairs(closure[smap[transition.target]]) do
                    closure[id][k_state] = true
                end
            end
        end
    end
end

local function empty_closure(self, closure, id, smap)
    local marked = false
    local name
    local first = true

    empty_closure_calc(self, closure, id, smap)

    for k_state in pairs(closure[id]) do
        if first then
            name = self.states:get(k_state).name
            first = false
        else
            name = name .. ',' .. self.states:get(k_state).name
        end
        marked = marked or self.states:get(k_state).marked
    end

    return closure[id], name, marked
end

local function empty_edge(self, closure, id, smap, event)
    local new_id = {}
    local target = {}
    local marked = false
    local name
    local first = true

    for k_state in pairs(id) do
        empty_closure_calc(self, closure, k_state, smap)
        for j_state in pairs(closure[k_state]) do
            new_id[j_state] = true
        end
    end

    for k_state in pairs(new_id) do
        for k_transition, transition in self.states:get(k_state).transitions_out:ipairs() do
            if transition.event==event then
                empty_closure(self, closure, smap[transition.target], smap)
                for j_state in pairs(closure[smap[transition.target]]) do
                    target[j_state] = true
                end
            end
        end
    end

    for k_state in pairs(target) do
        if first then
            name = self.states:get(k_state).name
            first = false
        else
            name = name .. ',' .. self.states:get(k_state).name
        end
        marked = marked or self.states:get(k_state).marked
    end

    return target, name, marked
end

local function state_sum(t)
    local sum = 0

    for k_state in pairs(t) do
        sum = sum + 2^(k_state-1)
    end

    return sum
end

---Makes the automaton deterministic.
--Creates a new automaton. Copies all events from 'self' to the new automanton. Creates the initial state of the new automaton as the closure of the initial state of 'self'. Transforms not deterministic and emptyword transitions into deterministic transitions, creating necessary new states in the process. Removes the emptyword from the new automaton.
--@param self Automaton in which the operation is applied.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@return Deterministic automaton.
--@see Automaton:clone
--@see Automaton:state_add
--@see Automaton:transition_remove
--@see Automaton:transition_add
--@see Automaton:accessible
--@see Automaton:create_log
function Automaton:deterministic(keep)
    if not self.initial then
        --gtk.InfoDialog.showInfo("Automaton doesn't have initial state. Operation can't be applied.")
        return
    end

    local new_automaton
    if keep then
        new_automaton = self
        self = self:clone()
    else
        new_automaton = self:clone()
    end

    --Clear new_automaton
    remove_states_fn(new_automaton, function() return true end)

    local closure = {}
    local comp_state = {}
    local smap = {}
    local i, j, p, name, marked

    --Map states (smap[state] = state_id)
    for k_state, state in self.states:ipairs() do
        smap[state] = k_state
    end

    p = 1
    j = 1
    comp_state[1], name, marked = empty_closure(self, closure, self.initial, smap)
    new_automaton:state_add(name, marked, true)
    while j<=p do
        for k_event, event in self.events:ipairs() do
            if event.name~='&' then
                local target, flag
                flag = false
                target, name, marked = empty_edge(self, closure, comp_state[j], smap, event)

                if state_sum(target) ~= 0 then
                    for k_state, state in ipairs(comp_state) do
                        if state_sum(target)==state_sum(state) then
                            new_automaton:transition_add(j, k_state, k_event, false)
                            flag = true
                            break
                        end
                    end
                    if not flag then
                        p = p + 1
                        comp_state[p] = target
                        new_automaton:state_add(name, marked, false)
                        new_automaton:transition_add(j, p, k_event, false)
                    end
                end
            end
        end

        j = j + 1
    end

    local events_to_remove = {}
    for k_event, event in new_automaton.events:ipairs() do
        if event.name=='&' then
            events_to_remove[ #events_to_remove+1 ] = k_event
        end
    end
    local diff = 0
    for _, event in ipairs(events_to_remove) do
        new_automaton:event_remove(event-diff)
        diff = diff + 1
    end

    --~ if not keep then
        --~ new_automaton:create_log()
    --~ end

    return new_automaton
end

---Calculates the complement of the automaton.
--Uses 'Automaton:deterministic' to make the automaton deterministic. Creates a new state. For every state, inverts its marked property and for each event that is not on that state, creates a transition with this event, having the new state as target. If no new transition have been created, the new state is removed.
--@param self Automaton in which the operation is applied.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@return Complement of the automaton.
--@see Automaton:deterministic
--@see Automaton:state_add
--@see Automaton:transition_add
--@see Automaton:create_log
function Automaton:complement(keep)
    if not self.initial then
        --gtk.InfoDialog.showInfo("Automaton doesn't have initial state. Operation can't be applied.")
        return
    end

    local new_automaton = self:deterministic(keep)
    local Sc, Sc_state = new_automaton:state_add('Sc', false, false )
    local transition

    local flag=false
    for k_state, state in new_automaton.states:ipairs() do
        state.marked = not state.marked
        local existent={}
        for k_t, t in state.transitions_out:ipairs() do
            existent[t.event] = true
        end
        for k_event, event in new_automaton.events:ipairs() do
            if not existent[event] then
                new_automaton:transition_add(state, Sc_state, event, true)
                if state~=Sc_state then
                    flag = true
                end
            end
        end
    end

    if not flag then
        new_automaton:state_remove(Sc)
    end

    --~ if not keep then
        --~ new_automaton:create_log()
    --~ end

    return new_automaton
end

local function mark_distinct_pair(distinct, i, j)
    local t=distinct[i][j]
    distinct[i][j] = true

    if type(t)=='table' then
        for k in pairs(t) do
            for l in pairs(t[k]) do
                if distinct[k][l]~=true then
                    mark_distinct_pair(distinct, k, l)
                end
            end
        end
    end
end

---Minimizes the automaton.
--Uses 'Automaton:deterministic' to make the automaton deterministic. Removes useless states using 'Automaton:trim'. Creates a new state. For every state, for each event that is not on that state, creates a transition with this event, having the new state as target. If no new transition have been created, the new state is removed. Creates the distinction matrix, marking trivially distinct pairs of states. For each pair in the matrix, verifies if it's states can be equivalent and, if not, marks it. If this depends on other pair(s) of states, store this pair for further analysis. Unifies non-marked pairs of states. Applies 'Automaton:trim' again to remove useless states.
--@param self Automaton in which the operation is applied.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@return Minimized automaton.
--@see Automaton:deterministic
--@see Automaton:trim
--@see Automaton:state_add
--@see Automaton:state_remove
--@see Automaton:state_set_initial
--@see Automaton:transition_add
--@see Automaton:transition_remove
--@see Automaton:create_log
function Automaton:minimize(keep)
    if not self.initial then
        --gtk.InfoDialog.showInfo("Automaton doesn't have initial state. Operation can't be applied.")
        return
    end

    local new_automaton = self:deterministic(keep):trim(true, true)
    local Sp, Sp_state = new_automaton:state_add('Sp', false, false )
    local flag=false
    local existent, distinct, smap, smap_inverted, union_map, target1, target2, transitions_to_remove

    --Create state for the incomplete transitions and map states:
    smap = {}
    smap_inverted = {}
    for k_state, state in new_automaton.states:ipairs() do
        smap[#smap+1] = state
        smap_inverted[state] = #smap
        existent = {}
        for k_t, t in state.transitions_out:ipairs() do
            existent[t.event] = true
        end
        for k_event, event in new_automaton.events:ipairs() do
            if not existent[event] then
                new_automaton:transition_add(state, Sp_state, event, true)
                if state~=Sp_state then
                    flag = true
                end
            end
        end
    end
    if not flag then
        new_automaton:state_remove(Sp)
        smap_inverted[smap[#smap]] = nil
        smap[#smap] = nil
    end

    --Create distinction matrix, marking trivially distinct pairs of states:
    distinct = {}
    for i=1,#smap-1 do
        distinct[i] = {}
        for j=i+1,#smap do
            distinct[i][j] = smap[i].marked~=smap[j].marked
        end
    end

    --Check pairs:
    for i=1,#smap-1 do
        for j=i+1,#smap do
            for k_event, event in new_automaton.events:ipairs() do
                for target in pairs(smap[i].event_target[event]) do
                    target1 = smap_inverted[target]
                end
                for target in pairs(smap[j].event_target[event]) do
                    target2 = smap_inverted[target]
                end
                if target1~=target2 then
                    if target1>target2 then
                        target1, target2 = target2, target1
                    end
                    if distinct[target1][target2]==true then --Needs '==true' because may be a table
                        mark_distinct_pair(distinct, i, j)
                        break
                    else
                        distinct[target1][target2] = distinct[target1][target2] or {}
                        distinct[target1][target2][i] = distinct[target1][target2][i] or {}
                        distinct[target1][target2][i][j] = true
                    end
                end
            end
        end
    end

    --Map sets of states:
    union_map = {}
    for i=1,#smap do
        union_map[i] = i
        for j=1,i-1 do
            if distinct[j][i]~=true then
                --i and j are equivalent
                union_map[i] = union_map[j]
                smap[union_map[i]].name = smap[union_map[i]].name .. ',' .. smap[i].name
                if smap[i].initial then
                    new_automaton:state_set_initial(smap[union_map[i]])
                end
                break
            end
        end
    end

    --Change transitions:
    transitions_to_remove = {}
    for i=1,#smap do
        if union_map[i]==i then
            for k_transition, transition in smap[i].transitions_out:ipairs() do
                if union_map[smap_inverted[transition.target]]~=smap_inverted[transition.target] then
                    new_automaton:transition_add(smap[i], smap[union_map[smap_inverted[transition.target]]], transition.event, true)
                    transitions_to_remove[ #transitions_to_remove+1 ] = transition
                end
            end
        end
    end

    --Remove transitions:
    for k_transition,transition in ipairs(transitions_to_remove) do
        new_automaton:transition_remove(transition)
    end

    --~ if not keep then
        --~ new_automaton:create_log()
    --~ end

    return new_automaton:trim(true, true)
end

---Masks the refined events of the automaton.
--For each mask, find its refinements and replaces them by the mask.
--@param self Automaton in which the operation is applied.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@param masks Event masks whose refinements shall be replaced.
--@return Masked automaton.
function Automaton:mask(keep, masks)
    local new_automaton = keep and self or self:clone()
    local ev_map = {}

    for k_event, event in new_automaton.events:ipairs() do
        if event.refinement~='' then --event is a refinement
            ev_map[event.refinement] = ev_map[event.refinement] or {}
            ev_map[event.refinement][ #ev_map[event.refinement]+1 ] = event
        else
            ev_map[event.name] = ev_map[event.name] or {}
            ev_map[event.name].event = event
        end
    end

    --masks = {ev1, ev2, ev3} (references to workspace)

    for k_mask, mask in ipairs(masks) do
        if ev_map[mask.name] then
            --add mask to automaton (if doesn't exist yet)
            local event = ev_map[mask.name].event
            if not event then
                _, event = new_automaton:event_add(mask.name, mask.level[self.level].observable, mask.level[self.level].controllable, mask.refinement, mask)
            end

            for k_ref, ref in ipairs(ev_map[mask.name]) do
                --copy refined transitions to masked transitions
                for k_transition, transition in ref.transitions:ipairs() do
                    new_automaton:transition_add(transition.source, transition.target, event, true)
                end

                --delete mask refinements (will delete transitions automatically)
                new_automaton:event_remove(ref)
            end
        end
    end

    --~ if not keep then
        --~ new_automaton:create_log()
    --~ end

    return new_automaton
end

---Distinguishes the events of the automaton.
--For each refinement, find its mask and replaces it by the refinements.
--@param self Automaton in which the operation is applied.
--@param keep If true, the operation is directly applied on 'self', otherwise, in a copy of it.
--@param masks Event refinements whose masks shall be replaced.
--@return Distinguished automaton.
function Automaton:distinguish(keep, refinements)
    local new_automaton = keep and self or self:clone()
    local ev_map = {}

    for k_event, event in new_automaton.events:ipairs() do
        if event.refinement~='' then --event is a refinement
            ev_map[event.name] = event
        else
            ev_map[event.name] = {
                event = event,
            }
        end
    end

    for k_ref, ref in ipairs(refinements) do
        if ev_map[ref.refinement] then
            ev_map[ref.refinement][ #ev_map[ref.refinement]+1 ] = ref
        end
    end

    --refinements = {ev1, ev2, ev3} (references to workspace)

    for k_mask, mask in pairs(ev_map) do
        if type(mask)=='table' and #mask>0 then
            for k_ref, ref in ipairs(mask) do
                --add refinement to automaton (if doesn't exist yet)
                local event = ev_map[ref.name]
                if not event then
                    _, event = new_automaton:event_add(ref.name, ref.level[self.level].observable, ref.level[self.level].controllable, ref.refinement, ref)
                end
                for k_transition, transition in mask.event.transitions:ipairs() do
                    new_automaton:transition_add(transition.source, transition.target, event, true)
                end
            end
            new_automaton:event_remove(mask.event)
        end
    end

    --~ if not keep then
        --~ new_automatonnew_automaton:create_log()
    --~ end

    return new_automaton
end

---Creates the automaton log.
--TODO
function Automaton:create_log()
    self.log = {
        pos = 0,
        list = letk.List.new(),
        last = {
            state = {},
            event = {},
            transition = {},
            property = {
                radius_factor = self.radius_factor,
                type = self.type,
                initial = self.initial,
            },
            address = {
                state = {},
                event = {},
                transition = {},
            },
        },
    }

    --TODO: store calc properties and other state properties (see Automaton:clone)

    local table = self.log.last.state
    for k_state, state in self.states:ipairs() do
        table[k_state] = {
            name = state.name,
            marked = state.marked,
            x = state.x,
            y = state.y,
        }
        self.log.last.address.state[k_state] = state
    end

    table = self.log.last.event
    for k_event, event in self.events:ipairs() do
        table[k_event] = {
            name = event.name,
            observable = event.observable,
            controllable = event.controllable,
            refinement = event.refinement,
        }
        self.log.last.address.event[k_event] = event
    end

    table = self.log.last.transition
    for k_transition, transition in self.transitions:ipairs() do
        local _, source = self.states:find(transition.source)
        local _, event = self.events:find(transition.event)
        local _, target = self.states:find(transition.target)
        local factor = transition.factor
        table[k_transition] = {
            source = source,
            event = event,
            target = target,
            factor = factor,
        }
        self.log.last.address.transition[k_transition] = transition
    end
end

local function write_log_operation(last, operations, name, range, target, new_value, address)
    local data = {
        name = name, --operation name
        range = range, --states, events, etc
        target = target, --state/event/etc id
        old_value = last[range][target], --undo value
        new_value = new_value, --redo value
    }
    operations:append(data)

    if name~='remove' then
        last[range][target] = new_value
        if range~='property' then
            last.address[range][target] = address
        end
    else
        table.remove(last[range], target)
        table.remove(last.address[range], target)
    end

    --print_r(data)
end

---Writes a page in the log.
--TODO
function Automaton:write_log(callback)
    --print('Writing log')

    local backup_list = letk.List.new()
    self.log.pos = self.log.pos + 1
    while self.log.pos <= self.log.list:len() do
        backup_list:append(self.log.list:remove(self.log.pos))
    end

    local operations = letk.List.new()
    self.log.list:append {
        operations = operations,
        callback = callback,
    }

    --detect changes
    local last = self.log.last

    --properties
    if self.radius_factor~=last.property.radius_factor then
        write_log_operation(last, operations, 'edit', 'property', 'radius_factor', self.radius_factor)
    end
    if self.type~=last.property.type then
        write_log_operation(last, operations, 'edit', 'property', 'type', self.type)
    end
    if self.initial~=last.property.initial then
        write_log_operation(last, operations, 'edit', 'property', 'initial', self.initial)
    end

    --transitions
    for k_transition, transition in self.transitions:ipairs() do
        local _, source = self.states:find(transition.source)
        local _, event = self.events:find(transition.event)
        local _, target = self.states:find(transition.target)
        local factor = transition.factor
        while last.transition[k_transition] and last.address.transition[k_transition]~=transition do
            --print('transition ' .. k_transition .. ' was deleted.')
            --transition was deleted
            write_log_operation(last, operations, 'remove', 'transition', k_transition)
        end
        if not last.transition[k_transition] then
            --print('transition ' .. k_transition .. ' was created.')
            --transition was created
            write_log_operation(last, operations, 'add', 'transition', k_transition, {
                source = source,
                event = event,
                target = target,
                factor = factor,
            }, transition)
        elseif last.transition[k_transition].source~=source or last.transition[k_transition].event~=event or last.transition[k_transition].target~=target or last.transition[k_transition].factor~=factor then
            --print('transition ' .. k_transition .. ' was modified.')
            --transition was modified
            write_log_operation(last, operations, 'edit', 'transition', k_transition, {
                source = source,
                event = event,
                target = target,
                factor = factor,
            }, transition)
        end
    end
    for k_transition=self.transitions:len()+1,#last.transition do
        --print('transition ' .. k_transition .. ' was deleted.')
        --transition was deleted
        write_log_operation(last, operations, 'remove', 'transition', k_transition)
    end

    --states
    for k_state, state in self.states:ipairs() do
        while last.state[k_state] and last.address.state[k_state]~=state do
            --print('state ' .. k_state .. ' was deleted.')
            --state was deleted
            write_log_operation(last, operations, 'remove', 'state', k_state)
        end
        if not last.state[k_state] then
            --print('state ' .. k_state .. ' was created.')
            --state was created
            write_log_operation(last, operations, 'add', 'state', k_state, {
                name = state.name,
                marked = state.marked,
                x = state.x,
                y = state.y,
            }, state)
        elseif last.state[k_state].name~=state.name or last.state[k_state].marked~=state.marked or last.state[k_state].x~=state.x or last.state[k_state].y~=state.y then
            --print('state ' .. k_state .. ' was modified.')
            --state was modified
            write_log_operation(last, operations, 'edit', 'state', k_state, {
                name = state.name,
                marked = state.marked,
                x = state.x,
                y = state.y,
            }, state)
        end
    end
    for k_state=self.states:len()+1,#last.state do
        --print('state ' .. k_state .. ' was deleted.')
        --state was deleted
        write_log_operation(last, operations, 'remove', 'state', k_state)
    end

    --events
    for k_event, event in self.events:ipairs() do
        while last.event[k_event] and last.address.event[k_event]~=event do
            --print('event ' .. k_event .. ' was deleted.')
            --event was deleted
            write_log_operation(last, operations, 'remove', 'event', k_event)
        end
        if not last.event[k_event] then
            --print('event ' .. k_event .. ' was created.')
            --event was created
            write_log_operation(last, operations, 'add', 'event', k_event, {
                name = event.name,
                observable = event.observable,
                controllable = event.controllable,
                refinement = event.refinement,
            }, event)
        elseif last.event[k_event].name~=event.name or last.event[k_event].observable~=event.observable or last.event[k_event].controllable~=event.controllable or last.event[k_event].refinement~=event.refinement then
            --[[ Handled in workspace
            print('event ' .. k_event .. ' was modified.')
            --event was modified
            write_log_operation(last, operations, 'edit', 'event', k_event, {
                name = event.name,
                observable = event.observable,
                controllable = event.controllable,
                refinement = event.refinement,
            }, event)
            ]]--
            last.event[k_event].name = event.name
            last.event[k_event].observable = event.observable
            last.event[k_event].controllable = event.controllable
            last.event[k_event].refinement = event.refinement
        end
    end
    for k_event=self.events:len()+1,#last.event do
        --print('event ' .. k_event .. ' was deleted.')
        --event was deleted
        write_log_operation(last, operations, 'remove', 'event', k_event)
    end

    if operations:len()==0 then
        --no operations made, cancel write_log
        self.log.list:remove(self.log.pos)
        while backup_list:len()>0 do
            self.log.list:append(backup_list:remove(1))
        end
        self.log.pos = self.log.pos - 1
        --print('Log cancelled')
    else
        --print('Log written')
    end
    --print(string.rep('\n',5))
end

local function undo_operation(automaton, operation)
    local address
    if operation.range=='property' then
        if operation.name=='edit' then
            if operation.target=='type' then
                automaton.type = operation.old_value
            end
            if operation.target=='radius_factor' then
                automaton.radius_factor = operation.old_value
            end
            if operation.target=='initial' then
                if operation.old_value then
                    automaton:state_set_initial(operation.old_value)
                else
                    automaton:state_unset_initial()
                end
            end
        end
    end
    if operation.range=='state' then
        if operation.name=='edit' then
            if operation.old_value.marked then
                automaton:state_set_marked(operation.target)
            else
                automaton:state_unset_marked(operation.target)
            end
            automaton:state_set_position(operation.target, operation.old_value.x, operation.old_value.y)
            automaton:state_set_name(operation.target, operation.old_value.name)
            address = automaton.log.last.address.state[operation.target]
        end
        if operation.name=='add' then
            automaton:state_remove(operation.target)
        end
        if operation.name=='remove' then
            _, address = automaton:state_add(operation.old_value.name, operation.old_value.marked, false, operation.target)
            automaton:state_set_position(operation.target, operation.old_value.x, operation.old_value.y)
        end
    end
    if operation.range=='event' then
        --[[ Handled in workspace
        if operation.name=='edit' then
            if operation.old_value.observable then
                automaton:event_set_observable(operation.target)
            else
                automaton:event_unset_observable(operation.target)
            end
            if operation.old_value.controllable then
                automaton:event_set_controllable(operation.target)
            else
                automaton:event_unset_controllable(operation.target)
            end
            automaton:event_set_refinement(operation.target, operation.old_value.refinement)
            automaton:event_set_name(operation.target, operation.old_value.name)
            address = automaton.log.last.address.event[operation.target]
        end
        ]]--
        if operation.name=='add' then
            automaton:event_remove(operation.target)
        end
        if operation.name=='remove' then
            local ew, ew_id = automaton.controller.events:find(function(event)
                return event.name==operation.old_value.name
            end)
            if not ew then
                local ref = automaton.controller.events:find(function(event)
                    return event.name==operation.old_value.refinement
                end)
                ew = automaton.controller:add_event(operation.old_value.name, operation.old_value.controllable, operation.old_value.observable, ref and ref.name)
            end
            _, address = automaton:event_add(ew.name, ew.observable, ew.controllable, ew.refinement, ew, operation.target)
            ew.automata[automaton] = address
        end
    end
    if operation.range=='transition' then
        if operation.name=='edit' then
            automaton:transition_set_factor(operation.target, operation.old_value.factor)
            address = automaton.log.last.address.transition[operation.target]
        end
        if operation.name=='add' then
            automaton:transition_remove(operation.target)
        end
        if operation.name=='remove' then
            _, address = automaton:transition_add(operation.old_value.source, operation.old_value.target, operation.old_value.event, false, operation.target)
        end
    end

    --update log.last
    if operation.name~='remove' then
        automaton.log.last[operation.range][operation.target] = operation.old_value
        if operation.range~='property' then
            automaton.log.last.address[operation.range][operation.target] = address
        end
    else
        table.insert(automaton.log.last[operation.range], operation.target, operation.old_value)
        table.insert(automaton.log.last.address[operation.range], operation.target, address)
    end
end

local function redo_operation(automaton, operation)
    local address
    if operation.range=='property' then
        if operation.name=='edit' then
            if operation.target=='type' then
                automaton.type = operation.new_value
            end
            if operation.target=='radius_factor' then
                automaton.radius_factor = operation.new_value
            end
            if operation.target=='initial' then
                if operation.new_value then
                    automaton:state_set_initial(operation.new_value)
                else
                    automaton:state_unset_initial()
                end
            end
        end
    end
    if operation.range=='state' then
        if operation.name=='edit' then
            if operation.new_value.marked then
                automaton:state_set_marked(operation.target)
            else
                automaton:state_unset_marked(operation.target)
            end
            automaton:state_set_position(operation.target, operation.new_value.x, operation.new_value.y)
            automaton:state_set_name(operation.target, operation.new_value.name)
            address = automaton.log.last.address.state[operation.target]
        end
        if operation.name=='add' then
            _, address = automaton:state_add(operation.new_value.name, operation.new_value.marked, false, operation.target)
            automaton:state_set_position(operation.target, operation.new_value.x, operation.new_value.y)
        end
        if operation.name=='remove' then
            automaton:state_remove(operation.target)
        end
    end
    if operation.range=='event' then
        --[[ Handled in workspace
        if operation.name=='edit' then
            if operation.old_value.observable then
                automaton:event_set_observable(operation.target)
            else
                automaton:event_unset_observable(operation.target)
            end
            if operation.old_value.controllable then
                automaton:event_set_controllable(operation.target)
            else
                automaton:event_unset_controllable(operation.target)
            end
            automaton:event_set_refinement(operation.target, operation.old_value.refinement)
            automaton:event_set_name(operation.target, operation.old_value.name)
            address = automaton.log.last.address.event[operation.target]
        end
        ]]--
        if operation.name=='add' then
            local ew, ew_id = automaton.controller.events:find(function(event)
                return event.name==operation.new_value.name
            end)
            if not ew then
                local ref = automaton.controller.events:find(function(event)
                    return event.name==operation.new_value.refinement
                end)
                ew = automaton.controller:add_event(operation.new_value.name, operation.new_value.controllable, operation.new_value.observable, ref and ref.name)
            end
            _, address = automaton:event_add(ew.name, ew.observable, ew.controllable, ew.refinement, ew, operation.target)
            ew.automata[automaton] = address
        end
        if operation.name=='remove' then
            automaton:event_remove(operation.target)
        end
    end
    if operation.range=='transition' then
        if operation.name=='edit' then
            automaton:transition_set_factor(operation.target, operation.new_value.factor)
            address = automaton.log.last.address.transition[operation.target]
        end
        if operation.name=='add' then
            _, address = automaton:transition_add(operation.new_value.source, operation.new_value.target, operation.new_value.event, false, operation.target)
        end
        if operation.name=='remove' then
            automaton:transition_remove(operation.target)
        end
    end

    if operation.name~='remove' then
        automaton.log.last[operation.range][operation.target] = operation.new_value
        if operation.range~='property' then
            automaton.log.last.address[operation.range][operation.target] = address
        end
    else
        table.remove(automaton.log.last[operation.range], operation.target)
        table.remove(automaton.log.last.address[operation.range], operation.target)
    end
end

---Undoes last modification to the automaton.
--TODO
function Automaton:undo()
    --~ if self.log.pos > 0 then
        --~ self.undoing = true
        --~ --print('\nUndoing')
        --~ local t = self.log.list:get(self.log.pos)
--~ 
        --~ --Undo operations (inverted order)
        --~ for k_operation = t.operations:len(),1,-1 do
            --~ local operation = t.operations:get(k_operation)
            --~ --print_r(operation)
            --~ undo_operation(self, operation)
        --~ end
--~ 
        --~ if t.callback then
            --~ t.callback()
        --~ end
--~ 
        --~ self.log.pos = self.log.pos - 1
--~ 
        --~ local old_t = self.log.list:get(self.log.pos)
        --~ if old_t.callback then
            --~ old_t.callback()
        --~ end
        --~ --print('Undone')
        --~ --print(string.rep('\n',5))
        --~ self.undoing = nil
    --~ end
end

---Redoes last modification to the automaton.
--TODO
function Automaton:redo()
    --~ if self.log.pos < self.log.list:len() then
        --~ self.redoing = true
        --~ --print('\nRedoing')
        --~ self.log.pos = self.log.pos + 1
        --~ local t = self.log.list:get(self.log.pos)
--~ 
        --~ --Redo operations (normal order)
        --~ for k_operation, operation in t.operations:ipairs() do
            --~ --print_r(operation)
            --~ redo_operation(self, operation)
        --~ end
--~ 
        --~ if t.callback then
            --~ t.callback()
        --~ end
        --~ --print('\nRedone')
        --~ --print(string.rep('\n',5))
        --~ self.redoing = nil
    --~ end
end

---Sets the radius factor property of the automaton.
--Changes the radius factor to 'f'.
--@param f New radius factor.
function Automaton:set_radius_factor(f)
    self.radius_factor = f
end

---Checks problems in the automaton, printing relevant information.
--TODO
--@param self Automaton to be checked.
function Automaton:check()
    print'Check start...'
    local sinit       = self.states:get( self.initial )
    local states      = {}
    local events      = {}
    local transitions = {}
    if sinit then
        print'[ OK ] Init find'
    else
        print'[ ERROR ] Init NOT find'
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
            print( string.format('[ ERROR ] Event %s not found in transition %i',
                tostring( t.event ), k_t
            ), states[t.source], events[ t.event ], states[t.target])
        end
        if not states[ t.target ] then
            print( string.format('[ ERROR ] State %s (T) not found in transition %i',
                tostring( t.target ), k_t
            ), states[t.source], events[ t.event ], states[t.target])
        end
        if not states[ t.source ] then
            print( string.format('[ ERROR ] State %s (S) not found in transition %i',
                tostring( t.source ), k_t
            ), states[t.source], events[ t.event ], states[t.target])
        end
    end

    print'check state transitions...'
    for k_s, s in self.states:ipairs() do
        for k_t, t in s.transitions_out:ipairs() do
            if not transitions[ t ] then
                print( string.format('[ERROR] Transition OUT %s not found in state %i',
                    tostring( t ), k_s
                ))
            end
            if t.source ~= s then
                print( string.format('[ERROR] Invalid self in Transition OUT %s in state %i',
                    tostring( t ), k_s
                ), t.source, s)
            end
            if not states[ t.target ] then
                print( string.format('[ERROR] Invalid target in Transition OUT %s in state %i',
                    tostring( t ), k_s
                ))
            end
            if not events[ t.event ] then
                print( string.format('[ERROR] Invalid event in Transition OUT %s in state %i',
                    tostring( t ), k_s
                ))
            end
        end
        for k_t, t in s.transitions_in:ipairs() do
            if not transitions[ t ] then
                print( string.format('[ERROR] Transition IN %s not found in state %i',
                    tostring( t ), k_s
                ))
            end
            if t.target ~= s then
                print( string.format('[ERROR] Invalid self in Transition IN %s in state %i',
                    tostring( t ), k_s
                ),t.target,s)
            end
            if not states[ t.source ] then
                print( string.format('[ERROR] Invalid target in Transition IN %s in state %i',
                    tostring( t ), k_s
                ))
            end
            if not events[ t.event ] then
                print( string.format('[ERROR] Invalid event in Transition IN %s in state %i',
                    tostring( t ), k_s
                ))
            end
        end
    end
    print'Check finish.'
end

---Check if two automata are isomorphic, to check if they are similar you first need to minimize it.
---Only works for DFA (convert to DFA if it is NFA first)
function Automaton:check_isomorphic( A2 )
    local A1 = self

    if not A1.initial or not A2.initial then return false, 'Initial state is required to compare' end 

    --Initial (Maybe redundant) check
    if A1.events.itens ~= A2.events.itens then return false, 'number of events are different ' .. A1.events.itens .. '/' .. A2.events.itens  end
    if A1.states.itens ~= A2.states.itens then return false, 'number of states are different '  .. A1.states.itens .. '/' .. A2.states.itens end
    if A1.transitions.itens ~= A2.transitions.itens then return false, 'number of transitions are different ' .. A1.transitions.itens .. '/' .. A2.transitions.itens end

    --Check eventNames TODO: transform to an EventSet and use EventSet comparison function
    local event_map={}
    for _, e1 in A1.events:ipairs() do
        event_map[ e1.name ] = { e1 }
    end
    for _, e2 in A2.events:ipairs() do
        event_map[ e2.name ] = event_map[ e2.name ] or {}
        event_map[ e2.name ][2] = e2
    end
    for eventName, e in pairs( event_map ) do
        if not e[1] or not e[2] then return false, 'events does not match ' .. eventName .. (e[1] and 'T' or 'F') .. '/' .. (e[2] and 'T' or 'F') end
        if e[1].controllable ~= e[2].controllable then return false, 'events controllability does not match ' .. eventName end
        if e[1].observable ~= e[2].observable then return false, 'events observable does not match ' .. eventName end
        if e[1].refinement ~= e[2].refinement then return false, 'events refinement does not match ' .. eventName end
    end

    local is1                = A1.states:find( A1.initial ) 
    local is2                = A2.states:find( A2.initial )
    if is1.marked ~= is2.marked then return false, 'State does not have same marked pattern' end
    local stack              = { is1 }
    local sPos               = 1
    local state_relation_map = { [is1] = is2 }
    while sPos <= #stack do
        local s1 = stack[ sPos ]
        local s2 = state_relation_map[ s1 ]
        for k_trans1, trans1 in s1.transitions_out:ipairs() do
            local eventName = trans1.event.name
            local t1        = trans1.target
            local t2
            if s2.transitions_out.itens ~= s1.transitions_out.itens then return false, 'State does no has same transition amount' end
            for k_trans2, trans2 in s2.transitions_out:ipairs() do
                if trans2.event.name == eventName then
                    t2 = trans2.target
                    break
                end
            end
            if not t2 then return false, 'State does no has same transitions' end
            if state_relation_map[ t1 ] then
                if state_relation_map[ t1 ] ~= t2 then return false, 'State does not have same transitions map' end
            else
                state_relation_map[ t1 ] = t2
                stack[ #stack + 1 ]      = t1
                if t1.marked ~= t2.marked then return false, 'State does not have same marked pattern' end
            end
            
        end

        sPos = sPos + 1
    end

    return true
end
