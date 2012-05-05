ScadaPlant = letk.Class( function( self )
    Object.__super( self )

    self:set('file_name', '*new plant' )
    
    self.component           = letk.List.new()
    self.automata_group      = nil
    self.automata_group_name = nil
end, Object )

ScadaPlant.__TYPE = 'scadaplant'

function ScadaPlant:add_component( name )
    local new_component = ScadaComponent[ name ].new()
    self.component:append( new_component )

    return new_component
end

function ScadaPlant:add_automata_group( ag )
    if type( ag ) == 'string' then
        self.automata_group_name = ag
    else
        self.automata_group      = ag
        self.automata_group_name = ag:get( 'file_name' )
        print( 'added', self.automata_group_name )
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
    local max_x, max_y = 200,200
    for k, component in self.component:ipairs() do
        local x, y = component:render( cr )
        if max_x < x then max_x = x end
        if max_y < y then max_y = y end
    end
    return max_x, max_y
end

function ScadaPlant:load_automata_group( element_list )
    if self.automata_group_name then
        for k, v in element_list:ipairs() do
            if v.__TYPE == 'automatagroup' then
                local file_nm = v:get( 'file_name' )
                if file_nm and file_nm == self.automata_group_name then
                    self.automata_group = v
                    v:load_automata( element_list )
                    return true
                end
            end
        end    
        return false
    end
    return false
end

function ScadaPlant:save_serialize()
    local data                 = {
        components          = {},
        automata_group_name = nil,
    }

    for k, component in self.component:ipairs() do
        data.components[ #data.components + 1 ] = component:dump()
    end
    
    if self.automata_group_name then
        data.automata_group_name = self.automata_group_name
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

function ScadaPlant:load_file( file_name, elements )
    local file = io.open( file_name, 'r')
    if file then
        local s    = file:read('*a')
        local data = loadstring('return ' .. s)()
        if data then
            for k, component in ipairs( data.components ) do
                local new_component = self:add_component( component.name or 'Base' )
                new_component:charge( component )
            end
            
            self.automata_group_name = data.automata_group_name
            self:load_automata_group( elements )

            self:set( 'file_type', 'nsp' )
            self:set( 'full_file_name', file_name )
            self:set( 'file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
        end
    end
end
