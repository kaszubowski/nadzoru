// developed by mike rubenstein at harvard university
// licensed under creative commons attribution-NonCommercial-ShareAlike 3.0 Unported (CC BY-NC-SA 3.0)
// more info at http://creativecommons.org/licenses/by-nc-sa/3.0/

// adapted by K-Team SA, 2012

// Kilobot functions library

// version 1.0 15.03.2012

#include "libKilobot.h"

/* DEFINES */

//some timing constants
#define time_a 269
#define time_b 269
#define timeb_half time_b/2

//used locations in eeprom for calibration data
#define ee_OSCCAL 0x001  // rc calibration value in eeprom, to be loaded to OSCCAL at startup
#define ee_CW_IN_PLACE 0x004  //motor calibration data in epromm
#define ee_CCW_IN_PLACE 0x008  //motor calibration data in epromm
#define ee_CW_IN_STRAIGHT 0x00B  //motor calibration data in epromm
#define ee_CCW_IN_STRAIGHT 0x013  ///motor calibration data in epromm
#define ee_SENSOR_LOW 0x20  //low gain sensor calibration data in epromm
#define ee_SENSOR_HIGH 0x50  //high-gain calibration data in epromm
#define ee_TX_MASK 0x90  //Role asignment


/*  VARIABLES */

//variables used for communication
volatile int incoming_byte=0;
volatile int adc_high_gain;
volatile int adc_low_gain;
volatile uint8_t incoming_byte_value;
volatile int message_incoming=0;
volatile uint8_t incoming_message[5];
volatile int leading_bit=1;
volatile int txvalue_buffer[7][4];
volatile int txvalue_buffer_pointer;
volatile int message_rx[7];
volatile uint8_t message_tx0=200;
volatile uint8_t message_tx1=200;
volatile uint8_t message_tx2=200;

//clock variables used with timer0
volatile int clock_1=0;
volatile uint16_t clock_2=0;
volatile int clock_3=0;
volatile int time_since_last =0;
volatile int tx_clock=0;
volatile int clock=0;

//calibration data stored here from eeprom for quick usage during program
volatile uint8_t	cw_in_place;
volatile uint8_t	ccw_in_place;
volatile uint8_t	cw_in_straight;
volatile uint8_t	ccw_in_straight;
volatile int sensor_cal_data_low[14];
volatile int sensor_cal_data_high[14];
static uint8_t tx_mask=0;

//variables used with the over head controller
volatile int special_mode_message=3;
volatile int special_mode=1;
volatile int special_message_buffer[3];//
volatile int special_message_pointer=0;
volatile int wakeup=0;
volatile uint8_t enable_tx=1;
volatile uint8_t run_program=0;

//variable used for generating a good random value
volatile int randseed=0;

/* FUNCTIONS */

//for reset, makes sure wdt doesnt continously reset
void wdt_init(void) __attribute__((naked)) __attribute__((section(".init3")));

void wdt_init(void)
{
    MCUSR = 0;
    wdt_disable();

    return;
}

//function for updating the next message to be transmitted (note: does not actually transmit message)
// the last char must be even, because its lsb is used internally
void message_out(char tx0,char tx1,char tx2)
{ 
	message_tx0=tx0;
	message_tx1=tx1;
	message_tx2=tx2;
	message_tx2 &= 0xfe ;
}		

//function for checking the received message buffer
void get_message(void)											\
{																\
	int count_pointer=0;										\
	int count_pointer_a=txvalue_buffer_pointer;					\
	message_rx[5]=0;											\
	while(count_pointer<4)										\
	{															\
		if(count_pointer_a==0)									\
			count_pointer_a=3;									\
		else													\
			count_pointer_a--;									\
																\
		if(txvalue_buffer[5][count_pointer_a]==1)				\
		{														\
			cli();												\
			message_rx[0]=txvalue_buffer[0][count_pointer_a];	\
			message_rx[1]=txvalue_buffer[1][count_pointer_a];	\
			message_rx[2]=txvalue_buffer[2][count_pointer_a];	\
			message_rx[3]=txvalue_buffer[3][count_pointer_a];	\
			message_rx[4]=txvalue_buffer[4][count_pointer_a];	\
			message_rx[6]=txvalue_buffer[6][count_pointer_a];	\
			sei();												\
			message_rx[5]=1;									\
			txvalue_buffer[5][count_pointer_a]=0;				\
			break;												\
																\
																\
																\
		}														\
																\
		count_pointer++;										\
																\
	}															\
																\
}	



//this function does the actual transmission of IR messages
int send_message(int a,int b,int c)
{
	sei();	
	//any messages already being received
	if(message_incoming==1)
	{
	
		return(2);

	}


	uint16_t data_out[4];
	uint8_t data_to_send[4]={a,b,c,255};

	

	//prepare data checksum to send
	data_to_send[3]=data_to_send[2]+data_to_send[1]+data_to_send[0]+128;

	//prepare data to send
	for(int i=0;i<4;i++)
	{
		data_out[i]=(data_to_send[i] & (1<<0))*128 + 
				(data_to_send[i] & (1<<1))*32 + 
				(data_to_send[i] & (1<<2))*8 + 
				(data_to_send[i] & (1<<3))*2+ 
				(data_to_send[i] & (1<<4))/2+ 
				(data_to_send[i] & (1<<5))/8 + 
				(data_to_send[i] & (1<<6))/32 + 
				(data_to_send[i] & (1<<7))/128;

		data_out[i]=data_out[i]<<1;
		data_out[i]++;
	}

	uint8_t collision_detected=0;
	cli();//start critical

	if(message_incoming==0)//no incoming message detected
	{
		//send start pulse
		DDRB |= tx_mask;
		PORTB |= tx_mask;
		asm volatile("nop\n\t");
		asm volatile("nop\n\t");
		PORTB&= ~tx_mask;

		//wait for own signal to die down
		for(int k=0;k<53;k++)
			asm volatile("nop\n\t");


		//check for collision
		for(int k=0;k<193;k++)
		{
			if((ACSR & (1<<ACO))>0)
			{
	
				collision_detected=1;
				//ensure led is off
				PORTB &= ~tx_mask;
				DDRB &= ~tx_mask;
				sei();//end critical
				return(3);

			}
			if((ACSR & (1<<ACO))>0)
			{
	
				collision_detected=1;
				//ensure led is off
				PORTB &= ~tx_mask;
				DDRB &= ~tx_mask;
				sei();//end critical
				return(4);

			}
				
	
		}	

		if(collision_detected==0)
			for(int byte_sending=0;byte_sending<4;byte_sending++)
			{
				int i=8;
				while(i>=0)
				{

					if(data_out[byte_sending] & 1)
					{
					
						PORTB |= tx_mask;
						asm volatile("nop\n\t");
						asm volatile("nop\n\t");
		
					}
					else
					{
						PORTB &= ~tx_mask;
						asm volatile("nop\n\t");
						asm volatile("nop\n\t");
	
					}

						PORTB &= ~tx_mask;
						for(int k=0;k<35;k++)
						{
							asm volatile("nop\n\t");
						}

						data_out[byte_sending]=data_out[byte_sending]>>1;
						i--;
				}
			}
	}
	else//channel was in use before starting
	{
		//ensure led is off
		PORTB &= ~tx_mask;
		DDRB &= ~tx_mask;
	
		sei();//end critical
		return(5);
	}
	//ensure led is off
	PORTB &= ~tx_mask;
	DDRB &= ~tx_mask;
	if(collision_detected==0)
	{
		//wait for own signal to die down
		for(int k=0;k<50;k++)
			asm volatile("nop\n\t");

			ACSR |= (1<<ACI);

		sei();//end critical
		return(1);
	}
	else
	{
	
		sei();//end critical
		return(0);
	}	
}


//watch dog timer isr. Used for the low power sleep mode
ISR(WDT_vect)
{
	
	//wake up 
	asm volatile("wdr\n\t");
	DDRD |= (1<<2);//make power supply control pin an output
	PORTD |= (1<<2);//turn on the power supply	  
	ADCSRA |= (1<<ADEN);//turn on the a/d converter
	
	//disable watch dog timer
	WDTCSR |= (1<<WDCE)|(1<<WDE);
	WDTCSR = 0;


	//check to see if message is incoming
	sei();
	set_color(3,3,3);
	_delay_ms(10);
	set_color(0,0,0);	
	
}


ISR(TIMER0_COMPA_vect)//timer interrupt attempts to send messages every fixed amount of time
{
	static int clock_0=0;//varaible used to determine when to try transmitting agian
	tx_clock+=time_since_last;	
	clock_0+=time_since_last;
	clock_1+=time_since_last;
	clock_3+=time_since_last;
	clock+=time_since_last;

	clock_2+=time_since_last/100;
	if(clock_2>32000)
		clock_2=0;
	time_since_last=0xff;	

	OCR0A=0xff;

	if(tx_clock>550)
		if(enable_tx==1)
		{
			int return_value;
	
		
			if(message_incoming==0)
			{
			//	set_color(1,0,0);
				return_value=send_message(message_tx0,message_tx1,message_tx2);//try to send the message
				//	set_color(0,0,0);
			}
			else
				return_value=3;
	
	
			if(return_value==0)//collision detected during transmission
			{
			
				time_since_last=rand()%255;
				OCR0A=time_since_last;//set next try to be a random time between 0.000128 and 0.03264 seconds later

			}
			else if(return_value==1)//sucessfull send
			{
		
				tx_clock=0;
			
			}
			else//channel aready in use
			{
				time_since_last=rand()%255;
				OCR0A=time_since_last;//set next try to be a random time between 0.000128 and 0.03264 seconds later

			}
	
		}

	//this is part of the system that makes sure you receive multiple special message from the over head controller
	//within a short time.. this ensures corrupt messages do not trigger a special message mode 
	if(clock_0>2295)
	{
		clock_0=0;
		special_message_buffer[0]=0;
		special_message_buffer[1]=0;
		special_message_buffer[2]=0;
		special_message_pointer=0;
	}

}



//isr for timer 1, this is used for receiving data over infra red
ISR(TIMER1_COMPA_vect)//triggers at the end of each byte (actually 1 flow bit, 8 data bits) received
{
	leading_bit=1;	
		
	if(incoming_byte==0)
	{
		
		//store adc value
		adc_low_gain=ADCW;
		
		//set adc to trigger converstion on next compairitor interrupt
		ADMUX=0;
		ADCSRA = (1<<ADEN)  | (1<<ADATE) | (1<<ADIF) |  (1<<ADPS1)|  (1<<ADPS0);//| (1<<ADIE);// | (1<<ADPS0); //enable a/d, have it trigger converstion start on a compairitor interrrupt.Note: turn off for power saving
		ADCSRB = (1<<ADTS0);//set compairitor to be trigger source


		incoming_message[0]=incoming_byte_value;
		incoming_byte=1;
		if(incoming_byte_value!=0)
		{	
			
			incoming_message[0]=0;
			incoming_message[1]=0;
			incoming_message[2]=0;
			incoming_message[3]=0;
			incoming_message[4]=0;
			ADMUX=1;
			ADCSRA = (1<<ADEN)  | (1<<ADATE) |  (1<<ADIF) |  (1<<ADPS1)|  (1<<ADPS0) ;// |(1<<ADIE);//| (1<<ADPS0); //enable a/d, have it trigger converstion start on a compairitor interrrupt.Note: turn off for power saving
			ADCSRB = (1<<ADTS0);//set compairitor to be trigger source


			TCCR1B=0;//turn counter1 off
			TCNT1H=0;//reset counter value to 0
			TCNT1L=0;//reset counter value to 0
			incoming_byte=0;
			message_incoming=0;//no longer receiving a message
			time_since_last+=3;//take into account time that timer0 was paused
			TCCR0B=0x05;//turn timer0 back on

		
		}
		randseed+=ADCW;
	}
	else if(incoming_byte==1)
	{
		adc_high_gain=ADCW;
		incoming_message[1]=incoming_byte_value;
		
		incoming_byte=2;
		randseed+=ADCW;
	}
	else if(incoming_byte==2)
	{
		incoming_message[2]=incoming_byte_value;
		incoming_byte=3;
	}	
	else if(incoming_byte==3)
	{
		incoming_message[3]=incoming_byte_value;
		incoming_byte=4;
	}	
	else if(incoming_byte==4)
	{	
		incoming_message[4]=incoming_byte_value;
		incoming_byte=0;

	

		//store data in buffer
		uint8_t check=incoming_message[1]+incoming_message[2]+incoming_message[3]+128;
		int checksum_good=0;
		//set_color(0,1,0);
		
		if((check==(incoming_message[4]))&&(incoming_message[0]==0))
		{
			//set_color(0,1,0);
			checksum_good=1;

			
			//compute distance from a/d readings based on sensor calibration values
			int index_low=-1;
			uint8_t distance_mm_low=255;
			int index_high=-1;
			uint8_t distance_mm_high=255;
			uint8_t distance;

			//compute distance for high gain and low gain when required (use low gain when high gain >900, both if between 900 and 700, high if less than 700)
			if(adc_high_gain<900)//use high gain
			{
				if(adc_high_gain>sensor_cal_data_high[0])
				{
					distance_mm_high=0;
	
				}
				else
				{


					for(int a=1;a<14;a++)
					{
						if(adc_high_gain>sensor_cal_data_high[a])
						{

							index_high=a;

							break;
						}

					}
					if(index_high==-1)
					{
						distance_mm_high=90;
						
				
			
					}
					else
					{
								
						double slope=(sensor_cal_data_high[index_high]-sensor_cal_data_high[index_high-1])/0.5;

						double b=(double)sensor_cal_data_high[index_high]-(double)slope*((double)index_high*(double)0.5+(double)0.0);

						b=(((((double)adc_high_gain-(double)b)*(double)10)));
						b=((int)((int)b/(int)slope));
						distance_mm_high=b;
							

					}

				}
			
			}
			if(adc_high_gain>700)//use low gain
			{
				if(adc_low_gain>sensor_cal_data_low[0])
				{
					distance_mm_low=0;
				
				}
				else
				{
					for(int a=1;a<14;a++)
					{
						if(adc_low_gain>sensor_cal_data_low[a])
						{

							index_low=a;

							break;
						}

					}
					if(index_low==-1)
					{
						distance_mm_low=90;
			
					}
					else
					{
						double slope=(sensor_cal_data_low[index_low]-sensor_cal_data_low[index_low-1])/0.5;

						double b=(double)sensor_cal_data_low[index_low]-(double)slope*((double)index_low*(double)0.5+(double)0.0);

						b=(((((double)adc_low_gain-(double)b)*(double)10)));
						b=((int)((int)b/(int)slope));
						distance_mm_low=b;
							

					}

				}
			

			}
			
			if((distance_mm_low!=255)&&(distance_mm_high!=255))
			{
				distance=((double)distance_mm_high*(900.0-adc_high_gain)+(double)distance_mm_low*(adc_high_gain-700.0))/200.0;
			
			}
			else if(distance_mm_low!=255)
			{
				distance=distance_mm_low;
		
			}
			else 
			{
				distance=distance_mm_high;
			
			}
			
			distance+=33;
			


			if((incoming_message[3]&(0x01))==0)// message is not a special mode message
			{
				//write in oldest txvalue_buffer location
				txvalue_buffer[0][txvalue_buffer_pointer]=incoming_message[1];
				txvalue_buffer[1][txvalue_buffer_pointer]=incoming_message[2];
				txvalue_buffer[2][txvalue_buffer_pointer]=incoming_message[3];
				txvalue_buffer[3][txvalue_buffer_pointer]=distance;
				txvalue_buffer[4][txvalue_buffer_pointer]=adc_low_gain;
				txvalue_buffer[5][txvalue_buffer_pointer]=1;//mark as new entry
				txvalue_buffer[6][txvalue_buffer_pointer]=adc_high_gain;
		
				txvalue_buffer_pointer++;

				if(txvalue_buffer_pointer==4)
					txvalue_buffer_pointer=0;

			}
		
			
			
		}
		else
		{
			checksum_good=0;
			
		}	

	
		if(checksum_good==1)//checksum passes
			if((incoming_message[3]&(0x01))!=0)// message is a special mode message
				if(incoming_message[2]==0)// this byte needs to be blank
					if(incoming_message[1]<9)//ignore if message is not valid
						if(special_mode_message!=incoming_message[1])//if i havent reacted to the special mode message yet
						{
							if(incoming_message[1]!=0x03)
							{
								for( int a=0 ; a<special_message_pointer ; a++ )
								{
									if(special_message_buffer[a]!=incoming_message[1])
									{

										special_message_buffer[0]=0;
										special_message_buffer[1]=0;
										special_message_buffer[2]=0;
										special_message_pointer=0;

									}

								}
								if(special_message_pointer<3)
								{
									special_message_buffer[special_message_pointer]=incoming_message[1];
									special_message_pointer++;


								}

								if(special_message_pointer==3)
								{
									special_mode_message=incoming_message[1];
									special_mode=1;  // special mode will be entered when reached in main loop
									special_message_buffer[0]=0;
									special_message_buffer[1]=0;
									special_message_buffer[2]=0;
									special_message_pointer=0;
								}
						

							}


							if(incoming_message[1]==0x03)
							{
								wakeup=1;
								special_mode_message=incoming_message[1];
								special_mode=1;  // special mode will be entered when reached in main loop
					
							}
						}
				
		
		//prepare a/d for next communication
		ADMUX=1;
		ADCSRA = (1<<ADEN)  | (1<<ADATE) |  (1<<ADIF) |  (1<<ADPS1)|  (1<<ADPS0)  ;//|(1<<ADIE);//| (1<<ADPS0); //enable a/d, have it trigger converstion start on a compairitor interrrupt.Note: turn off for power saving
		ADCSRB = (1<<ADTS0);//set compairitor to be trigger source

		message_incoming=0;//no longer receiving a message

	
		incoming_message[0]=0;
		incoming_message[1]=0;
		incoming_message[2]=0;
		incoming_message[3]=0;
		incoming_message[4]=0;


		TCCR1B=0;//turn counter1 off
		TCNT1H=0;//reset counter value to 0
		TCNT1L=0;//reset counter value to 0
		time_since_last+=12;//take into account time that timer0 was paused
		TCCR0B=0x05;//turn timer0 back on

		
	}
		

	incoming_byte_value=0;//reset incoming byte value for next byte
	
}



//isr for compairtor, needed for IR communication
ISR(ANALOG_COMP_vect)//triggers when a pulse is seen on the IR receiver, so every bit received
{
	int temp=TCNT1;
	TCCR0B=0x00;//turn off timer0 so message can be rx properly
	if(leading_bit==1)//leading bit received
	{
		
		TCNT1H=0;//reset counter value to 0
		TCNT1L=0;//reset counter value to 0
		TCCR1B=1;//start timer
		ADCSRA &= ~(1<<ADATE);//prevent adc more converstions from happening 
		if(incoming_byte==0)//9 bits for first flow control "byte"
		{
			//set timeout for end of byte
			OCR1AH=0x09;//high byte for timer compair interrupt
			OCR1AL=0x80;//low byte for timer compair interrupt	
		//	OCR1AH=0x0b;//high byte for timer compair interrupt
		//	OCR1AL=0x30;//low byte for timer compair interrupt	


		}
		else
		{
			//set timeout for end of byte
			OCR1AH=0x08;//high byte for timer compair interrupt
			OCR1AL=0x40;//low byte for timer compair interrupt
		//	OCR1AH=0x08;//high byte for timer compair interrupt
		//	OCR1AL=0xa0;//low byte for timer compair interrupt	
	

		}
						
		leading_bit=0;
		
			
	}
	else
	{
		
		if(temp<(time_a+time_b*3 +timeb_half))
		{
			if(temp<(time_a+time_b*1 +timeb_half))
			{
				if(temp<(time_a+time_b*0 +timeb_half))//0
				{
					incoming_byte_value+=128;
				}
				else//1
				{
					incoming_byte_value+=64;
				}

			}
			else
			{
				if(temp<(time_a+time_b*2 +timeb_half))//2
				{
					incoming_byte_value+=32;

				}
				else//3
				{
					incoming_byte_value+=16;

				}


			}


		}
		else
		{
			if(temp<(time_a+time_b*5 +timeb_half))
			{
				if(temp<(time_a+time_b*4 +timeb_half))//4
				{
					incoming_byte_value+=8;

				}
				else//5
				{
					incoming_byte_value+=4;

				}

			}
			else
			{
				if(temp<(time_a+time_b*6 +timeb_half))//6
				{
					incoming_byte_value+=2;

				}
				else//7
				{
					incoming_byte_value+=1;

				}


			}


		}

	
	}
		
	message_incoming=1;// a message is being recieved

}



void kprints(char *i)//print string for debugging out serial
{
	
	//for usage, kprints("hello world") up to 10 characters
	for(int a=0;a<10;a++)
	{
		UDR0=(i[a]);
			while(!(UCSR0A & (1<<UDRE0)));	
	}

	UDR0=(0x0A);

	while(!(UCSR0A & (1<<UDRE0)));
		UDR0=(0x0d);
	while(!(UCSR0A & (1<<UDRE0)));
}


void kprinti(int i)//print int for debugging out serial
{
	
	char buffer[10]; 
	for(int a=0;a<10;a++)
		buffer[a]=0;

	itoa(i,buffer,10);
	for(int a=0;a<10;a++)
	{
			UDR0=(buffer[a]);
			while(!(UCSR0A & (1<<UDRE0)));
	}

	UDR0=(0x20);
	while(!(UCSR0A & (1<<UDRE0)));
//		UDR0=(0x0d);
//	while(!(UCSR0A & (1<<UDRE0)));

}

//function for setting motor speeds
void set_motor(char cw, char ccw)
{ 
	OCR2A=ccw;
	OCR2B=cw;
}




//measures the ambient light sensor value, will return -1 if there is a message incoming, which need the a/d
int get_ambient_light(void)
{
	if(message_incoming==0)
	{
		cli();
		ADMUX=7;
		ADCSRA |= (1<<ADSC);//start adc
		while((ADCSRA&(1<<ADIF))==0);
		ADMUX=1;
		ADCSRA = (1<<ADEN)  | (1<<ADATE) |  (1<<ADIF) |  (1<<ADPS1)  ;//|(1<<ADIE);//| (1<<ADPS0); //enable a/d, have it trigger converstion start on a compairitor interrrupt.Note: turn off for power saving
		ADCSRB = (1<<ADTS0);//set compairitor to be trigger source
		sei();
		return(ADCW);
	}
	else
		return(-1);
}


//measures the robot battery voltage, will return -1 if there is a message incoming, which need the a/d
int measure_voltage( void)
{	
	if(message_incoming==0)
	{
		while((ADCSRA&(1<<ADSC))==1);
		cli();
		ADMUX=6;
		ADCSRA |= (1<<ADSC);//start adc
		while((ADCSRA&(1<<ADIF))==0);
		sei();

		//kprinti(ADCW);
		int voltage=(.0059*(double)ADCW+.0156)*100.0;

		return(voltage);
	}
	else
		return(-1);
}



//checks to see if robot is chargin its battery or not
int measure_charge_status(void)
{

	if(PIND & (1<<0))
	{
		//no, not charging
		return(0);
	}
	else
	{
		//yes charging
		return(1);
	}
}



//function used to handle the low power sleep mode for robot
void enter_sleep(void)
{
	wakeup=0;
	cli();
	//set registers for sleep mode
	SMCR= (1<<SM1);
	MCUSR=0;
	WDTCSR |= (1<<WDCE)|(1<<WDE);
	WDTCSR = (1<<WDIE) | (1<<WDP3)| (1<<WDP0);

	//this turns off all the devices, and then enters an 8s deep sleep (55ua current draw)
	DDRB=0;
	PORTB=0;
	DDRC=0;
	PORTC=0;
	DDRD=0;
	PORTD=0;
	sei();
	ADCSRA &= ~(1<<ADEN); //turn off a2d

	asm volatile("wdr\n\t");
	SMCR|= (1<<SE);
	asm volatile("sleep\n\t");
	sei();

	while(wakeup==0)//go back to sleep
	{
	
		//set registers for sleep mode
		SMCR= (1<<SM1);
		MCUSR=0;
		WDTCSR |= (1<<WDCE)|(1<<WDE);
		WDTCSR = (1<<WDIE) | (1<<WDP3)| (1<<WDP0);
	
		//this turns off all the devices, and then enters an 8s deep sleep (55ua current draw)
		DDRB=0;
		PORTB=0;
		DDRC=0;
		PORTC=0;
		DDRD=0;
		PORTD=0;
		sei();
		ADCSRA &= ~(1<<ADEN); //turn off a2d
		asm volatile("wdr\n\t");
		SMCR|= (1<<SE);
		asm volatile("sleep\n\t");
		sei();

	}

	//re enable motors
	DDRD |= (1<<3);
	DDRB |= (1<<3);
	TCCR2A |= (1<<COM2A1) | (1<<COM2B1) | (1<<WGM20);
	TCCR2B |= (1<<CS01); //prescaler set to /8
	OCR2B = 0x00;//start with motor off
	OCR2A = 0x00;//start with motor off
}



//for controlling the rgb led (0..3 for each color)
void set_color(int8_t red,int8_t green,int8_t blue)
{
//port assignments from pcb	
//BLUE
//PB1 msb

//GREEN
//PD2 msb
//PC5
//PC4 lsb

//RED
//PB6 msb
//PB7
//PD5 lsb

	
	if((blue%2)!=0)//lsb
		DDRC |= (1<<5);
	else
		DDRC &= ~(1<<5);

	blue=(blue>>1);
	if((blue%2)!=0)
		DDRC |= (1<<4);
	else
		DDRC &= ~(1<<4);


	if((red%2)!=0)//lsb
		DDRD |= (1<<5);
	else
		DDRD &= ~(1<<5);

	red=(red>>1);
	if((red%2)!=0)
		DDRD |= (1<<4);
	else
		DDRD &= ~(1<<4);


	if((green%2)!=0)//lsb
		DDRC |= (1<<3);
	else
		DDRC &= ~(1<<3);

	green=(green>>1);
	if((green%2)!=0)
		DDRC |= (1<<2);
	else
		DDRC &= ~(1<<2);
}



void init_robot(void)
{
	/////////////////////////
	//starting initalizations
	/////////////////////////
	//int TestLED=0;
	
	//clear special message buffer	
	special_message_buffer[0]=0;
	special_message_buffer[1]=0;
	special_message_buffer[2]=0;

	//clear txvalue_buffer
	for(int i=0;i<4;i++)
		txvalue_buffer[5][i]=0;	

	//port initalizations
	DDRB=0;
	PORTB=0;
	DDRC=0;
	PORTC=0;
	DDRD=0;
	PORTD=0;

	DDRD |= (1<<2);//make power supply control pin an output
	PORTD |= (1<<2);//turn on the power supply

	//set up rc oscillator to calibrated value
	OSCCAL=eeprom_read_byte((uint8_t *)ee_OSCCAL);//read rc calibration data from eeprom, and write it to OSCCAL
	
	//initalize uart for output of serial debugging info
	DDRD |= (1<<1);
	UBRR0=1;//256000 baud
	UCSR0A = 0;
	UCSR0B |= (1<<TXEN0);
	UCSR0C |= (1<<UCSZ01) | (1<<UCSZ00);
	kprints("start init");

	//initalize motors/pwm
	DDRD |= (1<<3);
	DDRB |= (1<<3);
	TCCR2A |= (1<<COM2A1) | (1<<COM2B1) | (1<<WGM20);
	TCCR2B |= (1<<CS01); //prescaler set to /8
	OCR2B = 0x00;//start with motor off
	OCR2A = 0x00;//start with motor off

	//initalize analog comparator
	ACSR |= (1<<ACIE) | (1<<ACIS1)| (1<<ACIS0) ;//trigger interrupt on rising output edge
	DIDR1=3;

	//initalize adc
	ADMUX = 0;//choose analog refrence pin AREF
	ADCSRA = (1<<ADEN) | (1<<ADSC) |  (1<<ADPS1) | (1<<ADPS0); //enable a/d, have it trigger converstion start on a compairitor interrrupt.Note: turn off for power saving
	
	//initalize timer1
	TCCR1A=0x00;
	TCCR1B=0x01;
	TIMSK1=0x02;
	OCR1AH=0x32;//high byte for timer compair interrupt
	OCR1AL=0x00;//low byte for timer compair interrupt	

	//initalize timer0
	TCCR0A=0x00;
	TCCR0B=0x05;
	TIMSK0=0x02;
	OCR0A=0xff;

	//read low gain sensor calibration data from eeprom, store in sensor_cal_data_low[]
	for(int i=0;i<14;i++)
	{
		
		sensor_cal_data_low[i]=eeprom_read_byte((uint8_t *) (ee_SENSOR_LOW+i*2));
		sensor_cal_data_low[i]=sensor_cal_data_low[i]<<8;
		sensor_cal_data_low[i]+=eeprom_read_byte((uint8_t *) (ee_SENSOR_LOW+i*2+1));
		

	}
	//read high gain sensor calibration data from eeprom, store in sensor_cal_data_high[]
	for(int i=0;i<14;i++)
	{
		
		sensor_cal_data_high[i]=eeprom_read_byte( (uint8_t *)(ee_SENSOR_HIGH+i*2));
		sensor_cal_data_high[i]=sensor_cal_data_high[i]<<8;
		sensor_cal_data_high[i]+=eeprom_read_byte((uint8_t *) (ee_SENSOR_HIGH+i*2+1));


	}

  	// Read the motor calibration data from eeprom
	cw_in_place = eeprom_read_byte((uint8_t *)ee_CW_IN_PLACE);
	ccw_in_place = eeprom_read_byte((uint8_t *)ee_CCW_IN_PLACE);
	cw_in_straight = eeprom_read_byte((uint8_t *)ee_CW_IN_STRAIGHT);
	ccw_in_straight = eeprom_read_byte((uint8_t *)ee_CCW_IN_STRAIGHT);

	//load transmission strength calibration data from eeprom
	tx_mask=eeprom_read_byte((uint8_t *) (ee_TX_MASK));

	//print out calibration data
	kprints("                    ");
	kprints("Calibration data    ");
	kprints("                    ");
	kprints("low gain          ");
	for(int i=0;i<14;i++)
		kprinti(sensor_cal_data_low[i]);
	kprints("                    ");
	kprints("high gain          ");
	for(int i=0;i<14;i++)
		kprinti(sensor_cal_data_high[i]);
	kprints("                    ");
	kprints("txmask     ");
	kprinti(tx_mask);
	kprints("            ");
	kprints("OSCCAL     ");
	kprinti(OSCCAL);
	kprints("            ");
	kprints("program start");
	kprints("            ");

	//flash RGB LED red green blue quickly.. just to show the robot is now on.
	set_color(1,0,0);
	_delay_ms(300);
	set_color(0,1,0);
	_delay_ms(300);
	set_color(0,0,1);
	_delay_ms(300);
	set_color(0,0,0);
	
	//start robot so it doesnt send any ir messages
	enable_tx=0;

	sei();//enable interrupts
	
	//clear txvalue_buffer, so robot ignors any messages received before it was ready
	for(int i=0;i<4;i++)
		txvalue_buffer[5][i]=0;			
}



void main_program_loop(void (*user_prgm) (void))
{

	while(1)//main program loop
	{	
		
		//special message controller, handles controll messages like sleep and resume program
		if(special_mode==1)
		{
			run_program=0;
			sei();
			special_mode=0;

			//modes for different values of special_mode_message
			//0x01 bootloader
			//0x02 sleep
			//0x03 wakeup, go to mode 0x04
			//0x04 Robot on, but does nothing active
			//0x05 display battery voltage
			//0x06 execute program code
			//0x07 battery charge
			//0x08 reset program
	
			if(special_mode_message==0x01)
			{
				//stop motors and ir led
				OCR2B = 0x00;
				OCR2A = 0x00;
				PORTD &= ~(1<<4);
				enable_tx=0;
				TCCR0B=0x00;//turn off timer0
				asm("jmp 0x7000");//jump to bootloader
			}
			if(special_mode_message==0x02)
			{
				enable_tx=0;
				wakeup=0;
				enter_sleep();//will not return from enter_sleep() untill a special mode message 0x03 is received	
			}
			if((special_mode_message==0x03)||(special_mode_message==0x04))
			{
				//wakeup already set to 1 in timer1 interrupt
			
				//special_mode=0;
				set_color(0,0,0);
				OCR2B = 0x00;
				OCR2A = 0x00;
				PORTD &= ~(1<<4);
				enable_tx=0;
				while(special_mode==0)//loop untill another special mode message is received
				{	
					set_color(3,3,0);
					_delay_ms(10);
					set_color(0,0,0);
					_delay_ms(1000);


				}
				enable_tx=1;
			
			}
			if(special_mode_message==0x05)
			{
			//	special_mode=0;
				OCR2B = 0x00;
				OCR2A = 0x00;
				PORTD &= ~(1<<4);
				TCCR0B=0x00;//turn off timer 0 to stop message transmissions
				enable_tx=0;
				while(special_mode==0)//loop untill another special mode message is received
				{
					if(measure_voltage()>400)
						set_color(0,3,0);
					else if(measure_voltage()>390)
						set_color(0,0,3);
					else if(measure_voltage()>350)
						set_color(3,3,0);
					else
						set_color(3,0,0);
					

				}
				enable_tx=1;
				TCCR0B=0x05;//turn on timer 0 to re-allow message transmissions
			}
			if(special_mode_message==0x06)
			{	
				enable_tx=1;
				run_program=1;
				//no code here, just allows special_mode to end 

			}
			if(special_mode_message==0x07)
			{
			//	special_mode=0;
				OCR2B = 0x00;
				OCR2A = 0x00;
				PORTD &= ~(1<<4);
				TCCR0B=0x00;//turn off timer 0 to stop message transmissions
				enable_tx=0;
				while(special_mode==0)//loop untill another special mode message is received
				{
				
					if(measure_charge_status()==1)
					{
						set_color(1,0,0);
						_delay_ms(2);
						set_color(0,0,0);
						_delay_ms(200);
					}
				}
				enable_tx=1;
				TCCR0B=0x05;//turn on timer 0 to re-allow message transmissions
			}
			if(special_mode_message==0x08)
			{
				cli(); 
				 wdt_enable(WDTO_15MS);  
			    for(;;)                
			    {                       
			    }       

			}
		
	
		}
		if(run_program==1)
		{	
			
			user_prgm();

		}
		


	}
}
