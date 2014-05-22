typedef struct SmsgDisableEvents {
    //~ unsigned char numAutomata;
    unsigned char *states; //2 * numAutomata bytes
    unsigned char *checkAutomata; // ceil(numAutomata/8) bytes
    unsigned char disableEvents[32];
} TmsgDisableEvents;

typedef struct SmsgNextState {
    //~ unsigned char numAutomata;
    unsigned char *states; //2 * numAutomata bytes
    unsigned char *checkAutomata; // ceil(numAutomata/8) bytes
    unsigned char event;
} TmsgNextState;
