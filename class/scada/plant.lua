ScadaPlant = letk.Class( function( self )
    Object.__super( self )

    self:set('file_name', '*new plant' )
    
    self.component = letk.List.new()
    self.automata = {
        g = {},
        e = {},
        k = {},
        s = {},
    }
    self.automata_object = nil
end, Object )

ScadaPlant.__TYPE = 'scadaplant'

function ScadaPlant:add_component( name )
    local new_component = ScadaComponent[ name ].new()
    self.component:append( new_component )

    return new_component
end

function ScadaPlant:load_automata( element_list )
    self.automata_object = {}
    for k, v in element_list:ipairs() do
        if v.__TYPE == 'automaton' then
            local file_nm = v:get( 'file_name' )
            if file_nm and (
                self.automata.g[ file_nm ] or
                self.automata.e[ file_nm ] or
                self.automata.k[ file_nm ] or
                self.automata.s[ file_nm ]
            ) then
                self.automata_object[ file_nm ] = v
            end
        end
    end
end

function ScadaPlant:get_selected( x, y )
    for k, component in self.component:ipairs() do
        if component:is_selected( x, y ) then
            return component, k
        end
    end
    return nil
end

function ScadaPlant:render( cr )
    for k, component in self.component:ipairs() do
        component:render( cr )
    end
end

function ScadaPlant:save_serialize()
    local data                 = {
        components       = {},
        automata_files = {
            g = {},
            e = {},
            k = {},
            s = {},
        },
    }

    for k, component in self.component:ipairs() do
        data.components[ #data.components + 1 ] = component:dump()
    end
    
    for t, l in pairs( self.automata ) do
        for name, const in pairs( l ) do
            data.automata_files[ t ][ name ] = true
        end
    end

    return letk.serialize( data )
end

local FILE_ERROS = {}
FILE_ERROS.ACCESS_DENIED     = 1
FILE_ERROS.NO_FILE_NAME      = 2
FILE_ERROS.INVALID_FILE_TYPE = 3

function ScadaPlant:save()
    local file_type = self:get( 'file_type' )
    local file_name = self:get( 'full_file_name' )
    if file_type == 'nsp' and file_name then
        if not file_name:match( '%.nsp$' ) then
            file_name = file_name .. '.nsp'
        end
        local file = io.open( file_name, 'w')
        if file then
            local code = self:save_serialize()
            file:write( code )
            file:close()
            return true
        end
        return false, FILE_ERROS.ACCESS_DENIED, FILE_ERROS
    elseif not file_type then
        return false, FILE_ERROS.NO_FILE_NAME, FILE_ERROS
    else
        return false, FILE_ERROS.INVALID_FILE_TYPE, FILE_ERROS
    end
end

function ScadaPlant:save_as( file_name )
    if file_name then
        if not file_name:match( '%.nsp$' ) then
            file_name = file_name .. '.nsp'
        end
        local file = io.open( file_name, 'w')
        if file then
            local code = self:save_serialize()
            file:write( code )
            file:close()
            self:set( 'file_type', 'nsp' )
            self:set( 'full_file_name', file_name )
            self:set( 'file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
            return true
        end
        return false, FILE_ERROS.ACCESS_DENIED, FILE_ERROS
    else
        return false, FILE_ERROS.NO_FILE_NAME, FILE_ERROS
    end
end

function ScadaPlant:load_file( file_name )
    local file = io.open( file_name, 'r')
    if file then
        local s    = file:read('*a')
        local data = loadstring('return ' .. s)()
        if data then
            for k, component in ipairs( data.components ) do
                local new_component = self:add_component( component.name or 'Base' )
                new_component:charge( component )
            end
            
            for t, l in pairs( data.automata_files ) do
                for name, const in pairs( l ) do
                    self.automata[ t ][ name ] = true
                end
            end

            self:set( 'file_type', 'nsp' )
            self:set( 'full_file_name', file_name )
            self:set( 'file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
        end
    end
end
