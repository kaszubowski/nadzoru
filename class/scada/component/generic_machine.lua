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
module "ScadaComponent.GenericMachine"
--]]
ScadaComponent.GenericMachine = letk.Class( function( self )
    ScadaComponent.Base.__super( self )
end, ScadaComponent.Base )

ScadaComponent.GenericMachine:init_properties{
    ['caption']     = { type = 'string'   , caption = "Caption"      , default = 'M1'   , private = false },
    ['color']       = { type = 'color'    , caption = "Color"        , default = '#AAA' , private = false },
    ['statuscolor'] = { type = 'color'    , caption = "Status Color" , default = '#0A0' , private = false },
}
ScadaComponent.GenericMachine.final_component = true
ScadaComponent.GenericMachine.caption         = "Generic Machine"
ScadaComponent.GenericMachine.icon            = 'res/scada/images/generic_machine.png'
ScadaComponent.GenericMachine:change_properties{
    ['w']              = { default = 48 },
    ['h']              = { default = 48 },
}

---TODO
--TODO
--@param self TODO
--@param cr TODO
--@return TODO
--@see ScadaComponent.Base:get_property
--@see ScadaComponent.Base:translate_color
--@see ScadaComponent.Base:write_text
function ScadaComponent.GenericMachine:render( cr )
    local x, y               = self:get_property( 'x' ), self:get_property( 'y' )
    local w, h               = self:get_property( 'w' ), self:get_property( 'h' )
    local caption            = self:get_property( 'caption' )
    local status_w, status_h = w/5, h/5
    local color      = self:translate_color( self:get_property( 'color' ) )
    local statuscolor  = self:translate_color( self:get_property( 'statuscolor' ) )
    
    cr:set_source_rgba( color[1], color[2], color[3], 1 )
    cr:rectangle( x, y, w, h )
    cr:fill()
    
    cr:set_source_rgba( 0, 0, 0, 1 )
    cr:rectangle( x, y, w, h )
    cr:stroke()
    
    cr:set_source_rgba( statuscolor[1], statuscolor[2], statuscolor[3], 0.85 )
    cr:rectangle( x+3*status_w, y+status_h, status_w, status_h)
    cr:fill()
    
    self:write_text( cr, x+(w/2), y+(2*h/3), caption, 12, {0,0,0} )
    
    return x+w, y+h    
end

---TODO
--TODO
--@param self TODO
--@param x TODO
--@param y TODO
--@return TODO
--@see ScadaComponent.Base:get_property
function ScadaComponent.GenericMachine:is_selected( x, y )
    local px, py = self:get_property( 'x' ), self:get_property( 'y' )
    local w, h   = self:get_property( 'w' ), self:get_property( 'h' )
    
    if x >= px and x <= (px+w) and y >= py and y <= (py+h) then
        return true
    end
    
    return false
end
