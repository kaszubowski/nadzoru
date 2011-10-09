#include <{{include}}>
#fuses {{fuses}}
#use delay(clock={{clock}})
{% if use_lcd %}
#include <lcd.c>
{% end %}

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
const unsigned char ev_controllable[{{ #events }}] = { {% for k_event, event in ipairs(events) %}{{ event.controllable and 1 or 0 }}{% notlast %}, {% end %} };
const unsigned char sup_events[{{ automata:len() }}][{{ #events }}] = { {% for k_automaton, automaton in automata:ipairs() %}{ {% for i = 1, #events %}{{ sup_events[k_automaton][i] and 1 or 0 }}{% notlast %},{% end %} }{% notlast %},{% end %} };
const unsigned char sup_number = {{ automata:len() }};
unsigned long int sup_current_state[{{ automata:len() }}] = { {% for k_automaton, automaton in automata:ipairs() %}{{automaton.initial - 1}}{% notlast %},{% end %} };
const unsigned long int sup_data_pos[{{ automata:len() }}] = { {{ table.concat(var_data_pos, ',') }} };
const unsigned char sup_data[ {{ #var_data }} ] = { {{ table.concat( var_data,',' ) }} };

unsigned long int get_state_position( unsigned char supervisor, unsigned long int state ){
    unsigned long int position;
    unsigned long int s;
    unsigned char en;
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
                    sup_current_state[i] = ((unsigned long int) sup_data[position + 1] ) * 255 + ((unsigned long int) sup_data[position + 2]);
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
        if( !ev_controllable[i] ) events[i] = 0;
    }

    /* Check disabled events for all supervisors */
    for(i=0; i<sup_number; i++){
        unsigned long int position;
        unsigned char ev_disable[{{#events}}] = { {% for k_event, event in ipairs(events) %}1{% notlast %},{% end %} };
        unsigned char num_transitions;
        position = get_state_position(i, sup_current_state[i]);
        for( j=0; j<ev_number; j++ ){

            /*if supervisor don't have this event, it can't disable the event*/
            if( !sup_events[i][j] ) ev_disable[j] = 0;
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

unsigned char input_buffer_check_empty(  ){
    return input_buffer_pnt_add == input_buffer_pnt_get;
}

unsigned char input_read( unsigned char ev ){
    char ret = 0;
    switch( ev ){
    {% for k_event, event in ipairs(events) %}
        case EV_{{ event.name }}:
        break;
    {% end %}
    }
    return ret;
}

unsigned char last_events[{{#events}}] = { {% for i = 1,#events %}0{% notlast %},{% end %} };

{% if input_fn == INPUT_TIMER %}
    {% if compiler == PICC %}
#INT_TIMER1
void  TIMER1_isr(void)
{
    unsigned char i;

    disable_interrupts(INT_TIMER1);
    set_timer1( {{timer_interval}} + get_timer1() );
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
    {% elseif compiler == SDCC %}

    {% end %}
{% elseif input_fn  == INPUT_MULTIPLEXED %}

    {% if compiler == PICC %}
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
    {% elseif compiler == SDCC %}

    {% end %}

{% end %}

/* Choice */
/* random */
{% if random_fn == RANDOM_AD or random_fn == RANDOM_PSEUDOAD %}
     unsigned char pic_rand_read_ad(){
         {% if compiler == PICC %}
            setup_ADC_ports({{ad_port}});
            setup_adc(ADC_CLOCK_INTERNAL);
            set_adc_channel(0);
            delay_ms(10);
            return read_adc();
        {% elseif compiler == SDCC %}

        {% end %}
    }
{% end %}

{% if random_fn == RANDOM_PSEUDOFIX %}
unsigned char seed = 0;
unsigned char pic_rand(){
    seed = seed * ( -35 ) + 53;
    return seed;
}
{% elseif random_fn == RANDOM_PSEUDOAD %}
unsigned char seed      = 0;
unsigned char seed_uses = 0;
unsigned char pic_rand(){
    seed = seed * ( -35 ) + 53;
    seed_uses++;
    if (seed_uses == 255){
        seed_uses = 0;
        seed      = pic_rand_read_ad();
    }
    return seed;
}
{% elseif random_fn == RANDOM_AD %}
unsigned char pic_rand(){
   return pic_rand_read_ad();
}
{% else %}
unsigned char pic_rand(){
   return 1;
}
{% end %}

/*choices*/
{% if choice_fn == CHOICE_RANDOM %}
unsigned char get_next_controllable( unsigned char *event ){
    unsigned char events[{{ #events }}] = {
    {% for k_event, event in ipairs(events) %}1{% notlast %}, {% end %}
    };
    int count_actives, random_pos;
    unsigned char i;

    get_active_controllable_events( events );
    count_actives = 0;
    for(i=0; i<{{ #events }}; i++){
        if( events[i] ){
            count_actives++;
        }
    }
    if( count_actives ){
        random_pos = pic_rand() % count_actives;
        for(i=0; i<{{ #events }}; i++){
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
{% end %}

/*Callback*/
void callback( unsigned char ev ){
    switch( ev ){
        {% for k_event, event in ipairs(events) %}
            case EV_{{ event.name }}:
            break;
        {% end %}
    }
}

void main(){
    ///port_b_pullups(TRUE);
{% if input_fn == INPUT_TIMER %}
    enable_interrupts(GLOBAL);
    //Timer
    setup_timer_1(T1_INTERNAL|T1_DIV_BY_1);
    set_timer1({{timer_interval}});
    enable_interrupts(INT_TIMER1);
{% elseif input_fn  == INPUT_MULTIPLEXED %}
    enable_interrupts(GLOBAL);
    //External Interruption
    ext_int_edge(0,{{external_edge}});
    clear_interrupt(INT_EXT);
    enable_interrupts(INT_EXT);
{% end %}
{% if random_fn == RANDOM_PSEUDOAD %}
    seed = pic_rand_read_ad();
{% end %}
{% if use_lcd %}
    lcd_init();
{% end %}
    while(1){
        unsigned char event;
        //clear buffer, executing all no controllable events
        while( input_buffer_get( &event ) ){
            make_transition( event );
            callback( event );
        }
        if( get_next_controllable( &event ) ){
            if( !input_buffer_check_empty() ) break;
            make_transition( event );
            callback( event );
        }
    }
}
