require'redis'

--lua -i fake_server.lua [ip] [port] [namespace] [database]

conn = Redis.connect{
    host = arg[1] or 'localhost',
    port = arg[2] or 6379,
}
conn:select( tonumber(arg[4]) or 0 )

function exec( ev )
    conn:lpush( (arg[3] or 'NadzoruScada') .. '_EVENTS', ev)
end

function clear( ev )
    conn:del( (arg[3] or 'NadzoruScada') .. '_EVENTS' )
end



