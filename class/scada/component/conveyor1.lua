ScadaComponent.Conveyor1 = letk.Class( function( self )
    ScadaComponent.Base.__super( self )
end, ScadaComponent.Base )

ScadaComponent.Conveyor1:init_properties{
    ['state'] = { type = 'integer', caption = "State", default = 1   , private = false, min=1, max=2 },
}
ScadaComponent.Conveyor1.final_component = true
ScadaComponent.Conveyor1.caption         = "Single Conveyor"
ScadaComponent.Conveyor1.icon            = 'res/scada/images/conveyor.png'
ScadaComponent.Conveyor1:change_properties{
    ['h']              = { default = 32 },
}

function ScadaComponent.Conveyor1:render( cr )
    local state_image = { 'conveyor_off','conveyor_on' }
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
