local Devices = {}

Devices['pic18f'] = {
    type    = 'microcontroller',
    file    = 'pic18f.c',
    clock   = 20000000,
    include = '18F4620.h',
    fuses   = 'NOMCLR,EC_IO,H4,NOWDT,NOPROTECT,NOLVP,NODEBUG'
}

return Devices
