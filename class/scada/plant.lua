--[[
    This file is part of nadzoru.

    nadzoru is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    nadzoru is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with nadzoru.  If not, see <http://www.gnu.org/licenses/>.

    Copyright (C) 2011 Yuri Kaszubowski Lopes, Eduardo Harbs, Andre Bittencourt Leal and Roberto Silvio Ubertino Rosso Jr.
--]]

--[[
module "ScadaPlant"
--]]
ScadaPlant = letk.Class( function( self )
    Object.__super( self )

    self:set('file_name', '*new plant' )
    
    self.component           = letk.List.new()
    self.automata_group      = nil
    self.automata_group_name = nil
end, Object )

ScadaPlant.__TYPE = 'scadaplant'

---TODO
--TODO
--@param self TODO
--@param name TODO
--@return TODO
function ScadaPlant:add_component( name )
    local new_component = ScadaComponent[ name ].new()
    self.component:append( new_component )

    return new_component
end

---TODO
--TODO
--@param self TODO
--@param ag TODO
function ScadaPlant:add_automata_group( ag )
    if type( ag ) == 'string' then
        self.automata_group_name = ag
    else
        self.automata_group      = ag
        self.automata_group_name = ag:get( 'file_name' )
        print( 'added', self.automata_group_name )
    end
end

---TODO
--TODO
--@param self TODO
--@param x TODO
--@param y TODO
--@return TODO
--@see ScadaComponent.Base:is_selected
function ScadaPlant:get_selected( x, y )
    for k, component in self.component:ipairs() do
        if component:is_selected( x, y ) then
            return component, k
        end
    end
    return nil
end

---TODO
--TODO
--@param self TODO
--@param cr TODO
--@return TODO
--@see ScadaComponent.Base:render
function ScadaPlant:render( cr )
    local max_x, max_y = 200,200
    for k, component in self.component:ipairs() do
        local x, y = component:render( cr )
        if max_x < x then max_x = x end
        if max_y < y then max_y = y end
    end
    return max_x, max_y
end

---TODO
--TODO
--@param self TODO
--@param element_list TODO
--@return TODO
--@see AutomataGroup:load_automata
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

---Serializes the scada plant, so it can be saved.
--TODO
--@param self Scada plant to be serialized.
--@return Serialized scada plant.
--@see ScadaComponent.Base:dump
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

local FILE_ERRORS = {}
FILE_ERRORS.ACCESS_DENIED     = 1
FILE_ERRORS.NO_FILE_NAME      = 2
FILE_ERRORS.INVALID_FILE_TYPE = 3

---Saves the scada plant in its current file.
--TODO
--@param self Scada plant to be saved.
--@return True if no problems occurred, false otherwise.
--@return Ids of any errors that occurred.
--@see ScadaPlant:save_serialize
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
        return false, FILE_ERRORS.ACCESS_DENIED, FILE_ERRORS
    elseif not file_type then
        return false, FILE_ERRORS.NO_FILE_NAME, FILE_ERRORS
    else
        return false, FILE_ERRORS.INVALID_FILE_TYPE, FILE_ERRORS
    end
end

---Saves the scada plant to a file.
--TODO
--@param self Scada plant to be saved.
--@param file_name Name of the file where the scada plant will be saved.
--@return True if no problems occurred, false otherwise.
--@return Ids of any errors that occurred.
--@see ScadaPlant:save_serialize
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
        return false, FILE_ERRORS.ACCESS_DENIED, FILE_ERRORS
    else
        return false, FILE_ERRORS.NO_FILE_NAME, FILE_ERRORS
    end
end

---Loads the scada plant from a file.
--TODO
--@param self Scada plant where informations will be loaded.
--@param file_name Name of the file to be loaded.
--@param elements TODO
--@see ScadaPlant:add_component
--@see ScadaComponent.Base:charge
--@see ScadaPlant:load_automata_group
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
