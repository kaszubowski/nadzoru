Template    = {}
Template_MT = { __index = Template }

local sf = string.format

local sff = function( s, t )
    return string.gsub( s, '%${([^{^}]*)}', t )
end

function Template.get( id, context )
    local t = type( Template[id] )
    local value = ''
    if t == 'string' then
        value = Template[ id ]
    elseif t == 'function' then
        value = Template[ id ]( context )
    else
        print("ERRO: code gen Invalid template:", id)
    end

    value = value:gsub( '%${([^{^}]*)}', function( tag )
        return Template.get( tag, context )
    end)

    return value
end

------------------------------------------------------------------------
--                            RANDOM                                  --
------------------------------------------------------------------------


Template.random_ad_body = [[
    setup_ADC_ports(AN0);
    setup_adc(ADC_CLOCK_INTERNAL);
    set_adc_channel(0);
    delay_ms(10);
    return read_adc();
]]

Template.random_pseudo_body = [[
    seed = seed * ( -35 ) + 53;
    return seed;
]]

Template.random_pseudofix = [[
unsigned char seed = 0;
unsigned char pic_rand(){
${random_pseudo_body}
}
]]

Template.random_pseudoad = [[
unsigned char get_ad_seed(){
${random_ad_body}
}

unsigned char seed = 0;
unsigned char pic_rand(){
${random_pseudo_body}
}
]]

Template.random_ad = [[
unsigned char pic_rand(){
${random_ad_body}
}
]]

------------------------------------------------------------------------
--                               INPUT                                --
------------------------------------------------------------------------
Template.input_read = function( context )

local events_s = {}
for k_event, event in ipairs(context.events) do
    if not event.controllable then
        events_s[#events_s + 1] = string.format([[
            case EV_%s:
            break;
        ]], event.name )
    end
end

local input_fn =
        context.input_fn == CodeGen.INPUT_TIMER              and 'input_timer'       or
        --context.input_fn == CodeGen.INPUT_EXTERNAL           and 'input_external'    or
        context.input_fn == CodeGen.INPUT_MULTIPLEXED        and 'input_multiplexed'


return sff([[
unsigned char input_buffer[256];
unsigned char input_buffer_pnt_add = 0;
unsigned char input_buffer_pnt_get = 0;

unsigned char input_buffer_get( unsigned char *event ){
    if(input_buffer_pnt_add == input_buffer_pnt_get){
        return 0;
    } else {
        *event = input_buffer[ input_buffer_pnt_get ];
        input_buffer_pnt_get++;
        return 1;
    }
}

void input_buffer_add( unsigned char event ){
    input_buffer[ input_buffer_pnt_add ] = event;
    input_buffer_pnt_add++;
}

unsigned char input_read( unsigned char ev ){
    char ret = 0;
    switch( ev ){
${events_s}
    }
    return ret;
}

${input_interruption}
]], {
    events_s           = table.concat( events_s, '\n' ),
    input_interruption = '${' .. input_fn .. '}',
})
end

Template.input_timer = function( context )
    local events_unset = {}
    for k_event, event in ipairs(context.events) do
        events_unset[#events_unset +1] = 0
    end

    return sff([[
unsigned char last_events[${ev_number}] = {${events_unset}};

#INT_TIMER1
void  TIMER1_isr(void)
{
    unsigned char i;

    disable_interrupts(INT_TIMER1);
    set_timer1(${timer_interval}+get_timer1());
    for(i=0;i<ev_number;i++){
        if( !ev_controllable[i]){
            if(  input_read( i ) ){
                if( !last_events[i] ){
                    input_buffer_add( i );
                    last_events[i] = 1;
                }
            } else {
                last_events[i] = 0;
            }
        }
    }
    enable_interrupts(INT_TIMER1);
}
    ]],{
        timer_interval = context.timer_interval,
        events_unset     = table.concat(events_unset, ',' ),
        ev_number      = #context.events,
    })
end

Template.input_multiplexed = function( context )
    local events_unset = {}
    for k_event, event in ipairs(context.events) do
        events_unset[#events_unset +1] = 0
    end

return sff([[
unsigned char last_events[${ev_number}] = {${events_unset}};

#INT_EXT
void  int_externo(void)
{
   unsigned char i;
   disable_interrupts(INT_EXT);
   delay_ms(1000);
   for(i=0;i<ev_number;i++){
        if( !ev_controllable[i]){
            if(  input_read( i ) ){
                if( !last_events[i] ){
                    input_buffer_add( i );
                    last_events[i] = 1;
                }
            } else {
                last_events[i] = 0;
            }
        }
    }
    enable_interrupts(INT_EXT);
}
    ]],{
        timer_interval = context.timer_interval,
        events_unset     = table.concat(events_unset, ',' ),
        ev_number      = #context.events,
    })
end

------------------------------------------------------------------------
--                              CALLBACK                              --
------------------------------------------------------------------------

Template.callback = function( context )
    local events_s = {}
    for k_event, event in ipairs(context.events) do
        events_s[#events_s + 1] = string.format([[
            case EV_%s:
            break;
        ]], event.name )
    end

    return sff([[
void callback( unsigned char ev ){
    switch( ev ){
${events_s}
    }
}
    ]],{
        events_s           = table.concat( events_s, '\n' ),
    })
end

------------------------------------------------------------------------
--                              STRUCTS                               --
------------------------------------------------------------------------
Template.automatons_data = function( context )
    local ev_controllable = {}
    local events         = {}
    local sup_events     = {}
    local initial_states = {}
    local sup_data_pos   = {}
    local sup_data       = {}
    local data_len       = 0
    local events_set     = {}

    for k_event, event in ipairs(context.events) do
        events_set[#events_set +1] = 1
        events[#events + 1] = string.format([[#define EV_%s %i]], event.name, k_event - 1 )
        ev_controllable[#ev_controllable +1] = event.controllable and 1 or 0
    end

    for k_automaton, automaton in context.automatons:ipairs() do
        local sup_events_row = {}
        for i = 1, #context.events do
            sup_events_row[#sup_events_row + 1] = context.sup_events[k_automaton][i] and 1 or 0
        end
        sup_events[#sup_events + 1] = '{' .. table.concat( sup_events_row, ',' ) .. '}'

        initial_states[#initial_states +1] = automaton.initial - 1
        sup_data_pos[#sup_data_pos +1]     = data_len
        local map_states = {}
        for k_state, state in automaton.states:ipairs() do
            map_states[state] = k_state - 1
        end

        for k_state, state in automaton.states:ipairs() do
            sup_data[#sup_data +1] = state.transitions_out:len()
            data_len = data_len + 1

            for k_transition, transition in state.transitions_out:ipairs() do
                data_len = data_len + 3

                sup_data[#sup_data +1] = 'EV_' .. transition.event.name

                local target_index = map_states[ transition.target ]
                local c2 = math.mod( target_index, 255 )
                local c1 = (target_index - c2)/ 255
                sup_data[#sup_data +1] = c1
                sup_data[#sup_data +1] = c2
            end
        end
    end

    return sff([[
${events}

const unsigned char ev_number                               = ${ev_number};
const unsigned char ev_controllable[${ev_number}]           = {${ev_controllable}};
const unsigned char sup_events[${sup_number}][${ev_number}] = {
    ${sup_events}
};
const unsigned char sup_number                              = ${sup_number};
unsigned long int sup_current_state[${sup_number}]     = {${initial_states}};
const unsigned long int sup_data_pos[${sup_number}]    = {${sup_data_pos}};
const unsigned char sup_data[${data_len}]                   = {
${sup_data}
};

unsigned long int get_state_position( unsigned char supervisor, unsigned long int state ){
    unsigned long int position = sup_data_pos[ supervisor ];
    unsigned long int s;
    unsigned char en;
    for(s=0; s<state; s++){
        en       = sup_data[position];
        position += en * 3 + 1;
    }

    return position;
}

void make_transition( unsigned char event ){
    unsigned char i;
    unsigned long int position;
    unsigned char num_transitions;

    for(i=0; i<sup_number; i++){
        if(sup_events[i][event]){
            position        = get_state_position(i, sup_current_state[i]);
            num_transitions = sup_data[position];
            position++;
            while(num_transitions--){
                if(sup_data[position] == event){
                    sup_current_state[i] = ((unsigned long int) sup_data[position + 1] ) * 255 + ((unsigned long int) sup_data[position + 2]);
                    break;
                }
                position+=3;
            }
        }
    }
}

void get_active_controllable_events( unsigned char *events ){
    unsigned char i,j;

    /* Disable all non controllable events */
    for( i=0; i<ev_number; i++ ){
        if( !ev_controllable[i] ){
            events[i] = 0;
        }
    }

    /* Check disabled events for all supervisors */
    for(i=0; i<sup_number; i++){
        unsigned long int position;
        unsigned char ev_disable[${ev_number}] = { ${events_set} };
        unsigned char num_transitions;
        position = get_state_position(i, sup_current_state[i]);
        for( j=0; j<ev_number; j++ ){

            /*if supervisor don't have this event, it can't disable the event*/
            if( !sup_events[i][j] ){
                ev_disable[j] = 0;
            }
        }
        /*if supervisor have a transition with the event in the current state, it can't disable the event */
        num_transitions = sup_data[position];
        position++;
        while(num_transitions--){
            ev_disable[ sup_data[position] ] = 0;
            position += 3;
        }

        /* Disable for current supervisor states */
        for( j=0; j<ev_number; j++ ){
            if( ev_disable[j] == 1 ){
                events[ j ] = 0;
            }
        }
    }
}
]], {
    events         = table.concat( events, '\n' ),
    ev_number      = #context.events,
    ev_controllable = table.concat( ev_controllable, ',' ),
    sup_events     = table.concat( sup_events, ',' ),
    sup_number     = context.automatons:len(),
    initial_states = table.concat(initial_states, ','),
    sup_data_pos   = table.concat(sup_data_pos, ','),
    data_len       = data_len,
    sup_data       = table.concat(sup_data, ','),
    events_set     = table.concat(events_set, ',' ),
})
end

------------------------------------------------------------------------
--                               CHOICE                               --
------------------------------------------------------------------------
Template.choice_random = function( context )

local events_set     = {}
for k_event, event in ipairs(context.events) do
    events_set[#events_set +1] = 1
end

return sff([[
unsigned char get_next_controllable( unsigned char *event ){
    unsigned char events[${ev_number}] = { ${events_set} };
    int count_actives, random_pos;
    unsigned char i;

    get_active_controllable_events( events );
    count_actives = 0;
    for(i=0; i<${ev_number}; i++){
        if( events[i] ){
            count_actives++;
        }
    }
    if( count_actives ){
        random_pos = pic_rand() % count_actives;
        for(i=0; i<${ev_number}; i++){
            if( !random_pos && events[i] ){
                *event = i;
                return 1;
            } else if( events[i] ){
                random_pos--;
            }
        }
    } else {
        return 0;
    }
}
]],{
    events_set = table.concat( events_set, ',' ),
    ev_number  = #context.events,
})

end

Template.choice_global = [[

]]

Template.choice_globalrandom = [[

]]

Template.choice_local = [[

]]

Template.choice_localrandom = [[

]]


------------------------------------------------------------------------
--                               PLAYER                               --
------------------------------------------------------------------------
Template.player = [[
void main_loop(){
    while(1){
        unsigned char event;
        //clear buffer, executing all no controllable events
        while( input_buffer_get( &event ) ){
            make_transition( event );
            callback( event );
        }
        if( get_next_controllable( &event ) ){
            make_transition( event );
            callback( event );
        }
    }
}
]]


------------------------------------------------------------------------
--                              MAIN                                  --
------------------------------------------------------------------------

Template.main = function ( context )
    local random_fn =
        context.random_fn == CodeGen.RANDOM_PSEUDOFIX and 'random_pseudofix' or
        context.random_fn == CodeGen.RANDOM_PSEUDOAD  and 'random_pseudoad'  or
        context.random_fn == CodeGen.RANDOM_AD        and 'random_ad'

    local init_random = context.random_fn == CodeGen.RANDOM_PSEUDOAD and [[
        seed = get_ad_seed();
    ]] or ''

    local choice_fn =
        context.choice_fn == CodeGen.CHOICE_RANDOM       and 'choice_random'       or
        context.choice_fn == CodeGen.CHOICE_GLOBAL       and 'choice_global'       or
        context.choice_fn == CodeGen.CHOICE_GLOBALRANDOM and 'choice_globalrandom' or
        context.choice_fn == CodeGen.CHOICE_LOCAL        and 'choice_local'        or
        context.choice_fn == CodeGen.CHOICE_LOCALRANDOM  and 'choice_localrandom'

local input_interruption_load =
    context.input_fn == INPUT_TIMER and sff([[
enable_interrupts(GLOBAL);
//Timer
setup_timer_1(T1_INTERNAL|T1_DIV_BY_1);
set_timer1(${timer_interval});
enable_interrupts(INT_TIMER1);
]], {
    timer_interval = context.timer_interval,
}) or context.input_fn == INPUT_MULTIPLEXED and sff([[
enable_interrupts(GLOBAL);
//Extermal Interruption
ext_int_edge(0,H_TO_L);
clear_interrupt(${interruption});
enable_interrupts(${interruption});
]],{
    interruption = context.interruption,
}) or ''

--~//#device adc=10; //configurar o AD para 10 bits (padrão é 8)

    return sf([[
#include <18F4620.h>
#fuses NOMCLR,EC_IO,H4,NOWDT,NOPROTECT,NOLVP,NODEBUG
#use delay(clock=20000000)
#include <stdio.h>
#include <stdlib.h>
#include <lcd.c>

/* Struct's */
${automatons_data}

/* RANDOM */
${%s}

/* IN_read */
${input_read}

/* Choice */
${%s}

/*Callback*/
${callback}

/* Player */
${player}


void main(){
    port_b_pullups(TRUE);
    %s
    %s
    main_loop();
}
    ]], random_fn, choice_fn, input_interruption_load, init_random )
end
