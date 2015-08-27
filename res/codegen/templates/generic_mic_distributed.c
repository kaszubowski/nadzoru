#include "{{ header_file }}"

#include <motor_led/e_epuck_ports.h>
#include <uart/e_uart_char.h>
#include <motor_led/advance_one_timer/e_led.h>
#include <shefpuck/bluetooth.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include <libpic30.h>

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
                {% set var_data[#var_data +1] = var_state_map[ transition.target ] % 256 %}
                {% set var_data[#var_data +1] = math.floor( var_state_map[ transition.target ] / 256 ) %}
            {% end %}
        {% end %}
    {% end %}
    /**************************************************************************/
    /********************************** DATA **********************************/
    /**************************************************************************/
    const unsigned char my_automata_check[ NUM_SUPERVISORS ] = { {{ table.concat(my_automata_check, ',') }} };
    const unsigned char ev_controllable[ NUM_EVENTS ]        = { {% for k_event, event in ipairs(events) %}{{ event.controllable and 1 or 0 }}{% notlast %},{% end %} };
    const int           sup_init_state[ NUM_SUPERVISORS ]    = { {% for k_automaton, automaton in automata:ipairs() %}{{automaton.initial - 1}}{% notlast %},{% end %} };
    int                 sup_current_state[ NUM_SUPERVISORS ] = { {% for k_automaton, automaton in automata:ipairs() %}{{automaton.initial - 1}}{% notlast %},{% end %} };
    //const unsigned char     sup_events[ MY_NUM_AUTOMATA ][ NUM_EVENTS ] = { {% for k_automaton, automaton in ipairs( my_automata_set ) %}{ {% for i = 1, #events %}{{ sup_events[k_automaton+my_first_automata-1][i] and 1 or 0 }}{% notlast %},{% end %} }{% notlast %},{% end %} };
    const unsigned char     sup_events[ NUM_SUPERVISORS ][ NUM_EVENTS ] = { {% for k_automaton, automaton in automata:ipairs() %}{ {% for i = 1, #events %}{{ sup_events[k_automaton][i] and 1 or 0 }}{% notlast %},{% end %} }{% notlast %},{% end %} };

    const int sup_data_pos[ MY_NUM_AUTOMATA ] = { {{ table.concat(var_data_pos, ',') }} };
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

    void set_bit( char *buf, int offset, int bit, char value ){
        char *b = &buf[ offset + bit/8 ];
        b[0] &=  ~( 1 << (bit%8) ); //unset bit
        if( value ){
            b[0] |= ( 1 << (bit%8) ); //set if value != 0
        }
    }

    /////////////////////////////////// MSG ////////////////////////////////////

/* update the msg with the new state according to the local supervisors */
//0                           = start byte
//1                           = msg type
//2 to 7                      = bt-addr
//8 to  2*NUM_SUPERVISORS + 7 = Current state
//2*NUM_SUPERVISORS + 8 to 2*NUM_SUPERVISORS + 9 + ceil(NUM_SUPERVISORS/8) = considered supervisors
///// 1 byte - the event
/* 0 <= global_supervisor < NUM_SUPERVISORS */

void msg_set_type( char *msg, char type ){
    msg[ 1 ] = type;
}
char msg_get_type( char *msg ){
    return msg[ 1 ];
}

//-------------------------------------
void msg_set_local_btaddr( char *msg ){
    int i;
    char *btaddr = bt_get_state()->local_address;
    for(i=0;i<6;i++){
       msg[i+2] = btaddr[i];
    }
}
int msg_is_local_bt_addr( char *msg ){
    if( bt_compare_device_addrs( &msg[2], bt_get_state()->local_address, 6 ) == 0 )
        return 1;
    return 0;
}

//-------------------------------------
void msg_set_current_state( char *msg, int global_supervisor, int state ){
    msg[ 8 + global_supervisor*2 ] = state % 256; //less significative
    msg[ 9 + global_supervisor*2 ] = state / 256; //most significative
}
void msg_init_current_state( char *msg ){
    int i;
    for(i=0;i<NUM_SUPERVISORS;i++){
        msg_set_current_state( msg, i, sup_current_state[ i ] );
    }
}
int msg_get_current_state( char *msg, int global_supervisor ){
    return msg[ 8 + global_supervisor*2 ] + msg[ 9 + global_supervisor*2 ] * 256;
}

//-------------------------------------
void msg_set_considered( char *msg, int global_supervisor ){
    int offset = 8 + 2*NUM_SUPERVISORS;
    set_bit( msg, offset, global_supervisor, 1 );
}
void msg_init_considered( char *msg ){
    int offset      = 8 + 2*NUM_SUPERVISORS;
    int i, numBytes = NUM_SUPERVISORS/8 + ( NUM_SUPERVISORS%8 ? 1 : 0 );
    for( i = 0; i < numBytes; i++ ){
        msg[ offset + i ] = 0;
    }
}
char msg_get_considered( char *msg, int global_supervisor ){
    int offset = 8 + 2*NUM_SUPERVISORS;
    return get_bit( msg, offset, global_supervisor );
}


//-------------------------------------
/* For MSG_STATE */
void msg_set_event( char *msg, unsigned char event ){
    int pos = 8 + 2*NUM_SUPERVISORS + NUM_SUPERVISORS/8 + (NUM_SUPERVISORS%8? 1 : 0);
    msg[ pos ] = (char) event;
}
char msg_get_event( char *msg ){
    int pos = 8 + 2*NUM_SUPERVISORS + NUM_SUPERVISORS/8 + (NUM_SUPERVISORS%8? 1 : 0);
    return msg[ pos ];
}

//-------------------------------------
/* For MSG_EVENT */
void msg_set_controllable_events( char *msg, unsigned char event, char value ){
    int offset = 8 + 2*NUM_SUPERVISORS + NUM_SUPERVISORS/8 + (NUM_SUPERVISORS%8? 1 : 0);
    set_bit( msg, offset, event, value );
}
void msg_init_controllable_events( char *msg ){
    /* init the controllable bit mask as 1. Disable all uncontrollable events (set as 0) */
    unsigned char i;
    for( i=0; i<NUM_EVENTS; i++ ){
        msg_set_controllable_events( msg, i, ev_controllable[i] );
    }
}
char msg_get_controllable_events( char *msg, unsigned char event ){
    int offset = 8 + 2*NUM_SUPERVISORS + NUM_SUPERVISORS/8 + (NUM_SUPERVISORS%8? 1 : 0);
    return get_bit( msg, offset, event );
}

//-------------------------------------
int check_all_considered( char *msg ){
    int i;
    //int offset = 8 + 2*NUM_SUPERVISORS;
    for(i=0;i<NUM_SUPERVISORS;i++){
        if(! msg_get_considered( msg, i ) )
            return 0;
    }
    return 1;
}


/******************************************************************************/
/******************************* Calculations *********************************/
/******************************************************************************/

/* Convert the global supervisor ID in the local supervisor ID*/
unsigned char get_local_supervisor_position( unsigned char global_supervisor_position ){
    return global_supervisor_position - MY_FIRST_AUTOMATA;
}

/* get the position in the sup_data of the transitions on "state" in the local supervisor*/
int get_state_position( unsigned char local_supervisor_positioin, int state ){
    int position;
    int s;
    int en;
    position = sup_data_pos[ local_supervisor_positioin ];
    for(s=0; s<state; s++){
        en       = sup_data[position];
        position += en * 3 + 1;
    }
    return position;
}

void calculate_next_state( char *msg ){
    unsigned char i;
    int position;
    unsigned char num_transitions;
    unsigned char event = msg_get_event( msg );
    //bt_debug( "considering event %i\n", event );

    for(i=0; i<NUM_SUPERVISORS; i++){
        if( (my_automata_check[i] == 1) && (msg_get_considered( msg, i ) == 0) ){ //Do I have this supervisor and it was not calculated yet
            msg_set_considered( msg, i );

            unsigned char local_sup_pos = get_local_supervisor_position( i );
            if( sup_events[ i ][ event ] ){
                int current_state = msg_get_current_state( msg, i );
                position        = get_state_position( local_sup_pos, current_state );
                num_transitions = sup_data[ position ];
                //bt_debug( "cur state %i @ sup %i : pos %i has %i trans.\n", current_state, i, position, num_transitions );
                position++;
                while( num_transitions-- ){
                    if( sup_data[ position ] == event ){
                        //state_vector[ i ] = ( sup_data[ position + 2 ] * 256 ) + ( sup_data[ position + 1 ] );
                        int new_state = (sup_data[ position + 2 ] * 256) + sup_data[ position + 1 ];
                        //bt_debug( "new state %i\n", new_state );
                        msg_set_current_state( msg, i, new_state );
                        break;
                    }
                    position+=3;
                }
            }
        } else {
            //bt_debug( "no sup %i, has %i, cons %i\n", i, my_automata_check[i], msg_get_considered( msg, i ) );
        }
    }
}

void calculate_active_controllable_events( char *msg ){
    unsigned char i,j;

    /* Check disabled events for all supervisors */
    for(i=0; i<NUM_SUPERVISORS; i++){
        if( (my_automata_check[i] == 1) && (msg_get_considered( msg, i ) == 0) ){ //Do I have this supervisor and it was not calculated yet
            msg_set_considered( msg, i );
            
            unsigned char local_sup_pos = get_local_supervisor_position( i );
            int position;
            unsigned char ev_disable[ NUM_EVENTS ], num_transitions;

            /*Disable all*/
            for(j=0; j<NUM_EVENTS;j++){
             ev_disable[ j ] = 1;
            }

            for( j=0; j<NUM_EVENTS; j++ ){
                /*if supervisor don't have this event, it can't disable the event*/
                if( !sup_events[ i ][ j ] ){
                    ev_disable[ j ] = 0;
                }
            }
            
            /*if supervisor have a transition with the event in the current state, it can't disable the event */
            position        = get_state_position( local_sup_pos, msg_get_current_state( msg, i ) );
            num_transitions = sup_data[ position ];
            position++;
            while( num_transitions-- ){
                ev_disable[ sup_data[ position ] ] = 0;
                position += 3;
            }

            /* Disable for current supervisor states */
            for( j=0; j<NUM_EVENTS; j++ ){
                if( ev_disable[ j ] == 1 ){
                    msg_set_controllable_events( msg, j, 0 );
                }
            }
        }
    }
}

/******************************************************************************/
/*************************** Local operations *********************************/
/******************************************************************************/

/*return the number of enabled controllable events or 0 otherwise. A randon selected event is saved in "event"*/
int get_active_controllable_events( char *msg, unsigned char *event ){
    unsigned char i, count_actives = 0, events[ NUM_EVENTS ];
    for(i=0; i<NUM_EVENTS; i++){
        if( msg_get_controllable_events( msg, i ) ){
            count_actives++;
            events[ i ] = 1;
        } else {
            events[ i ] = 0;
        }
    }

    if( count_actives ){
        unsigned char random_pos = rand() % count_actives;
        for(i=0; i<NUM_EVENTS; i++){
            if( !random_pos && events[i] ){
                *event = i;
                return count_actives;
            } else if( events[i] ){
                random_pos--;
            }
        }
    }

    return 0;
}

void update_states( char *msg ){
    int i;
    for(i=0;i<NUM_SUPERVISORS;i++){
        sup_current_state[ i ] = msg_get_current_state( msg, i );
    }
} 

/* IN_read */
unsigned char input_buffer[256];
unsigned char input_buffer_pnt_add = 0;
unsigned char input_buffer_pnt_get = 0;

unsigned char last_events[NUM_EVENTS];
unsigned char input_buffer_get( unsigned char *event ){
    if(input_buffer_pnt_add == input_buffer_pnt_get){
        return 0;
    } else {
        *event = input_buffer[ input_buffer_pnt_get ];
        last_events[*event] = 0;
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


void update_input(){
    unsigned char i;
    for(i=0;i<NUM_EVENTS;i++){
        if( !ev_controllable[i]){
            if( !last_events[i] ){
                if(  input_read( i ) ){
                    input_buffer_add( i );
                    last_events[i] = 1;
                }
            }// else {
            //    last_events[i] = 0;
            //}
        }
    }
}

void execCallback( unsigned char ev ){
    if( ev < NUM_EVENTS && callback[ ev ].callback != NULL )
        callback[ ev ].callback( callback[ ev ].data );
}

/******************************************************************************/
/************************** Communication Functions ***************************/
/******************************************************************************/
#define MSG_START_BYTE 0x17
#define MSG_NONE 0
#define MSG_STATE 1
#define MSG_EVENT 2

////////////////////////////////////////////////////////////////////////////////

#define REQUEST_TIMEOUT 64//around 1.28s
int request_timeout;
//char debug_msg[96];
unsigned char lastRequestedEvent;
void request_new_state( unsigned char event ){
    lastRequestedEvent = event; //Save event for retry;
    int i, sizeMsg = 9 + 2*NUM_SUPERVISORS + NUM_SUPERVISORS/8 + (NUM_SUPERVISORS%8? 1 : 0);
    char msg[64];
    for(i=0;i<sizeMsg;i++)
        msg[i] = 0x30;
    msg[0] = MSG_START_BYTE;
    msg_set_type( msg, MSG_STATE );
    msg_set_local_btaddr( msg );
    msg_init_current_state( msg );
    msg_init_considered( msg );
    msg_set_event( msg, event );

    calculate_next_state( msg );

    bt_cmd_spp_send_data( BT_LOCAL_PORT, sizeMsg, msg );
    request_timeout = REQUEST_TIMEOUT;
    //toHexStr( msg, debug_msg, sizeMsg ); bt_debug( "state: %i : %s\n", sizeMsg, debug_msg );
}

void response_new_state( char *msg ){
    int sizeMsg = 9 + 2*NUM_SUPERVISORS + NUM_SUPERVISORS/8 + (NUM_SUPERVISORS%8? 1 : 0);
    calculate_next_state( msg );
    bt_cmd_spp_send_data( BT_LOCAL_PORT, sizeMsg, msg );
    //toHexStr( msg, debug_msg, sizeMsg ); bt_debug( "res state: %i : %s\n", sizeMsg, debug_msg );
}

void request_enabled_controllable_events(){
    int sizeMsg = 8 + 2*NUM_SUPERVISORS + NUM_SUPERVISORS/8 + (NUM_SUPERVISORS%8? 1 : 0) + NUM_EVENTS/8 + (NUM_EVENTS%8? 1 : 0);
    char msg[64];
    msg[0] = MSG_START_BYTE;
    msg_set_type( msg, MSG_EVENT );
    msg_set_local_btaddr( msg );
    msg_init_current_state( msg );
    msg_init_considered( msg );
    msg_init_controllable_events( msg );

    calculate_active_controllable_events( msg );

    bt_cmd_spp_send_data( BT_LOCAL_PORT, sizeMsg, msg );
    request_timeout = REQUEST_TIMEOUT;
    //toHexStr( msg, debug_msg, sizeMsg ); bt_debug( "events: %i : %s\n", sizeMsg, debug_msg );
}

void response_enabled_controllable_events( char *msg ){
    int sizeMsg = 8 + 2*NUM_SUPERVISORS + NUM_SUPERVISORS/8 + (NUM_SUPERVISORS%8? 1 : 0) + NUM_EVENTS/8 + (NUM_EVENTS%8? 1 : 0);
    calculate_active_controllable_events( msg );
    bt_cmd_spp_send_data( BT_LOCAL_PORT, sizeMsg, msg );
    //toHexStr( msg, debug_msg, sizeMsg ); bt_debug( "res events: %i : %s\n", sizeMsg, debug_msg );
}

/******************************************************************************/
/*********************************** PUBLIC ***********************************/
/******************************************************************************/
#define STATE_IDLE 0
#define STATE_BREAK 1
#define STATE_REQUESTED_STATE 2
#define STATE_REQUESTED_EVENT 3
#define STATE_WAIT_UC 4

void SCT_init(){
    int i;
    for(i=0; i<NUM_EVENTS; i++){
        last_events[i] = 0;
        callback[i].callback    = NULL;
        callback[i].check_input = NULL;
        callback[i].data        = NULL;
    }

    request_timeout = -1;
}

void SCT_init_BT( char enableDebug ){
    //~ if( enableDebug ){
        //~ bt_init( (1 << (BT_LOCAL_PORT-1)) | (1 << (BT_REMOTE_PORT-1)) | (1 << (enableDebug-1)) );
        //~ bt_get_state()->debug = enableDebug;
    //~ } else {
        //~ bt_init( (1 << (BT_LOCAL_PORT-1)) | (1 << (BT_REMOTE_PORT-1)) ); //ports BT_LOCAL_PORT and BT_REMOTE_PORT
    //~ }

    bt_init( 7 ); // ports 1,2,3
    
    bt_cmd_spp_release_link( BT_LOCAL_PORT );
    bt_cmd_spp_release_link( BT_REMOTE_PORT );
    
    bt_cmd_set_fixed_pin( "0000", 4 );
    
    __delay_ms( 100 );
    
    bt_update();
    
    bt_util_read_local_info();
    
    e_set_led(0,1);
}

void SCT_init_BT_addrs( const char **btaddrs, char num_addrs ){
    int i;
    char chain_position, myGroup, groups;
    
    char bt_class[3] = {0,0,0};
    for(i=0;i<num_addrs;i++){
        bt_util_add_device( (const char *) &btaddrs[i], bt_class );
    }

    e_set_led(1,1);
    chain_position = bt_connection_chain( BT_LOCAL_PORT, BT_REMOTE_PORT, -1 );

    e_set_led(2,1);
    bt_auto_get_group( chain_position, BT_LOCAL_PORT, BT_REMOTE_PORT, MY_TYPE, TYPES, &myGroup, &groups  );

    e_set_led(3,1);
    chain_position = bt_auto_connection_chain_split( chain_position, BT_LOCAL_PORT, BT_REMOTE_PORT, myGroup, groups );

    e_set_led(4,1);
    bt_auto_connection_chain_to_cycle( chain_position, BT_LOCAL_PORT, BT_REMOTE_PORT );

    e_set_led(5,1);
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

#define BREAKTIME 8
void SCT_run_step(){//DIST------ //TODO timeout, rentry retransmissions if fail, rentry requests if fail
    //AUTOMATA PLAYER
    static int state     = STATE_IDLE;
    static int breakTime = BREAKTIME;
    //TODO: messageID to discart old messages?
    unsigned char event;

    bt_debug( "Run step:%i\n", state);

    update_input();
    
    if( state == STATE_IDLE || state == STATE_WAIT_UC ){
        if( input_buffer_get( &event ) ){
            request_new_state( event );
            execCallback( event );
            state = STATE_REQUESTED_STATE;
        } else {
            if( state == STATE_IDLE ){
                request_enabled_controllable_events();
                state = STATE_REQUESTED_EVENT;
            }
        }
    }
    else {
        if( request_timeout > 0 ){
            request_timeout--;
            if( request_timeout == 0 ){
                request_timeout = -1;
                if( state == STATE_REQUESTED_STATE ){
                    request_new_state( lastRequestedEvent );
                } else if( state == STATE_REQUESTED_EVENT ){
                    request_enabled_controllable_events();
                }
            }
        }
    }

    if( state == STATE_BREAK ){
        if( breakTime==0 ){
            state = STATE_IDLE;
            breakTime = BREAKTIME;
        } else {
            breakTime--;
        }
    }

    while( 1 ){
        e_set_led( state, 1 );
        char bt_op = bt_update_step();

        //repair connections
        while( bt_repair_connection( BT_LOCAL_PORT, 3 ) == 0 ){
            BODY_LED=1;
        };
        BODY_LED=0;
        
        if( bt_op == BT_CHARFALSE ){
            break;
        }
        
        if( bt_op == BT_OPCODE_SPP_INCOMING_DATA ){
            char *msg = NULL;
            bt_util_get_spp_incoming_data_pointer( &msg );
            //bt_debug( "----data state:%i msg_type:%i\n", state, msg_get_type( msg ) );__delay_ms(50);

            if( msg_get_type( msg ) == MSG_STATE ){
                //bt_debug( "--------MSG_STATE:%i\n", state);__delay_ms(50);
                if( msg_is_local_bt_addr( msg ) ){
                    //bt_debug( "--------local:%i\n", state);__delay_ms(50);
                    if( state == STATE_REQUESTED_STATE ){
                        //bt_debug( "--------OK:%i\n", state);__delay_ms(50);
                        update_states( msg );
                        state           = STATE_BREAK; /////////////////////////////////////
                        request_timeout = -1;
                    }
                } else {
                    //bt_debug( "--------remote:%i\n", state);__delay_ms(50);
                    response_new_state( msg );
                    
                }
            }//END MSG_STATE
            
            if( msg_get_type( msg ) == MSG_EVENT ){
                //bt_debug( "----data:MSG_EVENT:%i\n", state);__delay_ms(50);
                if( msg_is_local_bt_addr( msg )){
                    //bt_debug( "--------local:%i\n", state);__delay_ms(50);
                    if( state == STATE_REQUESTED_EVENT ){
                        //bt_debug( "--------OK:%i\n", state);__delay_ms(50);
                        if( get_active_controllable_events( msg, &event ) ){
                            bt_debug( "controllable ev:%i\n", event);
                            request_new_state( event ); //will re-set request_timeout
                            execCallback( event );
                            state = STATE_REQUESTED_STATE;
                        } else {
                            //bt_debug( "------------NO con ev:%i\n", state);__delay_ms(50);
                            state = STATE_WAIT_UC;
                            request_timeout = -1;
                        }
                    }
                } else {
                    //bt_debug( "--------remote:%i\n", state);__delay_ms(50);
                    response_enabled_controllable_events( msg );
                }
            }//END MSG_EVENT
        } //END incoming data
    }//END while
    
    BODY_LED=!BODY_LED;
}
#endif

        //~ if( bt_get_spp_send_data_status( BT_LOCAL_PORT ) == BT_STATUS_SEND_IDLE_FAIL_WAIT ){
            //~ bt_cmd_spp_send_data_retry( BT_LOCAL_PORT );
        //~ }

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
