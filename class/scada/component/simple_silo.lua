ScadaComponent.SimpleSilo = letk.Class( function( self )
    ScadaComponent.Base.__super( self )
end, ScadaComponent.Base )

ScadaComponent.SimpleSilo:init_properties{
    ['state'] = { type = 'number', caption = "State", default = 1   , private = false, min=1, max=5 },
}
ScadaComponent.SimpleSilo.final_component = true
ScadaComponent.SimpleSilo.caption         = "Simple Silo"
ScadaComponent.SimpleSilo.icon            = 'res/scada/images/silo.png'
ScadaComponent.SimpleSilo:change_properties{
    ['w']              = { default = 64 },
}

function ScadaComponent.SimpleSilo:render( cr )
    local state_image = { 'silo_0','silo_1','silo_2','silo_3','silo_4' }
    local image_file  = 'res/scada/images/' .. state_image[ self:get_property( 'state' ) ] .. '.png'
    local image       = cairo.ImageSurface.create_from_png( image_file )
    local ow, oh      = image:get_width(), image:get_height()
    local w           = self:get_property( 'w' )
    local h           = self:get_property( 'h' )
    local x           = self:get_property( 'x' )
    local y           = self:get_property( 'y' )
    local rw, rh      = w/ow, h/oh
    local surface     = cairo.ImageSurface.create(cairo.FORMAT_ARGB32, ow, oh )
    local ic          = cairo.Context.create(surface)
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
