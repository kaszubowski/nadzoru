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
local Blocks = {}

------------------------------------------------------------------------
--                             PIC C                                  --
------------------------------------------------------------------------

Blocks.pic_c_header = function()
    return [[

typedef struct SEventInfo {
    unsigned char controllable;
} TEventInfo;
]]
end

Blocks.pic_c_callback_function = function( list )

return string.format([[
unsigned char input_read( unsigned char ev ){
    unsigned char ret = 0;
    switch( ev ){
%s
    }
    return ret;
}

void callback( unsigned char ev, unsigned long int s, unsigned long int t){

}
]], list, list)

end

Blocks.pic_c_main_loop  = function( automaton )

return string.format([[

unsigned char seed = 0;
unsigned char pic_rand(){
    seed = seed * ( -35 ) + 53;
    return seed;
}

void state_machine_loop(){
    unsigned long int current_state = %i, next_state;
    unsigned char     i, loop, quit, controllable_events, ex_event, next_event;
    unsigned long int pnt, state_remain;
    unsigned char     aux_num_ev, aux_ev ;

    while(1){
        //put the pnt in the current_state
        pnt = 0;
        state_remain = current_state;
        while(state_remain){
            state_remain--;
             aux_num_ev = states[pnt];
            pnt += 1 + (aux_num_ev * 3);
        }

        aux_num_ev = states[pnt];
        loop                = 0;
        quit                = 0;
        controllable_events = 0;
        next_state          = 0;
        next_event          = 0;
        ex_event            = 0;
        while(1){
            if( loop == 1 && controllable_events){
                ex_event = (pic_rand() %% controllable_events) + 1;
            }

            for( i=1; i<(aux_num_ev*3); i+=3 ){
                aux_ev = states[pnt+i];
                if( loop == 0 || loop == 2 ){
                    if( !events[ aux_ev ].controllable ){
                        quit = input_read( aux_ev );
                        if( quit ){
                            next_state = ((unsigned long int) states[ pnt+i+1 ] ) * 255 + ((unsigned long int) states[ pnt+i+2 ]);
                            next_event = aux_ev;
                            break;
                        }
                    }
                    if( loop == 0  && events[ aux_ev ].controllable ){
                        controllable_events++;
                    }
                } else if( loop == 1 && controllable_events && events[ aux_ev ].controllable ) {
                    ex_event--;
                    if(! ex_event){
                        next_state = states[ pnt+i+1 ]*255 + states[ pnt+i+2 ];
                        next_event = aux_ev;
                        quit = 1;
                        break;
                    }
                }
            }//end 'for'
            if( loop < 2 ) loop++;
            if(quit) break;
        }

        //execute
        callback(
            next_event,
            current_state,
            next_state
        );
        current_state = next_state;

    }//MAIN LOOP

}

void main(){
    //CODE here

    //state machine main loop
    state_machine_loop();
}

]], automaton.initial - 1)

end

return Blocks
