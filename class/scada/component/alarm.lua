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
module "ScadaComponent.Alarm"
--]]
ScadaComponent.Alarm = letk.Class( function( self )
    ScadaComponent.Base.__super( self )
    self.alarmTick = 1
end, ScadaComponent.Base )

ScadaComponent.Alarm:init_properties{
    ['state'] = { type = 'integer', caption = "State", default = 1   , private = false, min=1, max=2 },
}
ScadaComponent.Alarm.final_component = true
ScadaComponent.Alarm.caption         = "Alarm"
ScadaComponent.Alarm.icon            = 'res/scada/images/alarm.png'
ScadaComponent.Alarm:change_properties{
    ['h']              = { default = 96 },
    ['w']              = { default = 96 },
}

---TODO
--TODO
--@param self TODO
--@param cr TODO
--@return TODO
--@see ScadaComponent.Base:get_property
function ScadaComponent.Alarm:render( cr )
    local image_file  = 'res/scada/images/alarm0.png'
    if  self:get_property( 'state' ) == 2 then
        if self.alarmTick == 2 then
            image_file  = 'res/scada/images/alarm1.png'
        end
        self.alarmTick = self.alarmTick == 1 and 2 or 1
    end
    local image       = cairo.ImageSurface.create_from_png( image_file )
    local ow, oh      = image:get_width(), image:get_height()
    local w           = self:get_property( 'w' )
    local h           = self:get_property( 'h' )
    local x           = self:get_property( 'x' )
    local y           = self:get_property( 'y' )
    local rw, rh      = w/ow, h/oh
    local surface     = cairo.ImageSurface.create(cairo.FORMAT_ARGB32, ow, oh )
    local ic          = cairo.Context.create(surface)
    cr:save()
        cr:scale( rw, rh )
        ic:rectangle(0, 0, ow, oh )
        ic:fill()
        cr:set_source_surface( image, x/rw,y/rh )
        cr:mask_surface( surface, x/rw, y/rh )
    cr:restore()
    ic:destroy()
    surface:destroy()
    image:destroy()
    
    return x+w, y+h
end

---TODO
--TODO
--@param self TODO
--@see ScadaComponent.Base:set_property
function ScadaComponent.Alarm:click()
    self:set_property( 'state', 1 )
end
