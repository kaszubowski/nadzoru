// developed by mike rubenstein at harvard university
// licensed under creative commons attribution-NonCommercial-ShareAlike 3.0 Unported (CC BY-NC-SA 3.0)
// more info at http://creativecommons.org/licenses/by-nc-sa/3.0/

// adapted by K-Team SA, 2012

// Kilobot functions header

// version 1.0 15.03.2012

#ifndef __libKilobot__
#define __libKilobot__

/* INCLUDES */

#include <avr/eeprom.h>
#include <avr/io.h>
#include <avr/wdt.h>
#include <avr/interrupt.h>
#include <stdlib.h>
#include <util/delay.h>
#include <avr/sleep.h>
#include <math.h>



/* EXPORTED VARIABLES */

extern volatile int message_rx[];

extern volatile uint8_t	cw_in_place;
extern volatile uint8_t	ccw_in_place;
extern volatile uint8_t	cw_in_straight;
extern volatile uint8_t	ccw_in_straight;
extern volatile uint8_t enable_tx;



/* EXPORTED FUNCTIONS */


extern void kprinti(int);

extern void kprints(char *);

extern void set_color(int8_t ,int8_t ,int8_t );

extern void enter_sleep(void);


extern int measure_voltage(void);

extern int measure_charge_status(void);


extern void set_motor(char cw, char ccw);

extern void get_message(void);

extern void message_out(char ,char ,char );

extern int get_ambient_light(void);


extern void init_robot(void);

extern void main_program_loop(void (*user_prgm) (void));






#endif // __libKilobot__
