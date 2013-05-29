{% if compiler == CCS %}
    {% for k_inc, inc in ipairs( type(include_ccs) == 'table' and include_ccs or { include_ccs } )%}
        #include <{{inc}}>
    {% end %}
    #fuses {{fuses}}
    #use delay(clock={{clock}})
    #include <stdio.h>
    #include <stdlib.h>
{% elseif compiler == SDCC %}
    #define _XTAL_FREQ 12000000
    {% for k_inc, inc in ipairs( type(include_sdcc) == 'table' and include_sdcc or { include_sdcc } )%}
        #include <{{inc}}>
    {% end %}
    #include <stdio.h>
    #include <stdarg.h>
    #include "libs/delay.c"
    {% if compiler == SDCC and use_lcd %}
        #include "libs/lcd.c"
    {% end %}
    {% if compiler == SDCC and ( output_fn == OUTPUT_RS232 or output_fn == OUTPUT_NORMAL_RS232 or input_fn == INPUT_RS232 ) %}
        #include "libs/rs232.c"
    {% end %}

    __code char __at __CONFIG1H _conf1 = {{sdcc_1H}};
    __code char __at __CONFIG2L _conf2 = {{sdcc_2L}};
    __code char __at __CONFIG2H _conf3 = {{sdcc_2H}};
    __code char __at 0x300004   _conf4 = 0x00;
    __code char __at __CONFIG3H _conf5 = {{sdcc_3H}};
    __code char __at __CONFIG4L _conf6 = {{sdcc_4L}};
    __code char __at 0x300007   _conf7 = 0x00;
    __code char __at __CONFIG5L _conf8 = {{sdcc_5L}};
    __code char __at __CONFIG5H _conf9 = {{sdcc_5H}};
    __code char __at __CONFIG6L _confA = {{sdcc_6L}};
    __code char __at __CONFIG6H _confB = {{sdcc_6H}};
    __code char __at __CONFIG7L _confC = {{sdcc_7L}};
    __code char __at __CONFIG7H _confD = {{sdcc_7H}};
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
const {{char}} ev_number = {{ #events }};
const {{char}} ev_controllable[{{ #events }}] = { {% for k_event, event in ipairs(events) %}{{ event.controllable and 1 or 0 }}{% notlast %},{% end %} };
const {{char}} sup_events[{{ automata:len() }}][{{ #events }}] = { {% for k_automaton, automaton in automata:ipairs() %}{ {% for i = 1, #events %}{{ sup_events[k_automaton][i] and 1 or 0 }}{% notlast %},{% end %} }{% notlast %},{% end %} };
const {{char}} sup_number = {{ automata:len() }};
{{int}} sup_current_state[{{ automata:len() }}] = { {% for k_automaton, automaton in automata:ipairs() %}{{automaton.initial - 1}}{{ns}}{% notlast %},{% end %} };
const {{int}} sup_data_pos[{{ automata:len() }}] = { {{ table.concat(var_data_pos, ns .. ',') }}{{ns}} };
const {{char}} sup_data[ {{ #var_data }}{{ns}} ] = { {{ table.concat( var_data,',' ) }} };

{{int}} get_state_position( {{char}} supervisor, {{int}} state ){
    {{int}} position;
    {{int}} s;
    {{char}} en;
    position = sup_data_pos[ supervisor ];
    for(s=0; s<state; s++){
        en       = sup_data[position];
        {% if compiler == CCS %}
        position += en * 3{{ns}} + 1{{ns}};
        {% else %}
        position += ( {{int_cast}} en) * ( {{int_cast}} 3{{ns}}) + ( {{int_cast}} 1{{ns}});
        {% end %}
    }
    return position;
}

void make_transition( {{char}} event ){
    {{char}} i;
    {{int}} position;
    {{char}} num_transitions;
    {% if compiler == SDCC and use_lcd %}
        char lcdbuf[17];
    {% end %}

    for(i=0; i<sup_number; i++){
        if(sup_events[i][event]){
            position        = get_state_position(i, sup_current_state[i]);
            num_transitions = sup_data[position];
            position++;
            while(num_transitions--){
                if(sup_data[position] == event){
                    sup_current_state[i] = ( {{int_cast}} sup_data[position + 1] ) * 256{{ns}} + ( {{int_cast}} sup_data[position + 2{{ns}}]);
                    break;
                }
                position+=3{{ns}};
            }
        }
    }
    
    {% if compiler == SDCC and use_lcd %}
        lcd_home();lcd_puts( "                " );
        sprintf( lcdbuf, "Event %i", event+1 );
        lcd_home();lcd_puts( lcdbuf );
    {% end %}
}
{% endwith %}

void get_active_controllable_events( {{char}} *events ){
    {{char}} i,j;

    /* Disable all non controllable events */
    for( i=0; i<ev_number; i++ ){
        if( !ev_controllable[i] ){
            events[i] = 0;
        }
    }

    /* Check disabled events for all supervisors */
    for(i=0; i<sup_number; i++){
        {{int}} position;
        {{char}} ev_disable[23], k;
        {{char}} num_transitions;
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
            position += ( {{int_cast}} 3{{ns}} );
        }

        /* Disable for current supervisor states */
        for( j=0; j<ev_number; j++ ){
            if( ev_disable[j] == 1 ){
                events[ j ] = 0;
            }
        }
    }
}

/* Choice */
/* random */
{% if random_fn == RANDOM_AD or random_fn == RANDOM_PSEUDOAD %}
     {{char}} pic_rand_read_ad(){
         {% if compiler == CCS %}
            setup_ADC_ports(AN{{ad_port}});
            setup_adc(ADC_CLOCK_INTERNAL);
            set_adc_channel(0);
            delay_ms(10);
            return read_adc();
        {% elseif compiler == SDCC %}
            //ADCON1: vref = vdd; -vref = vss; AN0..12 are Analog
            ADCON1bits.VCFG0 = 0;
            ADCON1bits.VCFG1 = 0;

            //ADCON2: ADC Result Right Justified; Acquisition Time = 2TAD; Conversion Clock = 32 Tosc
            ADCON2=0b10001010;

            //ADCON0 (channel)
            ADCON0=({{ad_port}}<<2);
            ADCON0bits.ADON=1;
            ADCON0bits.GO=1;
            while(ADCON0bits.GO);
            ADCON0bits.ADON=0;
            return ADRESL;
        {% end %}
    }
{% end %}

{% if random_fn == RANDOM_PSEUDOFIX %}
{{char}} seed = 0;
{{char}} pic_rand(){
    seed = seed * ( -35 ) + 53;
    return seed;
}
{% elseif random_fn == RANDOM_PSEUDOAD %}
{{char}} seed      = 0;
{{char}} seed_uses = 0;
{{char}} pic_rand(){
    seed = seed * ( -35 ) + 53;
    seed_uses++;
    if (seed_uses == 255){
        seed_uses = 0;
        seed      = pic_rand_read_ad();
    }
    return seed;
}
{% elseif random_fn == RANDOM_AD %}
{{char}} pic_rand(){
   return pic_rand_read_ad();
}
{% else %}
{{char}} pic_rand(){
   return 1;
}
{% end %}

/* IN_read */
{{char}} input_buffer[256];
{{char}} input_buffer_pnt_add = 0;
{{char}} input_buffer_pnt_get = 0;

{{char}} input_buffer_get( {{char}} *event ){
    if(input_buffer_pnt_add == input_buffer_pnt_get){
        return 0;
    } else {
        *event = input_buffer[ input_buffer_pnt_get ];
        input_buffer_pnt_get++;
        return 1;
    }
}

void input_buffer_add( {{char}} event ){
    input_buffer[ input_buffer_pnt_add ] = event;
    input_buffer_pnt_add++;
}

{{char}} input_buffer_check_empty(  ){
    return input_buffer_pnt_add == input_buffer_pnt_get;
}

{% if (compiler == SDCC and input_fn ~= INPUT_RS232) or compiler == CCS %}
    {% for k_event, event in ipairs(events) %}
        {% if not event.controllable %}
            {{char}} input_read_{{ event.name }}(){
                {{ event_code[ event.name ] and event_code[ event.name ].input or 'return 0;'  }}
            }
        {% end %}
    {% end %}


    {% if compiler == CCS %}
        {{char}} input_read( {{char}} ev ){
            {{char}} result = 0;
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
    {% elseif compiler == SDCC %}
        {{char}} input_read( {{char}} ev ){
            {{char}} result       = 0;
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
    {% end %}
{% end %}

{{char}} last_events[{{#events}}] = { {% for i = 1,#events %}0{% notlast %},{% end %} };

/*choices*/
{% if choice_fn == CHOICE_RANDOM %}
{{char}} get_next_controllable( {{char}} *event ){
    {{char}} events[{{ #events }}] = {
    {% for k_event, event in ipairs(events) %}1{% notlast %}, {% end %}
    };
    int count_actives, random_pos;
    {{char}} i;

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
    }
    return 0;
}
{% end %}

{% if (compiler == SDCC and output_fn ~= OUTPUT_RS232) or compiler == CCS %}
    /*Callback*/
    {% for k_event, event in ipairs(events) %}
        void callback_{{ event.name }}(){
            {{ event_code[ event.name ] and event_code[ event.name ].output or ''  }}
        }
    {% end %}


    void callback( {{char}} ev ){
        switch( ev ){
            {% for k_event, event in ipairs(events) %}
            case EV_{{ event.name }}:
                callback_{{ event.name }}();
                break;
            {% end %}
        }
    }
{% end %}

void main(){
    
    {% if compiler == SDCC %}
        //Config, will be a new tab in DFA-generator>'code area' with user initial code
        TRISA=0b11111111;
        TRISB=0b00000001;//B0 -> input(1), B[1..7] output(0)
        TRISC=0b00000001;//PORTC output(0)
        TRISD=0x00;//D[0,1,2] LCD, D3 LED, D[4,5,6,7] LCD
        TRISE=0b00001111;
        ADCON1 = 0b00001110; //AN[1..12] are Digital - AN0 Analogic

        PORTBbits.RB7 = 1;
        PORTDbits.RD3 = 1;
    {% end %}
    
    {% if compiler == SDCC and ( output_fn == OUTPUT_RS232 or output_fn == OUTPUT_NORMAL_RS232 or input_fn == INPUT_RS232 ) %}
        RS232Start(); 
    {% end %}

    {% if compiler == SDCC and use_lcd  %}
        lcd_init( FOURBIT_MODE );
    {% end %}


    //Interrupt (Timer/External) Config
    {% if input_fn == INPUT_TIMER %}
        {% if compiler == CCS %}
            enable_interrupts(GLOBAL);
            //Timer
            setup_timer_1(T1_INTERNAL|T1_DIV_BY_1);
            set_timer1({{timer_interval  or 65416}});
            enable_interrupts(INT_TIMER1);
        {% elseif compiler == SDCC %}
            T0CONbits.T0PS0  = 0; // Set up prescaler to (210) 011 = 1:16, 110 = 1:128; 111 = 1:256; 101 = 1:64
            T0CONbits.T0PS1  = 1; // "
            T0CONbits.T0PS2  = 1; // "
            T0CONbits.PSA    = 0; // Clear to assign prescaler to Timer 0.
            T0CONbits.T0SE   = 0; // Increment on low-to-high transition on T0CKI pin
            T0CONbits.T0CS   = 0; // Internal instruction cycle clock (CLKO)
            T0CONbits.T08BIT = 0; //Timer0 is configured as a 16-bit timer/counter
            T0CONbits.TMR0ON = 1; // Enables Timer0

            //~ INTCON = 0x00; // Clear interrupt flag bits.
            INTCONbits.GIE = 1;    // Enable all interrupts. (bit 7)
            INTCONbits.PEIE = 1;   // Enable peripheral interrupts. (bit 6)
            INTCONbits.T0IE = 1;   // Enables the TMR0 overflow interrupt (bit 5)
        {% end %}
    {% elseif input_fn  == INPUT_MULTIPLEXED %}
        {% if compiler == CCS %}
            enable_interrupts(GLOBAL);
            //External Interruption
            ext_int_edge(0,{{external_edge}});
            clear_interrupt(INT_EXT);
            enable_interrupts(INT_EXT);
        {% elseif compiler == SDCC %}
            //~ INTCON=0x00;       // Clear interrupt register completely
            INTCONbits.GIE=1;      // Globally enable interrupts (bit 7)
            INTCONbits.PEIE = 1;   // Enable peripheral interrupts. (bit 6)
            INTCONbits.INT0IE=1;   // Set ONLY PORTB/B0 interrupt (bit 4)
            INTCONbits.RBIE=0;     // Disables the RB port change interrupt (bit 3)
            INTCON2bits.INTEDG0={{external_edge == 'H_TO_L' and 0 or 1}}; // Interrupt on falling edge(1 is rising).
        {% end %}
    {% end %}

    {% if random_fn == RANDOM_PSEUDOAD %}
        seed = pic_rand_read_ad();
    {% end %}

    //Main Loop
    while(1){
        {{char}} event;
        //clear buffer, executing all no controllable events
        while( input_buffer_get( &event ) ){
            make_transition( event );
            {% if (compiler == SDCC and output_fn ~= OUTPUT_RS232) or  compiler == CCS %}
                callback( event );
            {% end %}
        }
        if( get_next_controllable( &event ) ){
            if( !input_buffer_check_empty() ) continue;
            make_transition( event );
            {% if (compiler == SDCC and output_fn ~= OUTPUT_RS232) or  compiler == CCS %}
                callback( event );
            {% end %}
            {% if compiler == SDCC and ( output_fn == OUTPUT_RS232 or output_fn == OUTPUT_NORMAL_RS232 ) %}
                //~ printf("%c", event+1 ); //Send by RS 232 (IN PIC we use 0 to 254, IN PC 1 to 255)
                //~ if you want to send a char be carefull because you need disable all special char's in PC
                //~ like:  ~( ICANON | ECHO | ISIG |IEXTEN ); --There is more but I don't know.
                printf("%i\n", event+1);
            {% end %}
        }
        delay_ms(100);
    }
}

{% if compiler == CCS and input_fn == INPUT_TIMER  %}
    #INT_TIMER1
    void  TIMER1_isr(void)
    {
        {{char}} i;

        disable_interrupts(INT_TIMER1);
        set_timer1( {{timer_interval or 65416}} + get_timer1() );
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
{% elseif compiler == CCS and input_fn == INPUT_MULTIPLEXED %}
    #INT_EXT
    void  int_externo(void)
    {
       {{char}} i;
       disable_interrupts(INT_EXT);
       delay_ms(500);
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


{% elseif compiler == SDCC and ( input_fn == INPUT_TIMER or input_fn == INPUT_MULTIPLEXED or input_fn == INPUT_RS232 ) %}
    void HighLevelIntr(void) __interrupt 1
    {
        {% if input_fn == INPUT_TIMER %}
            if( INTCONbits.T0IF ){ //Timer Interrupt
                {{char}} i;
                INTCONbits.T0IF = 0;   // Clear the Timer 0 interrupt. (bit 1)

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
        {% elseif input_fn == INPUT_MULTIPLEXED %}
            if( INTCONbits.INT0IF ){ //External(0) Interrupt
                {{char}} breg, i;
                //~ INTCONbits.GIE=0;
                breg=PORTB;
                PORTB=breg;
                INTCONbits.INT0IF=0; //Clear INT0 (bit 1)

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
        {% elseif input_fn == INPUT_RS232 %}
            if( PIR1bits.RCIF ){ //USART interrupt
                {{ char }} eventID;
                RS232HandlerInterrupt();
                while( !RS232IsEmpty()){
                    eventID = RS232GetChar()-1; //(IN PIC we use 0 to 254, IN PC 1 to 255)
                    if( !ev_controllable[ eventID ]){
                        input_buffer_add( eventID );
                    }
                }
            }
        {% end %}
    } //end HighLevelIntr    
{% end %}
