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
module "ScadaComponent.Sensor"
--]]
ScadaComponent.Sensor = letk.Class( function( self )
    ScadaComponent.Base.__super( self )
end, ScadaComponent.Base )

ScadaComponent.Sensor:init_properties{
    ['caption']        = { type = 'string'   , caption = "Caption"        , default = 'S1'   , private = false },
    ['color']          = { type = 'color'    , caption = "Color"          , default = '#AAA' , private = false },
    ['active_color']   = { type = 'color'    , caption = "Active Color"   , default = '#0A0' , private = false },
    ['deactive_color'] = { type = 'color'    , caption = "Deactive Color" , default = '#F00' , private = false },
    ['active']         = { type = 'integer'  , caption = "Active"         , default = 0      , private = false, min = 0, max = 1 },
    ['orientation']    = { type = 'combobox' , caption = "Orientation"    , default = 1      , private = false, values = {"East", "South", "West", "North"} },
}
ScadaComponent.Sensor.final_component = true
ScadaComponent.Sensor.caption         = "Sensor"
ScadaComponent.Sensor.icon            = 'res/scada/images/sensor.png'
ScadaComponent.Sensor:change_properties{
    ['w']              = { default = 48 },
    ['h']              = { default = 32 },
}

---TODO
--TODO
--@param self TODO
--@param cr TODO
--@return TODO
--@see ScadaComponent.Base:get_property
--@see ScadaComponent.Base:translate_color
--@see ScadaComponent.Base:write_text
function ScadaComponent.Sensor:render( cr )
    local x, y               = self:get_property( 'x' ), self:get_property( 'y' )
    local w, h               = self:get_property( 'w' ), self:get_property( 'h' )
    local caption            = self:get_property( 'caption' )
    local radius             = h/4 
    local center_x, center_y 
    local s_rad, e_rad
    local color              = self:translate_color( self:get_property( 'color' ) )
    local active_color       = self:translate_color( self:get_property( 'active_color' ) )
    local deactive_color     = self:translate_color( self:get_property( 'deactive_color' ) )
    local active             = self:get_property( 'active' )
    local orientation        = self:get_property( 'orientation' )

    cr:set_source_rgba( color[1], color[2], color[3], 1 )
    cr:rectangle( x, y, w, h )
    cr:fill()
    
    cr:set_source_rgba( 0, 0, 0, 1 )
    cr:rectangle( x, y, w, h )
    cr:stroke()
    
    if active == 1 then
        cr:set_source_rgba( active_color[1], active_color[2], active_color[3], 1 )
    else
        cr:set_source_rgba( deactive_color[1], deactive_color[2], deactive_color[3], 1 )
    end
    if orientation == 1 then
        center_x = x + w
        center_y = y + h/2
        s_rad = math.pi/2
        e_rad = 3*math.pi/2
    elseif orientation == 2 then
        center_x = x + w/2
        center_y = y + h
        s_rad = math.pi
        e_rad = 2*math.pi
    elseif orientation == 3 then
        center_x = x
        center_y = y + h/2
        s_rad = 3*math.pi/2
        e_rad = math.pi/2
    elseif orientation == 4 then
        center_x = x + w/2
        center_y = y
        s_rad = 0
        e_rad = math.pi
    end
    cr:arc( center_x, center_y, radius, s_rad, e_rad )
    cr:fill()
    
    self:write_text( cr, x+(w/2), y+(h/2), caption, 12, {0,0,0} )
    
    return x+w, y+h
end

---TODO
--TODO
--@param self TODO
--@param x TODO
--@param y TODO
--@return TODO
--@see ScadaComponent.Base:get_property
function ScadaComponent.Sensor:is_selected( x, y )
    local px, py = self:get_property( 'x' ), self:get_property( 'y' )
    local w, h   = self:get_property( 'w' ), self:get_property( 'h' )
    
    if x >= px and x <= (px+w) and y >= py and y <= (py+h) then
        return true
    end
    
    return false
end
