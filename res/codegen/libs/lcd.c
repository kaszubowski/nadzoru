/*
 *  LCD interface example
 *  Uses routines from delay.c
 *  This code will interface to a standard LCD controller
 *  like the Hitachi HD44780. It uses it in 4 or 8 bit mode
 */

#include <pic18fregs.h>
#include <delay.h>
#include "lcd.h"


char fourbit;     // four or eight bit mode?

void lcd_fourbit_cmd(unsigned char c){
    LCD_DATA = ( c & 0xF0 ) | ( LCD_DATA & 0x0F );
    LCD_STROBE();
}

/* send a command to the LCD */
void
lcd_cmd(unsigned char c)
{
    LCD_WAIT; // may check LCD busy flag, or just delay a little, depending on lcd.h

    if (fourbit)
    {
        lcd_fourbit_cmd( c );
        lcd_fourbit_cmd( c << 4 );
    }
    else
    {
        LCD_DATA = c;
        LCD_STROBE();
    }
}

/* send data to the LCD */
void
lcd_data(unsigned char c)
{
    LCD_WAIT; // may check LCD busy flag, or just delay a little, depending on lcd.h

    LCD_DATA = 0;
    if (fourbit)
    {
        LCD_DATA = ( c & 0xF0 ) | ( LCD_DATA & 0x0F );
        LCD_RS   = 1;
        LCD_STROBE();
        LCD_DATA = ( ( c << 4 ) & 0xF0 ) | ( LCD_DATA & 0x0F );
        LCD_RS   = 1;
        LCD_STROBE();
    }
    else
    {
        LCD_DATA = c;
        LCD_RS   = 1;
        LCD_STROBE();
    }
    LCD_RS = 0;
}

/* write a string of chars to the LCD */
void
lcd_puts(const char * s)
{
    while(*s)
        lcd_data(*s++);
}

/* initialize the LCD */
void
lcd_init(unsigned char mode)
{
    char init_value;

    fourbit     = 0;
    if (mode == FOURBIT_MODE){
        fourbit = 1;
        init_value = 0x30;
    }else{
        init_value = 0x3F;
    }
    LCD_RS = 0;
    LCD_EN = 0;
    LCD_RW = 0;
    LCD_RS_TRIS    = OUTPUT_PIN;
    LCD_EN_TRIS    = OUTPUT_PIN;
    LCD_RW_TRIS    = OUTPUT_PIN;
    delay_ms(15);
    if(fourbit){
        LCD_DATA_TRIS  = OUTPUT_PIN;
        lcd_fourbit_cmd( init_value );
    } else {
        LCD_DATA_TRIS  = OUTPUT_PIN;
        LCD_DATA     = init_value;
        LCD_STROBE();
    }
    delay_ms(5);
    if(!fourbit){
        lcd_fourbit_cmd( init_value );
    } else {
        LCD_DATA     = init_value;
        LCD_STROBE();
    }
    delay_us(200);
    if(!fourbit){
        lcd_fourbit_cmd( init_value );
    } else {
        LCD_DATA     = init_value;
        LCD_STROBE();
    }

    if (fourbit){
        LCD_WAIT; //may check LCD busy flag, or just delay a little, depending on lcd.h
        lcd_fourbit_cmd( 0x20 );

        lcd_cmd(0x28); // Function Set
    }else{
        lcd_cmd(0x38);
    }
    lcd_cmd(0xF); //Display On, Cursor On, Cursor Blink
    lcd_cmd(0x1); //Display Clear
    lcd_cmd(0x6); //Entry Mode
    lcd_cmd(0x80); //Initialize DDRAM address to zero
}



