#include <shefpuck/bluetooth.h>

#include "generic_mic.h"
#define FN_AP 1
#define FN_SUP 1

#if FN_SUP
{% noblankline %}
{% with
    var_data         = {},
    var_data_pos     = {},
    var_state_map    = {},
%}
    {% for k_automaton, automaton in ipairs( my_automata_set ) %}
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
    /**************************************************************************/
    /********************************** DATA **********************************/
    /**************************************************************************/
    const unsigned char     my_automata_check[ NUM_SUPERVISORS ] = { {{ table.concat(my_automata_check, ',') }} };
    const unsigned char     ev_controllable[ NUM_EVENTS ]        = { {% for k_event, event in ipairs(events) %}{{ event.controllable and 1 or 0 }}{% notlast %},{% end %} };
    const unsigned long int sup_init_state[ NUM_SUPERVISORS ]    = { {% for k_automaton, automaton in automata:ipairs() %}{{automaton.initial - 1}}{% notlast %},{% end %} };
    unsigned long int       sup_current_state[ NUM_SUPERVISORS ] = { {% for k_automaton, automaton in automata:ipairs() %}{{automaton.initial - 1}}{% notlast %},{% end %} };

    const unsigned char     sup_events[ MY_NUM_AUTOMATA ][ NUM_EVENTS ] = { {% for k_automaton, automaton in ipairs( my_automata_set ) %}{ {% for i = 1, #events %}{{ sup_events[k_automaton][i] and 1 or 0 }}{% notlast %},{% end %} }{% notlast %},{% end %} };
    const unsigned long int sup_data_pos[ MY_NUM_AUTOMATA ] = { {{ table.concat(var_data_pos, ',') }} };
    const unsigned char     sup_data[ {{ #var_data }} ] = { {{ table.concat( var_data,',' ) }} };
{% endwith %}
{% endnoblankline %}
#endif


#if FN_AP

    /**************************************************************************/
    /******************************* callbacks ********************************/
    /**************************************************************************/
typedef struct Scallback {
    void (*callback)( void* data );
    unsigned char (*check_input) ( void* data );
    void* data;
} Tcallback;

Tcallback callback[ NUM_EVENTS ];

    /**************************************************************************/
    /********************************* Utils **********************************/
    /**************************************************************************/

    char get_bit( char *buffer, int offset, int bit ){
        char *b = &buffer[ offset + bit/8 ];
        return b[0] & ( 1<<(bit%8) );
    }

    void set_bit( char *buffer, int offset, int bit, char value ){
        char *b = &buffer[ offset + bit/8 ];
        b[0] &=  ~( 1 << (bit%8) ); //unset bit
        if( value ){
            b[0] |= ( 1 << (bit%8) ); //set if value != 0
        }
    }

    /**************************************************************************/
    /***************************** Calculations *******************************/
    /**************************************************************************/

unsigned char get_local_supervisor_position( unsigned char global_supervisor_position ){
    return global_supervisor_position + MY_FIRST_AUTOMATA;
}

unsigned long int get_state_position( unsigned char local_supervisor_positioin, unsigned long int state ){
    unsigned long int position;
    unsigned long int s;
    unsigned long int en;
    position = sup_data_pos[ local_supervisor_positioin ];
    for(s=0; s<state; s++){
        en       = sup_data[position];
        position += en * 3 + 1;
    }
    return position;
}

void calculate_next_state( unsigned char event, unsigned long int state_vector[], unsigned char check_vector[] ){
    unsigned char i;
    unsigned long int position;
    unsigned char num_transitions;

    for(i=0; i<NUM_SUPERVISORS; i++){
        if( (my_automata_check[i] == 1) && (check_vector[i] == 0) ){ //Do I have this supervisor and it was not calculated yet
            check_vector[ i ] = 1;

            unsigned char local_sup_pos = get_local_supervisor_position( i );
            if( sup_events[ local_sup_pos ][ event ] ){
                position        = get_state_position( local_sup_pos, state_vector[i] );
                num_transitions = sup_data[ position ];
                position++;
                while( num_transitions-- ){
                    if( sup_data[ position ] == event ){
                        state_vector[ i ] = ( sup_data[ position + 1 ] * 256 ) + ( sup_data[ position + 2 ] );
                        break;
                    }
                    position+=3;
                }
            }
            
        }
    }
}

void start_get_active_controllable_events( unsigned char *events ){
    /* Disable all non controllable events */
    unsigned char i;
    for( i=0; i<NUM_EVENTS; i++ ){
        if( !ev_controllable[i] ){
            events[i] = 0;
        } else {
            events[i] = 1;
        }
    }
}

void get_active_controllable_events( unsigned char *events, unsigned long int state_vector[], unsigned char check_vector[] ){
    unsigned char i,j;

    /* Check disabled events for all supervisors */
    for(i=0; i<NUM_SUPERVISORS; i++){
        if( (my_automata_check[i] == 1) && (check_vector[i] == 0) ){ //Do I have this supervisor and it was not calculated yet
            check_vector[ i ] = 1;
            
            unsigned char local_sup_pos = get_local_supervisor_position( i );
            unsigned long int position;
            unsigned char ev_disable[ NUM_EVENTS ], num_transitions;

            /*Disable all*/
            for(j=0; j<NUM_EVENTS;j++){
             ev_disable[ j ] = 1;
            }

            for( j=0; j<NUM_EVENTS; j++ ){
                /*if supervisor don't have this event, it can't disable the event*/
                if( !sup_events[ local_sup_pos ][ j ] ){
                    ev_disable[ j ] = 0;
                }
            }
            
            /*if supervisor have a transition with the event in the current state, it can't disable the event */
            position = get_state_position( local_sup_pos, state_vector[ i ] );
            num_transitions = sup_data[ position ];
            position++;
            while( num_transitions-- ){
                ev_disable[ sup_data[ position ] ] = 0;
                position += 3;
            }

            /* Disable for current supervisor states */
            for( j=0; j<NUM_EVENTS; j++ ){
                if( ev_disable[ j ] == 1 ){
                    events[ j ] = 0;
                }
            }
            
        }
    }
}

unsigned char end_get_active_controllable_events( unsigned char *events ){
    unsigned char i, count_actives = 0;
    for(i=0; i<NUM_EVENTS; i++){
        if( events[i] ){
            count_actives++;
        }
    }
    
    return count_actives; //TODO: return number of active controllable events
}

int check_all_supervisors_considered( unsigned char check_vector[] ){
    int i;
    for(i=0;i<NUM_SUPERVISORS;i++){
        if( !check_vector[ i ] ){
            return 0;
        }
    }
    return 1;
}

/******************************************************************************/
/*************************** Local operations *********************************/
/******************************************************************************/

void update_states( unsigned long int state_vector[] ){
    int i;
    for(i=0;i<NUM_SUPERVISORS;i++){
        sup_current_state[ i ] = state_vector[ i ];
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

/*choices*/
/*
unsigned char get_next_controllable( unsigned char *event ){ //DIST------
    unsigned char events[NUM_EVENTS], i, count_actives;
    unsigned long int random_pos;
    
    count_actives = get_active_controllable_events( events );
    
    if( count_actives ){
        random_pos = rand() % count_actives;
        for(i=0; i<NUM_EVENTS; i++){
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
*/


void execCallback( unsigned char ev ){
    if( ev < NUM_EVENTS && callback[ ev ].callback != NULL )
        callback[ ev ].callback( callback[ ev ].data );
}

/******************************************************************************/
/************************** Communication Functions ***************************/
/******************************************************************************/
#define MSG_NONE 0
#define MSG_STATE 1
#define MSG_EVENT 2

/* Message protocol
<0> init bit 0x17
<1> message type MSG_STATE, MSG_EVENT
<2 to 7> requester BT address
<8 to ...> the current state vector bit mask

In MSG_STATE:
<1 bit> the event

In MSG_EVENT
<...> the bit mask of all events (controllable) to disable

*/

void request_new_state( unsigned char event ){
    char s[64];
}

void request_enabled_controllable_events(){
    char s[64];
}

/*return the message type*/
int get_income_message( char *message_id, char *data ){
    return 0;
}


/******************************************************************************/
/*********************************** PUBLIC ***********************************/
/******************************************************************************/
#define STATE_IDLE 0
#define STATE_WAIT_MSG 1
#define STATE_WAIT_UC 2

void SCT_init(){
    int i;
    for(i=0; i<NUM_EVENTS; i++){
        last_events[i] = 0;
        callback[i].callback    = NULL;
        callback[i].check_input = NULL;
        callback[i].data        = NULL;
    }
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

void SCT_run_step(){//DIST------
    //AUTOMATA PLAYER
    static int state       = STATE_IDLE;
    static char message_id = 0;
    unsigned char event;

    update_input();
    
    if( state == STATE_IDLE || state == STATE_WAIT_UC ){
        if( input_buffer_get( &event ) ){
            request_new_state( event );
            execCallback( event );
        } else {
            request_enabled_controllable_events();
        }
        state = WAIT_MSG;
    }

    char msg_id[6], msg_data[64];
    char msg_type = get_income_message( msg_id, msg_data );

    if( msg_type == MSG_STATE ){
        if( bt_compare_device_addrs( msg_id, bt_get_state()->local_address, 6) == 0 ){
            update_states( ... );
            state = STATE_IDLE;
        } else {
            calculate_next_state( ... );
            transmit( ... );
        }
    }
    
    if( msg_type == MSG_EVENT ){
        if( bt_compare_device_addrs( msg_id, bt_get_state()->local_address, 6) == 0 ){
            end_get_active_controllable_events( ... );
            if( ... ){
                request_new_state( event );
                execCallback( event );
            } else {
                state = STATE_WAIT_UC;
            }
        } else {
            calculate_next_state( ... );
            transmit( ... );
        }
    }





    
    //~ update_input();
    //~ unsigned char event;
    //~ while( input_buffer_get( &event ) ){//clear buffer, executing all no controllable events (NCE)
        //~ make_transition( event );
        //~ execCallback( event );
    //~ }
    //~ if( get_next_controllable( &event ) ){//find controllable event (CE)
        //~ //if( input_buffer_check_empty() ){ //Only execute CE if NCE input buffer is empty
        //~ make_transition( event );
        //~ execCallback( event );
        //~ //}
    //~ }
}
#endif
