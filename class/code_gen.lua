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
local CodeGen = {}
local CodeGen_MT = { __index = CodeGen}

local code_blocks = require( 'class.code_blocks' )

function CodeGen.new( automaton )
    local self = {
        automaton = automaton,
    }
    setmetatable( self, CodeGen_MT )

    return self
end


function CodeGen:pic_c( file_name )
    local code_h = {
        [[#include <stdio.h>]],
        code_blocks.pic_c_header(),
    }

    local code_c = {
        string.format( [[#include "%s.h"]], select(3, file_name:find( '^.-([^/\\]*)$' ) ) ),
    }

    --define events
    for ch_ev, ev in ipairs( self.automaton.events ) do
        code_h[#code_h + 1] = string.format([[#define EV_%s %i]], ev.name, ch_ev - 1 )
    end

    --state
    local len = 0
    local st_ev = {}
    for ch_st, st in ipairs( self.automaton.states ) do
        len = len + 1
        local evs = {}
        for ch_ev, target in pairs( st.event_target ) do
            local c2 = math.mod( (target - 1), 255 )
            local c1 = (target - 1 - c2)/ 255
            evs[#evs +1] = string.format([[EV_%s, %i, %i]], self.automaton.events[ch_ev].name , c1, c2 )
            len = len + 3
        end
        st_ev[#st_ev +1] = #evs
        for c, v in ipairs(evs) do
            st_ev[#st_ev +1] = v
        end
    end
    code_c[#code_c +1] = string.format([[const unsigned char states[%i] = { ]], len) .. table.concat(st_ev, ',') .. [[};]]

    --callback and events info
    local events_info_list = {}
    for ch_ev, ev in ipairs( self.automaton.events ) do
         events_info_list[#events_info_list +1] = string.format([[    { %i }]], ev.controllable and 1 or 0 )
    end
    code_c[#code_c +1] = string.format([[
TEventInfo events[%i] = {
%s
};
    ]], #self.automaton.events,  table.concat( events_info_list, ',\n' ))

    --callback function
    local ev_list_switch = {}
    for ch_ev, ev in ipairs( self.automaton.events ) do
        ev_list_switch[#ev_list_switch + 1] = string.format('       case EV_%s:\n        \n        break;', ev.name)
    end
    code_c[#code_c +1] = code_blocks.pic_c_callback_function( table.concat(ev_list_switch,'\n'), table.concat(ev_list_switch,'\n') )

    --main loop( automata player )
    code_c[#code_c +1] = code_blocks.pic_c_main_loop( self.automaton )

    --return
    local file = io.open( file_name .. '.h', "w")
    file:write( table.concat(code_h,'\n') )
    file:close()
    file = io.open( file_name .. '.c', "w")
    file:write( table.concat(code_c,'\n') )
    file:close()
end

return CodeGen
