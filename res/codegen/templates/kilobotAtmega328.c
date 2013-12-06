#include "libkilobot.h"

int move_type      = 0;
int move_start     = 0; //start_move
int move_time      = 0;
int move_stopEvent = 0;
int light          = 0;
int neighbor       = 0;

void moveForward( int t ){
    move_type  = 0;
    move_time  = t;
    move_start = 1;
}
void moveTurnCCW( int t ){
    move_type  = 1;
    move_time  = t;
    move_start = 1;
}
void moveTurnCW( int t ){
    move_type  = 2;
    move_time  = t;
    move_start = 1;
}
void moveStop(){
    move_type  = 0;
    move_time  = 0;
    move_start = 0;
}

{% if extra_numNeighbor == 1 %}
    int num_neighbors     = 0;
    char nn_msg_code      = 0;
    char nn_msg_received[32];

    void nn_clear_msg(){
        for(int i=0;i<32;i++){
            nn_msg_received[i] = 0;
        }
        num_neighbors = 0;
    }

    void nn_update(char code){
        int pos    = code/8;
        char subpos = 1 << code%8;
        if (!(nn_msg_received[pos] & subpos)){
            nn_msg_received[pos] = nn_msg_received[pos] | subpos;
            num_neighbors++;
        }
        if( code == nn_msg_code ){
            nn_msg_code = rand()%256;
            message_out(nn_msg_code, 0x00, 0xFE);
        }
    }
{% end %}

{% if extra_rgb %}
char R,G,B;
{% end %}

{{ code_global }}

/* Struct's */
{% for k_event, event in ipairs(events) %}
    #define EV_{{event.name}} {{k_event-1}}
{% end %}

{% with
    var_data         = {},
    var_data_pos     = {},
    var_state_map    = {},
%}
{% for k_automaton, automaton in automata:ipairs() %}
    {% set var_data_pos[k_automaton] = #var_data %}
    {% for k_state, state in automaton.states:ipairs() %}
        {% set var_state_map[ state ] = k_state - 1 %}
    {% end %}
    {% for k_state, state in automaton.states:ipairs() %}
        {% set var_data[#var_data +1] = state.transitions_out:len() %}
        {% for k_transition, transition in state.transitions_out:ipairs() %}
            {% set var_data[#var_data +1] = 'EV_' .. transition.event.name %}
            {% set var_data[#var_data +1] = math.floor( var_state_map[ transition.target ] / 256 ) %}
            {% set var_data[#var_data +1] = var_state_map[ transition.target ] % 256 %}
        {% end %}
    {% end %}
{% end %}
const unsigned char ev_number = {{ #events }};
const unsigned char ev_controllable[{{ #events }}] = { {% for k_event, event in ipairs(events) %}{{ event.controllable and 1 or 0 }}{% notlast %},{% end %} };
const unsigned char sup_events[{{ automata:len() }}][{{ #events }}] = { {% for k_automaton, automaton in automata:ipairs() %}{ {% for i = 1, #events %}{{ sup_events[k_automaton][i] and 1 or 0 }}{% notlast %},{% end %} }{% notlast %},{% end %} };
const unsigned char sup_number = {{ automata:len() }};
unsigned long int sup_current_state[{{ automata:len() }}]  = { {% for k_automaton, automaton in automata:ipairs() %}{{automaton.initial - 1}}{% notlast %},{% end %} };
const unsigned long int sup_data_pos[{{ automata:len() }}] = { {{ table.concat(var_data_pos, ',') }} };
const unsigned char sup_data[ {{ #var_data }} ] = { {{ table.concat( var_data,',' ) }} };

unsigned long int get_state_position( unsigned char supervisor, unsigned long int state ){
    unsigned long int position;
    unsigned long int s;
    unsigned long int en;
    position = sup_data_pos[ supervisor ];
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
                    sup_current_state[i] = (sup_data[position + 1] * 256) + (sup_data[position + 2]);
                    break;
                }
                position+=3;
            }
        }
    }
}
{% endwith %}

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
        unsigned char ev_disable[23], k;
        unsigned char num_transitions;
        for(k=0; k<23;k++){
         ev_disable[k] = 1;
        }
        for( j=0; j<ev_number; j++ ){

            /*if supervisor don't have this event, it can't disable the event*/
            if( !sup_events[i][j] ){
                ev_disable[j] = 0;
            }
        }
        /*if supervisor have a transition with the event in the current state, it can't disable the event */
        position = get_state_position(i, sup_current_state[i]);
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

/* IN_read */
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

unsigned char input_buffer_check_empty(){
    return input_buffer_pnt_add == input_buffer_pnt_get;
}

{% for k_event, event in ipairs(events) %}
    {% if not event.controllable %}
        unsigned char input_read_{{ event.name }}(){
            {{ event_code[ event.name ] and event_code[ event.name ].input or 'return 0;'  }}
        }
    {% end %}
{% end %}

unsigned char input_read( unsigned char ev ){
    unsigned char result = 0;
    switch( ev ){
    {% for k_event, event in ipairs(events) %}
        {% if not event.controllable %}
        case EV_{{ event.name }}:
            result = input_read_{{ event.name }}();
            break;
        {% end %}
    {% end %}
    }
    return result;
}

unsigned char last_events[{{#events}}] = { {% for i = 1,#events %}0{% notlast %},{% end %} };

void update_input(){
    unsigned char i;
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
}

/*choices*/
unsigned char get_next_controllable( unsigned char *event ){
    unsigned char events[{{ #events }}] = { {% for k_event, event in ipairs(events) %}1{% notlast %}, {% end %} };
    unsigned long int count_actives, random_pos;
    unsigned char i;

    get_active_controllable_events( events );
    count_actives = 0;
    for(i=0; i<{{ #events }}; i++){
        if( events[i] ){
            count_actives++;
        }
    }
    if( count_actives ){
        random_pos = rand() % count_actives;
        for(i=0; i<{{ #events }}; i++){
            if( !random_pos && events[i] ){
                *event = i;
                return 1;
            } else if( events[i] ){
                random_pos--;
            }
        }
    }
    return 0;
}

/*Callback*/
{% for k_event, event in ipairs(events) %}
    void callback_{{ event.name }}(){
        {{ event_code[ event.name ] and event_code[ event.name ].output or ''  }}
    }
{% end %}

void callback( unsigned char ev ){
    switch( ev ){
        {% for k_event, event in ipairs(events) %}
        case EV_{{ event.name }}:
            callback_{{ event.name }}();
            break;
        {% end %}
    }
}

void user_program(void)
{
    extern volatile int clock;
    
    get_message();
    if( message_rx[5] == 1 ){
        neighbor   = 1;
        {% if extra_numNeighbor == 1 %}
        nn_update( message_rx[0] );
        {% end %}
        {{ code_message }}
    }

    if(move_start==1){
        if(move_type==0){
            set_motor(0xa0,0xa0);//spin up motors
            _delay_ms(55);
            set_motor(cw_in_straight, ccw_in_straight);//set to move straight
        } else if(move_type==1){
            set_motor(0, 0xa0);//spin up motor
            _delay_ms(55);
            set_motor(0, ccw_in_place);//set to move ccw
        } else if(move_type==2){
            set_motor(0xa0,0);//spin up motor
            _delay_ms(55);
        set_motor(cw_in_place ,0);//set to move cw
        }

        move_start=2;//mark that i am currently moving
    }
    else if(move_start==0){
        set_motor(0,0); //stop motors
    }
    
    //AUTOMATA PLAYER
    update_input();
    unsigned char event;
    while( input_buffer_get( &event ) ){//clear buffer, executing all no controllable events (NCE)
        make_transition( event );
        callback( event );
    }
    if( get_next_controllable( &event ) ){//find controllable event (CE)
        if( input_buffer_check_empty() ){ //Only execute CE if NCE input buffer is empty
            make_transition( event );
            callback( event );
        }
    }
        
    if(clock>2000){ //near to each half second
        //CLEAR
        clock          = 0;
        neighbor       = 0;
        move_stopEvent = 0;
        {% if extra_numNeighbor == 1 %}
        nn_clear_msg();
        {% end %}
        {{ code_clear }}
        
        //GET LIGHT
        int local_light      = get_ambient_light();
        if( local_light != -1 ){
            light = local_light;
        }
        
        //CHECK MOVE TIME
        if ( move_time > 0 ){
            move_time--;
            if( move_time == 0 ){
                move_start     = 0;
                move_stopEvent = 1;
            }
        }
        
        //CUSTOM UPDATE CODE
        {{ code_update }}
        
        {% if extra_rgb %}
        set_color(R,G,B);
        {% end %}
    }
}

int main(void)
{
    {% if random_fn == RANDOM_PSEUDOVOLTAGE %}
        int randseed = 0;
        for(int i=0;i<30;i++)
            randseed+=measure_voltage();
        srand( randseed );
    {% end %}
    
    {% if extra_rgb %}
    R = 0;
    G = 0;
    B = 0;
    {% end %}
    
    {% if extra_numNeighbor == 1 %}
    nn_clear_msg();
    {% end %}
    
    {{ code_init }}
    
    // initialise the robot
    init_robot();

    // loop and run each time the user program
    main_program_loop(user_program);

    return 0;
}
