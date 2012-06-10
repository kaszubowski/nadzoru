#include <delay.h>

void delay_cycles(unsigned long int dc){
    while(dc > 1000000){
        delay1mtcy(1);
        dc -= 1000000;
    }
    while(dc > 100000){
        delay100ktcy(1);
        dc -= 100000;
    }
    while(dc > 10000){
        delay10ktcy(1);
        dc -= 10000;
    }
    while(dc > 1000){
        delay1ktcy(1);
        dc -= 1000;
    }
    while(dc > 100){
        delay100tcy(1);
        dc -= 100;
    }
    while(dc > 10){
        delay10tcy(1);
        dc -= 10;
    }
}

/// each cycle is 4Hz ?

void delay_us(unsigned int us){
    unsigned long int steps = us * (_XTAL_FREQ/4000000);
    delay_cycles( steps );
}

void delay_ms(unsigned int ms){
    unsigned long int steps = ms * (_XTAL_FREQ/4000);
    delay_cycles( steps );
}

void delay_s(unsigned int s){
    unsigned int i;
    for(i=0;i<s;i++){
        delay_ms(1000);
    }
}
