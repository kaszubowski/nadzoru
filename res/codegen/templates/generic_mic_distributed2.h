#include <stdlib.h>

#define MSG_BUFFER_SIZE 64

/* Struct's */
#define NUM_EVENTS {{ #events }}
#define NUM_SUPERVISORS {{ automata:len() }}

#define TYPES {{ types }}
#define MY_TYPE {{ my_type-1 }}
#define MY_FIRST_AUTOMATA {{ my_first_automata-1 }}
#define MY_NUM_AUTOMATA {{ #my_automata_set }}

{% for k_event, event in ipairs(events) %}
#define EV_{{event.name}} {{k_event-1}}
{% end %}

void SCT_init();
void SCT_reset();
void SCT_add_callback( unsigned char event, void (*clbk)( void* ), unsigned char (*ci)( void* ), void* data );
void SCT_run_step();
