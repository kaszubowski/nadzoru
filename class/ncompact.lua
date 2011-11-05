require 'letk'

local NCompact = letk.Class( function( self )
    self.fs = {}
end )

function NCompact:env( path )
    self.tbl_mt = self.tbl_mt or {
        __index = function( this, k )
            this[ k ] = {}
            setmetatable( this[ k ], self.tbl_mt )
            return this[ k ]
        end
    }
    self.f_env = self.f_env or setmetatable( {}, {
        __index    = function( this, k )
            if not self.fs[ k ] then
                self.fs[ k ] = {}
                setmetatable( self.fs[ k ], self.tbl_mt )
            end
            return self.fs[ k ]
        end,
        __newindex = function( this, k, v )
            if type( v ) == 'table' then
                setmetatable( v, self.tbl_mt )
            end
            self.fs[ k ] = v
        end,
    } )

    return self.f_env
end

function NCompact:pathmake( path )
    path = path:gsub( '[%/\\]?([^%/\\]*%.[^%/\\]+)', function( cap ) return '[\"' .. cap .. '\"]' end )
    path = path:gsub('[%/\\]','%.')
    path = select( 3, path:find('^%.?(.-)%.?$') )
    return path
end

function NCompact:mkdir( path )
    local f   = loadstring( self:pathmake( path ) .. ' = {}' )
    local env = self:env()
    setfenv( f, env )
    f()
end

function NCompact:rm( path )
    local f   = loadstring( self:pathmake( path ) .. ' = nil' )
    local env = self:env()
    setfenv( f, env )
    f()
end

function NCompact:get( path )
    local f   = loadstring( 'return ' .. self:pathmake( path ) )
    local env = self:env()
    setfenv( f, env )
    return f()
end

function NCompact:set( path, data )
    local f   = loadstring( self:pathmake( path ) ..  ' = ' .. string.format( "%q", data ) )
    local env = self:env()
    setfenv( f, env )
    return f()
end

function NCompact:save_as( file_name )
    local file = io.open( file_name, 'w')

    if file then
        file:write( letk.serialize( self.fs ) )
        self.file_name = file_name
        file:close()
        return true
    end

    return false
end

function NCompact:save( )
    if self.file_name then
        self:save_as( self.file_name )
    end
end

function NCompact:load( file_name )
    local file = io.open( file_name, 'r')
    if file then
        local s = file:read('*a')
        self.fs = loadstring('return ' .. s )()
        return true
    end

    return false
end

function NCompact:write_file( path, file_name )
    local data = self:get( path )
    local file = io.open( file_name, 'wb')
    if file and data then
        file:write( data )
        file:close()
        return true
    end

    return false
end

function NCompact:read_file( path, file_name )
    local file = io.open( file_name, 'rb')
    if file then
        local data = file:read('*a')
        if data then
            self:set( path, data )
            return true
        end
    end

    return false
end

return NCompact


