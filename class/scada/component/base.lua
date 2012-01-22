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

function ScadaComponent.Base:init_properties( properties )
    self.properties = {}
    copy_properties( self, self )
    for property, info in pairs( properties ) do
        self.properties[ property ] = info
    end
end

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

ScadaComponent.Base:init_properties{
        ['x']        = { type = 'integer', caption = "Position x", default = 0   , private = false, min=0 },
        ['y']        = { type = 'integer', caption = "Position y", default = 0   , private = false, min=0 },
        ['w']        = { type = 'integer', caption = "Width"     , default = 128 , private = false },
        ['h']        = { type = 'integer', caption = "Height"    , default = 128 , private = false },
        ['onupdate'] = { type = 'code'  , caption = "On Update" , default = ''  , private = false },
    }
ScadaComponent.Base.final_component = false
ScadaComponent.Base.caption         = "Base"
ScadaComponent.Base.icon            = 'res/scada/images/base.png'

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
    cr:scale( rw, rh )
    ic:rectangle(0, 0, ow, oh )
    ic:fill()
    cr:set_source_surface( image, x/rw,y/rh )
    cr:mask_surface( surface, x/rw, y/rh )
    cr:identity_matrix()
    ic:destroy()
    surface:destroy()
    image:destroy()
end

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

function ScadaComponent.Base:set_property( key, value )
    if self.properties[ key ] then
        if self.properties[ key ].type == 'number' or self.properties[ key ].type == 'integer' then
            self.properties_values[ key ] = tonumber(value)
            if self.properties[ key ].min and self.properties_values[ key ] < self.properties[ key ].min then
                self.properties_values[ key ] = self.properties[ key ].min
            end
            if self.properties[ key ].max and self.properties_values[ key ] > self.properties[ key ].max then
                self.properties_values[ key ] = self.properties[ key ].max
            end
        elseif self.properties[ key ].type == 'string' then
            self.properties_values[ key ] = tostring(value)
        end
    end
end

function ScadaComponent.Base:get_property( key )
    if self.properties[ key ] then
        return self.properties_values[ key ] or self.properties[ key ].default
    end
end

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

function ScadaComponent.Base:charge( component )
    for k,v in pairs( component.properties ) do
        self:set_property( k, v )
    end
end
