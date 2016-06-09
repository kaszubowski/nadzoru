#include <stdlib.h>

/* Struct's */
#define NUM_EVENTS {{ #events }}
#define NUM_SUPERVISORS {{ automata:len() }}
{% for k_event, event in ipairs(events) %}
#define EV_{{event.name}} {{k_event-1}}
{% end %}

void SCT_init();
void SCT_reset();
void SCT_add_callback( unsigned char event, void (*clbk)( void* ), unsigned char (*ci)( void* ), void* data );
void SCT_run_step();
