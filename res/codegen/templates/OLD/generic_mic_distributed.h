#include <stdlib.h>
#include <e_uart_char.h>
#include <e_bluetooth.h>

#define DIVUP(X,Y) (1+((X)-1)/(Y));

#define STATE_IDLE_ALL 1
#define STATE_IDLE_UC  2
#define STATE_WAIT 3

#define MSG_NONE 0
#define MSG_RESPONSE_EVENT 1
#define MSG_RESPONSE_STATE 2
#define MSG_REQUEST_EVENT 3
#define MSG_REQUEST_STATE 4
#define MSG_INVALID 99

/* Struct's */
#define NUM_EVENTS {{ #events }}
#define NUM_SUPERVISORS {{ automata:len() }}
#define SUP_START {{ sup_start }} //0
#define SUP_END {{ sup_end }}     //until NUM_SUPERVISORS-1
{% for k_event, event in ipairs(events) %}
#define EV_{{event.name}} {{k_event-1}}
{% end %}

unsigned long int RobotID;

void SCT_init();
void SCT_add_callback( unsigned char event, void (*clbk)( void* ), unsigned char (*ci)( void* ), void* data );
void SCT_run_step();
