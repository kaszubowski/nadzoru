{%if compiler.type == 'picc' %}
#include <{{ model }}.h>
#fuses NOMCLR,EC_IO,H4,NOWDT,NOPROTECT,NOLVP,NODEBUG
#use delay(clock=20000000)
#include <stdio.h>
#include <stdlib.h>
{% if compiler.lcd %}
#include <lcd.c>
{%end %}
{%elseif compiler.type == 'sdcc' %}
...
{%end %}

void main(){
    port_b_pullups(TRUE);
    %s
    %s
    main_loop();
}
