#include <stdlib.h>

#define BT_LOCAL_PORT 2
#define BT_REMOTE_PORT 2

/* Struct's */
#define NUM_EVENTS {{ #events }}
#define NUM_SUPERVISORS {{ automata:len() }}

#define TYPES {{ types }}
#define MY_NUM_AUTOMATA {{ #my_automata_set }}
#define MY_TYPE {{ my_type-1 }}
#define MY_FIRST_AUTOMATA {{ my_first_automata-1 }}

{% for k_event, event in ipairs(events) %}
#define EV_{{event.name}} {{k_event-1}}
{% end %}

void SCT_init();
void SCT_init_BT( char enableDebug );
void SCT_init_BT_addrs( const char **btaddrs, char num_addrs );
void SCT_reset();
void SCT_add_callback( unsigned char event, void (*clbk)( void* ), unsigned char (*ci)( void* ), void* data );
void SCT_run_step();
