#include "generic_mic_distributed.h"

{% with
    var_data         = {},
    var_data_pos     = {},
    var_state_map    = {},
%}
    {% for k_automaton, automaton in automata:ipairs_range(sup_start,sup_end) %}
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
    const unsigned char     ev_controllable[{{ #events }}] = { {% for k_event, event in ipairs(events) %}{{ event.controllable and 1 or 0 }}{% notlast %},{% end %} };
    const unsigned char     sup_events[{{ sup_end - sup_start + 1 }}][{{ #events }}] = { {% for k_automaton, automaton in automata:ipairs_range(sup_start,sup_end) %}{ {% for i = 1, #events %}{{ sup_events[k_automaton][i] and 1 or 0 }}{% notlast %},{% end %} }{% notlast %},{% end %} };
    const unsigned long int sup_init_state[{{ automata:len() }}]     = { {% for k_automaton, automaton in automata:ipairs() %}{{automaton.initial - 1}}{% notlast %},{% end %} };
    unsigned long int       sup_current_state[{{ automata:len() }}]  = { {% for k_automaton, automaton in automata:ipairs() %}{{automaton.initial - 1}}{% notlast %},{% end %} };    
    const unsigned long int sup_data_pos[{{ sup_end - sup_start + 1 }}] = { {{ table.concat(var_data_pos, ',') }} };
    const unsigned char     sup_data[ {{ #var_data }} ] = { {{ table.concat( var_data,',' ) }} };
{% endwith %}

typedef struct Scallback {
    void (*callback)( void* data );
    unsigned char (*check_input) ( void* data );
    void* data;
} Tcallback;

Tcallback callback[ NUM_EVENTS ];

unsigned long int convert_2chars_to_int( unsigned char high_char, unsigned char low_char ){
    return high_char * 256 + low_char;
}

void convert_int_to_2chars( unsigned long int value, unsigned char *high_char, unsigned char *low_char ){
    *high_char = value/256;
    *low_char = value % 256;
}

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

unsigned long int next_state( unsigned char supervisor, unsigned long int state, unsigned char event ){
    unsigned long int position;
    unsigned char num_transitions;
    if(sup_events[ supervisor ][ event ]){
        position        = get_state_position(i, state);
        num_transitions = sup_data[ position ];
        position++;
        while(num_transitions--){
            if(sup_data[ position ] == event){
                return convert_2chars_to_int( sup_data[position + 1], sup_data[position + 2] )
            }
            position+=3;
        }
    }
    return state;
}

/* IN_read */
unsigned char input_buffer[256];
unsigned char input_buffer_pnt_add = 0;
unsigned char input_buffer_pnt_get = 0;

unsigned char input_buffer_check_empty(){
    return input_buffer_pnt_add == input_buffer_pnt_get;
}

unsigned char input_buffer_get( unsigned char *event ){
    if( input_buffer_check_empty() ){
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
    if( ev < NUM_EVENTS && callback[ ev ].check_input != NULL )
        return callback[ ev ].check_input( callback[ ev ].data );
    return 0;
}

unsigned char last_events[NUM_EVENTS];
void update_input(){
    unsigned char i;
    for(i=0;i<NUM_EVENTS;i++){
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

void execCallback( unsigned char ev ){
    if( ev < NUM_EVENTS && callback[ ev ].callback != NULL )
        callback[ ev ].callback( callback[ ev ].data );
}

/** Distributed **/
/* MSG
 * 0-1: Header
 * 2: Lenght
 * 3: Operation code : 0x01 -> calculate controllable events, 0x02 : calculate next state
 * 4-5: Robot ID
 * next 2*NUM_SUPERVISORS: current state
 * next NUM_SUPERVISORS/8.0: Supervisor Check
 * 
 * -2,-1: check
 * */
/* MSG (NEW)
 * byte | value    = content
 * 0    : 0x02     = Start delimiter
 * 1    : 0x52     = Packet Type ID (see other at LMX9820A datasheet) 0x[52,43,69,72]
 * 2    : 0x0f     = Opcode (eg 0x0f : send)
 * 3-4  : low/high = Data Lenght
 * 5    : low      = low byte checksum from 1 to 4 
 * 7-*  : data     = Packet Data as follow, size = Data Lenght v[3](low) v[4](high)
 *      7 : operation Code
 *      8-11 : Robot ID(PID) ? can we get by bluetooth driver?
 *      next 2*NUM_SUPERVISORS: current state
 *      next NUM_SUPERVISORS/8.0: Supervisor Check
 *      [VARIABLE ACORDING TO OPERATION]
 * -1   : 0x03     = end Delimiter
 *
 * OLD:
 * 0-1: Header
 * 2: Lenght
 * 3: Operation code : 0x01 -> calculate controllable events, 0x02 : calculate next state
 * 4-5: Robot ID
 * next 2*NUM_SUPERVISORS: current state
 * next NUM_SUPERVISORS/8.0: Supervisor Check
 * 
 * -2,-1: check
 * */

unsigned char msgBuffer[256];

void msg_transmit(){
    e_send_uart1_char(msgBuffer, (int) msgBuffer[2]);
    while(e_uart1_sending());
}

unsigned char msg_read_check(){
    unsigned char position  = 3;
    unsigned int  robotID;
    //Header
    if( !e_getchar_uart1( &msgBuffer[0] ) ){
        return MSG_NONE;
    }
    if( !e_getchar_uart1( &msgBuffer[1] ) ){
        return MSG_NONE;
    }
    
    //Lenght
    if( !e_getchar_uart1( &msgBuffer[2] ) ){
        return MSG_NONE;
    }
    
    while( position < msgBuffer[2] && e_getchar_uart1( &msgBuffer[position] ) ){
        position++;
    }
    
    robotID = convert_2chars_to_int( msgBuffer[4], msgBuffer[5] );
    
    if( id == RobotID ){
        if( msgBuffer[3] == 0x01 )
            return MSG_RESPONSE_EVENT;
        if( msgBuffer[3] == 0x02 )
            return MSG_RESPONSE_STATE;
    } else {
        if( msgBuffer[3] == 0x01 )
            return MSG_REQUEST_EVENT;
        if( msgBuffer[3] == 0x02 )
            return MSG_REQUEST_STATE;
    }
    
    return MSG_INVALID;
}


//Check if all supervisors were checked: theoretically true, if false, error, send again
unsigned char msg_check_all_supervisors(){
    //TODO
}

void msg_create_check(){
    unsigned char checkXor = 0x00;
    unsigned char checkSum = 0x00;
    unsigned char i;
    unsigned char len = msgBuffer[3] - 2;
    for(i=0;i<len;i++){
        checkXor ^= msgBuffer[ i ];
        checkSum += msgBuffer[ i ];
    }
    msgBuffer[len]   = checkXor;
    msgBuffer[len+1] = checkSum;
}

///************* CALCULATE ENABLE CONTROLLALE EVENTS ****************///

void msg_disabled_non_controllable_event(){
    unsigned char i,pos;
    //~ pos   = 6 + 2*NUM_SUPERVISORS + DIVUP(NUM_EVENTS,8.0);
    pos   = 6 + 2*NUM_SUPERVISORS + DIVUP(NUM_SUPERVISORS,8.0);
    
    /* Disable all non controllable events */
    for( i=0; i<NUM_EVENTS; i++ ){
        if( !ev_controllable[i] )
            msgBuffer[pos + i/8] &= 0xff - ( 0x80 >> (i%8) );
    }
}

void msg_calculate_disabled_event(){
    unsigned char     i,msgPos;
    unsigned long int position;
    unsigned char     ev_disable[NUM_EVENTS], k;
    unsigned char     num_transitions;
    msgPos   = 6 + 2*NUM_SUPERVISORS + DIVUP(NUM_EVENTS,8.0);
    
    for(i=SUP_START;i<=SUP_END;i++){
        for(k=0; k<NUM_EVENTS;k++){
            if( !sup_events[i][j] ){
                ev_disable[j] = 0; // if supervisor don't have this event, it can't disable the event
            } else {
                ev_disable[k] = 1;
            }
        }

        /*if supervisor have a transition with the event in the current state, it can't disable the event */
        position        = get_state_position(i, sup_current_state[i]);
        num_transitions = sup_data[position];
        position++;
        while(num_transitions--){
            ev_disable[ sup_data[position] ] = 0;
            position += 3;
        }

        /* Disable for current supervisor states */
        for( j=0; j<NUM_EVENTS; j++ ){
            if( ev_disable[j] == 1 ){
                msgBuffer[ msgPos + j/8 ] &= 0xff - ( 0x80 >> (j%8) );
            }
        }   
    }
}

///********************* CALCULATE NEXT STATE ***********************///

void msg_calculate_next_state(){
    unsigned char i, pos, pInit;
    unsigned char event
    pInit   = 6 + 2*NUM_SUPERVISORS + DIVUP(NUM_EVENTS,8.0);
    event = msgBuffer[pInit];
    for(i=SUP_START;i<=SUP_END;i++){
        pos = pInit + i/8;
        if( !( msgBuffer[pos] & ( 0x80 >> (i%8) ) ) ){ //check if supervisor was already checked
            msgBuffer[pos] |= 0x80 >> (i%8);           //mark the supervisor as checked
            
            pos   = 6 + 2*i;
            state = convert_2chars_to_int( msgBuffer[pos], msgBuffer[pos+1] );
            state = next_state( i, state, event );
            convert_int_to_2chars( state, &msgBuffer[pos], &msgBuffer[pos+1] );
        }
    }
}

///************************** INTERFACE *****************************///

void request_next_controllable(){
    unsigned char i,j;
    //Header
    msgBuffer[0] = 0xaa; //Start - handshake
    msgBuffer[1] = 0x05; //Start - handshake
    msgBuffer[2] = 6 + 2*NUM_SUPERVISORS + DIVUP( NUM_SUPERVISORS,8.0 ) + DIVUP( NUM_EVENTS,8.0 ) + 2;
    
    //Content
    msgBuffer[3] = 0x01; //Operation code
    convert_int_to_2chars( RobotID, &msgBuffer[4], &msgBuffer[5] );
    j=6;
    for(i=0; i<NUM_SUPERVISORS; i++){ //Current State
        convert_int_to_2chars( sup_current_state[i], &msgBuffer[++j], &msgBuffer[++j] );
    }
    for(i=0; i<NUM_SUPERVISORS; i+=8){ //Supervisor Check
        msgBuffer[++j]=0x00;
    }
    for(i=0; i<NUM_EVENTS; i+=8){ //Enabled Events
        msgBuffer[++j]=0xff;
    }
    msg_disabled_non_controllable_event()
    msg_calculate_disabled_event();
    msg_create_check();
    msg_transmit();
}

void request_new_state( unsigned char ev ){
    unsigned char i,j=0;
    
    //Header
    msgBuffer[0] = 0xaa; //Start - handshake
    msgBuffer[1] = 0x05; //Start - handshake
    msgBuffer[2] = 6 + 2*NUM_SUPERVISORS + DIVUP(NUM_SUPERVISORS,8.0) + 3;
    
    //Content
    msgBuffer[3] = 0x02; //Operation code
    convert_int_to_2chars( RobotID, &msgBuffer[4], &msgBuffer[5] ); //Robot code TODO:get robot code
    j=6;
    for(i=0; i<NUM_SUPERVISORS; i++){
        convert_int_to_2chars( sup_current_state[i], &msgBuffer[++j], &msgBuffer[++j] );
    }
    for(i=0; i<NUM_SUPERVISORS; i+=8){ //Supervisor Check
        msgBuffer[++j]=0x00;
    }
    msgBuffer[++j]=ev;
    msg_calculate_next_state();
    msg_create_check();
    msg_transmit();
}

unsigned char process_response_event( unsigned char *event ){
    unsigned char countActives = 0, i, pos, randomPos;
    
    pos   = 6 + 2*NUM_SUPERVISORS + DIVUP(NUM_SUPERVISORS,8.0);
    for( i=0; i<NUM_EVENTS; i++ ){
        if( ev_controllable[i] &&  ( msgBuffer[pos + i/8] & ( 0x80 >> (i%8) ) ) ){
            countActives++;
        }
    }
    
    if( countActives ){
        randomPos = rand() % countActives;
        for(i=0; i<NUM_EVENTS; i++){
            if( !randomPos && ( msgBuffer[pos + i/8] & ( 0x80 >> (i%8) ) ) ){
                *event = i;
                return 1;
            } else if( ( msgBuffer[pos + i/8] & ( 0x80 >> (i%8) ) ) ){
                randomPos--;
            }
        }
    }
    
    return 0;
}

void process_response_state(){
    unsigned char i,pos;
    for(i=0;i<NUM_SUPERVISORS;i++){
        pos                  = 6 + 2*i;
        sup_current_state[i] = convert_2chars_to_int( msgBuffer[pos], msgBuffer[pos+1] );
    }
}

void process_request_event(){
    msg_calculate_disabled_event();
    msg_create_check();
    msg_transmit();
}
void process_request_state(){
    msg_calculate_next_state();
    msg_create_check();
    msg_transmit();
}

/// PUBLIC:

void SCT_init(){
    int i;
    for(i=0; i<NUM_EVENTS; i++){
        last_events[i] = 0;
        callback[i].callback    = NULL;
        callback[i].check_input = NULL;
        callback[i].data        = NULL;
    }
    RobotID = 32000; //TODO
}

void SCT_reset(){
    int i;
    for(i=0; i<NUM_SUPERVISORS; i++){
        sup_current_state[i] = sup_init_state[i];
    }
    for(i=0; i<NUM_EVENTS; i++){
        last_events[i] = 0;
    }
}

void SCT_add_callback( unsigned char event, void (*clbk)( void* ), unsigned char (*ci)( void* ), void* data ){
    callback[ event ].callback    = clbk;
    callback[ event ].check_input = ci;
    callback[ event ].data        = data;
}


//AUTOMATA PLAYER
void SCT_run_step(){
    static char state = STATE_IDLE_ALL;
    unsigned char event;
    unsigned char msg_type;
    
    update_input();
    
    if( state == STATE_IDLE_ALL ){
        if( input_buffer_get( &event ) ){
            request_new_state( event );
            execCallback( event );
            state = STATE_WAIT;
        } else {
            request_next_controllable();
            state = STATE_WAIT;
        }
    }
    if( state == STATE_IDLE_UC ){ //reduce number of calls
        if( input_buffer_get( &event ) ){
            request_new_state( event );
            execCallback( event );
            state = STATE_WAIT;
        }
    }
    
    //Process income message
    msg_type = msg_read_check();
    if( msg_type == MSG_RESPONSE_STATE ){
        process_response_state();
        state = STATE_IDLE_ALL
    }
    if( msg_type = MSG_RESPONSE_EVENT ){
        if( process_response_event( &event ) ){
            execCallback( event );
            request_new_state( event );
            state = STATE_WAIT;
        } else {
            state = STATE_IDLE_UC;
        }
    }
    if( msg_type == MSG_REQUEST_STATE ){
        process_request_state();
    }
    if( msg_type == MSG_REQUEST_EVENT ){
        process_request_event();
    }
}
