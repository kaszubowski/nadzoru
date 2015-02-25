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
module "ScadaComponent.Buffer"
--]]
ScadaComponent.Buffer = letk.Class( function( self )
    ScadaComponent.Base.__super( self )
end, ScadaComponent.Base )

ScadaComponent.Buffer:init_properties{
    ['capacity']           = { type = 'integer'  , caption = "Capacity"   , default = 1      , private = false, min=1 },
    ['items']              = { type = 'integer'  , caption = "Items"      , default = 0      , private = false, min=0, max = 'capacity' },
    ['color']              = { type = 'color'    , caption = "Color"      , default = '#AAA' , private = false },
    ['fontcolor']          = { type = 'color'    , caption = "Font Color" , default = '#222' , private = false },
}
ScadaComponent.Buffer.final_component = true
ScadaComponent.Buffer.caption         = "Buffer"
ScadaComponent.Buffer.icon            = 'res/scada/images/buffer.png'
ScadaComponent.Buffer:change_properties{
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
function ScadaComponent.Buffer:render( cr )
    local x, y       = self:get_property( 'x' ), self:get_property( 'y' )
    local w, h       = self:get_property( 'w' ), self:get_property( 'h' )
    local color      = self:translate_color( self:get_property( 'color' ) )
    local fontcolor  = self:translate_color( self:get_property( 'fontcolor' ) )
    local items      = self:get_property( 'items' )
    local capacity   = self:get_property( 'capacity' )
    
    cr:set_source_rgba( color[1], color[2], color[3], 1 )
    cr:rectangle( x, y, w, h)
    cr:fill()
    
    cr:set_source_rgba( 0, 0, 0, 1 )
    cr:rectangle( x, y, w, h)
    cr:stroke()
    
    self:write_text( cr, x+(w/2), y+(h/2), items .. "/" .. capacity, 16, fontcolor )
    
    return x+w, y+h
end

---TODO
--TODO
--@param self TODO
--@param x TODO
--@param y TODO
--@return TODO
--@see ScadaComponent.Base:get_property
function ScadaComponent.Buffer:is_selected( x, y )
    local px, py = self:get_property( 'x' ), self:get_property( 'y' )
    local w, h   = self:get_property( 'w' ), self:get_property( 'h' )
    
    if x >= px and x <= (px+w) and y >= py and y <= (py+h) then
        return true
    end
    
    return false
end
