/* RS232 */
char RS232Buffer[256];
unsigned char pRS232RXIN;
unsigned char pRS232RXOUT;

void RS232Start(){
    pRS232RXIN  = 0;
    pRS232RXOUT = 0;
    
    // Serial Interrupts
    INTCONbits.GIE  = 1;
    INTCONbits.PEIE = 1; 
    PIE1bits.RCIE = 1;
    IPR1bits.RCIP = 0;
    PIE1bits.TXIE = 0;
    IPR1bits.TXIP = 0;
    
    TRISCbits.TRISC7 = 1; //RX (1:input)
    TRISCbits.TRISC6 = 1; //TX (0:output)

    //~ TXSTAbits.CSRC  = 0; //Don't  care
    TXSTAbits.TX9   = 0;
    TXSTAbits.TXEN  = 1;
    TXSTAbits.SYNC  = 0;
    TXSTAbits.SENDB = 0;
    TXSTAbits.BRGH  = 1;
    //~ TXSTAbits.TRMT  //Read Only
    TXSTAbits.TX9D  = 0;
    
    RCSTAbits.SPEN = 1;
    RCSTAbits.RX9  = 0;
    //~ RCSTAbits.SREN  = 0; //Don't care
    RCSTAbits.CREN  = 1;
    //~ RCSTAbits.ADDEN  = 0; //Don't care
    //~ RCSTAbits.FERR //Read Only
    //~ RCSTAbits.OERR //Read Only
    //~ RCSTAbits.RX9D //Read Only
    
    
    //~ BAUDCONbits.ABDOVF //Read
    //~ BAUDCONbits.RCIDL  //Read Only
    BAUDCONbits.RXDTP = 0; 
    BAUDCONbits.TXCKP = 0; 
    BAUDCONbits.BRG16 = 0;
    //~ Not implemented
    BAUDCONbits.WUE   = 0;
    BAUDCONbits.ABDEN = 0;
    
    SPBRG = 129;
      
    stdout = STREAM_USART;   
}

// ....OUT.......IN.......
unsigned char RS232BufferLen(){
    if( pRS232RXIN < pRS232RXOUT ){
        return (256 - pRS232RXOUT) + pRS232RXIN;
    }
    
    return pRS232RXIN - pRS232RXOUT; //0 no data
}

unsigned char RS232IsEmpty(){
    return pRS232RXIN == pRS232RXOUT;
}

unsigned char RS232GetChar(){
    unsigned char c = RS232Buffer[ pRS232RXOUT ];
    if ( RS232BufferLen() ){
        pRS232RXOUT++;
    }
    return c;
}

unsigned char RS232GetBuffer( unsigned char *result, unsigned char len ){
    unsigned char pos = 0;
    if( (pRS232RXIN == pRS232RXOUT) || !len ){
        return 0;
    }
    while( pRS232RXIN != pRS232RXOUT && len ){
        result[ pos ] = RS232Buffer[ pRS232RXOUT ];
        len--;
        pRS232RXOUT++;
        pos++;
    }
    result[ pos ] = '\0'; //buffer must have space to \0
    
    return 1;
}

void RS232PutChar( unsigned char c){
    RS232Buffer[ pRS232RXIN ] = c;
    pRS232RXIN++;
}

void RS232HandlerInterrupt(){
    while(PIR1bits.RCIF){
        RS232PutChar( RCREG );

        //Clear error
        if( RCSTAbits.OERR ){
            RCSTAbits.CREN = 0;
            RCSTAbits.CREN = 1;
        }
    }
}
