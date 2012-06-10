require'redis'

--lua -i fake_server.lua [ip] [port] [namespace] [database]

param = {
    host      = 'localhost',
    port      = '6379',
    namespace = 'NadzoruScada',
    database  = '0',
    device    = '/dev/ttyUSB0',
}

for i = 1,#arg,2 do
    param[ arg[i] ] = arg[2]
end

conn = Redis.connect{
    host = param.host,
    port = param.port,
}
conn:select( tonumber( param.database ) )

function exec( ev )
    conn:lpush( param.namespace .. '_EVENTS', ev)
end

function clear( ev )
    conn:del( param.namespace .. '_EVENTS' )
end

local fdevice = io.open( param.device, 'a+' )
function dev( n )
    fdevice:write( string.char( n ) )
    fdevice:flush()
end



