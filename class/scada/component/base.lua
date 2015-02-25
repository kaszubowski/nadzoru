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
module "ScadaComponent.Base"
--]]
ScadaComponent.Base = letk.Class( function( self )
    Object.__super( self )

    self.properties_values = {}
end, Object )

local function copy_properties( self, t )
    for i = #t.__parents, 1, -1 do
        local parent = t.__parents[i]
        copy_properties( self, parent )
        if parent.properties then
            for property, t in pairs( parent.properties ) do
                self.properties[ property ] = {}
                for key, value in pairs( t ) do
                    self.properties[ property ][ key ] = value
                end
            end
        end
    end
end

---TODO
--TODO
--@param self TODO
--@param properties TODO
function ScadaComponent.Base:init_properties( properties )
    self.properties = {}
    copy_properties( self, self )
    for property, info in pairs( properties ) do
        if type(info) == 'boolean' and info == false then
            self.properties[ property ] = nil --remove inherited properties
        else
            self.properties[ property ] = info
        end
    end
end

---TODO
--TODO
--@param self TODO
--@param changes TODO
function ScadaComponent.Base:change_properties( changes )
    changes = changes or {}
    for propertie, values in pairs( changes ) do
        if self.properties then
            for key, value in pairs( values ) do
                self.properties[ propertie ][ key ] = value
            end
        end
    end
end

local default_onupdate_code = [[
function onupdate( self, event, dfa_sim_list )
    --Your code here--
    
end
]]

ScadaComponent.Base:init_properties{
        ['x']        = { type = 'integer', caption = "Position x", default = 0   , private = false, min=0 },
        ['y']        = { type = 'integer', caption = "Position y", default = 0   , private = false, min=0 },
        ['w']        = { type = 'integer', caption = "Width"     , default = 128 , private = false },
        ['h']        = { type = 'integer', caption = "Height"    , default = 128 , private = false },
        ['onupdate'] = { type = 'code'   , caption = "On Update" , default = default_onupdate_code  , private = false, help = true },
    }
ScadaComponent.Base.final_component = false
ScadaComponent.Base.caption         = "Base"
ScadaComponent.Base.icon            = 'res/scada/images/base.png'

---TODO
--TODO
--@param self TODO
--@param cr TODO
--@return TODO
--@see ScadaComponent.Base:get_property
function ScadaComponent.Base:render( cr )
    local image  = cairo.ImageSurface.create_from_png('res/scada/images/no_image.png')
    local ow, oh = image:get_width(), image:get_height()
    local w      = self:get_property( 'w' )
    local h      = self:get_property( 'h' )
    local x      = self:get_property( 'x' )
    local y      = self:get_property( 'y' )
    local rw, rh = w/ow, h/oh
    local surface = cairo.ImageSurface.create(cairo.FORMAT_ARGB32, ow, oh )
    local ic      = cairo.Context.create(surface)
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
--@param x TODO
--@param y TODO
--@return TODO
--@see ScadaComponent.Base:get_property
function ScadaComponent.Base:is_selected( x, y )
    local px     = self:get_property( 'x' )
    local py     = self:get_property( 'y' )
    local pw     = self:get_property( 'w' )
    local ph     = self:get_property( 'h' )
    if x >= px and x <= (px+pw) and y >= py and y <= (py+ph) then
        return true
    end
    return false
end

---TODO
--TODO
--@param self TODO
--@param key TODO
--@param value TODO
--@see ScadaComponent.Base:get_property
function ScadaComponent.Base:set_property( key, value )
    if self.properties[ key ] then
        if self.properties[ key ].type == 'number' or self.properties[ key ].type == 'integer' then
            self.properties_values[ key ] = tonumber(value)
            if self.properties[ key ].min and type( self.properties[ key ].min ) == 'number' and self.properties_values[ key ] < self.properties[ key ].min then
                self.properties_values[ key ] = self.properties[ key ].min
            end
            if self.properties[ key ].min and type( self.properties[ key ].min ) == 'string' then
                local min_val = self:get_property( self.properties[ key ].min )
                if self.properties_values[ key ] < min_val then
                    self.properties_values[ key ] = min_val
                end
            end
            if self.properties[ key ].max and type( self.properties[ key ].max ) == 'number' and self.properties_values[ key ] > self.properties[ key ].max then
                self.properties_values[ key ] = self.properties[ key ].max
            end
            if self.properties[ key ].max and type( self.properties[ key ].max ) == 'string' then
                local max_val = self:get_property( self.properties[ key ].max )
                if self.properties_values[ key ] > max_val then
                    self.properties_values[ key ] = max_val
                end
            end
        elseif self.properties[ key ].type == 'string' or self.properties[ key ].type == 'code' then
            self.properties_values[ key ] = tostring(value)
        elseif self.properties[ key ].type == 'combobox' then
            self.properties_values[ key ] = tonumber( value )
        elseif self.properties[ key ].type == 'color' then
            self.properties_values[ key ] = value
        elseif self.properties[ key ].type == 'boolean' then
            self.properties_values[ key ] = value
        end
    end
end

---TODO
--TODO
--@param self TODO
--@param key TODO
--@return TODO
function ScadaComponent.Base:get_property( key )
    if self.properties[ key ] then
        return self.properties_values[ key ] or self.properties[ key ].default
    end
end

---TODO
--TODO
--@param self TODO
--@return TODO
function ScadaComponent.Base:dump()
    local component = {
        properties = {},
    }

    for k,v in pairs( self.properties_values ) do
        component.properties[ k ] = v
    end

    local self_class = getmetatable( self )
    for cmp_name, cmp_class in pairs( ScadaComponent ) do
        if self_class == cmp_class then
        component.name = cmp_name
        end
    end

    return component
end

---TODO
--TODO
--@param self TODO
--@param component TODO
--@see ScadaComponent.Base:set_property
function ScadaComponent.Base:charge( component )
    for k,v in pairs( component.properties ) do
        self:set_property( k, v )
    end
end

---TODO
--TODO
--@param self TODO
--@param scolor TODO
--@return TODO
function ScadaComponent.Base:translate_color( scolor )
    local color  = {0,0,0}
    local cdigits = (#scolor - 1)/3
    for i = 1,3 do
        color[i] = tonumber( '0x' .. scolor:sub(2 + (i-1)*cdigits, 1+i*cdigits) ) / ( 16^cdigits )
    end
    
    return color
end

---TODO
--TODO
--@param self TODO
--@param cr TODO
--@param x TODO
--@param y TODO
--@param text TODO
--@param font TODO
--@param color TODO
--@return TODO
function ScadaComponent.Base:write_text(cr,x,y,text,font,color)
    color = color or { 0,0,0 }
    cr:select_font_face("sans", cairo.FONT_SLANT_OBLIQUE)
    cr:set_font_size(font)
    local txt_ext = cairo.TextExtents.create( )
    cr:text_extents( text or "", txt_ext )
    local x_bearing, y_bearing, txt_width, txt_height, x_advance, y_advance = txt_ext:get()
    txt_ext:destroy()
    cr:move_to( x -(txt_width/2), y + (txt_height/2) )
    --~ cr:rotate()
    cr:set_source_rgb(color[1], color[2], color[3])
    cr:show_text( text or "" )
    cr:stroke()
    return (txt_width/2), (txt_height/2), x -(txt_width/2), y + (txt_height/2)
end

---TODO
--Unfinished. TODO
--@param self TODO
function ScadaComponent.Base:tick() --Maybe it is abstract.

end

---TODO
--Unfinished. TODO
--@param self TODO
function ScadaComponent.Base:click() --Maybe it is abstract.

end
