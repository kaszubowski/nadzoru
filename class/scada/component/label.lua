ScadaComponent.Label = letk.Class( function( self )
    ScadaComponent.Base.__super( self )
end, ScadaComponent.Base )

ScadaComponent.Label:init_properties{
    ['caption']     = { type = 'string'   , caption = "Caption"      , default = 'M1'   , private = false },
    ['fontsize']    = { type = 'integer'  , caption = "Font Size"    , default = 10     , private = false, min = 6, max = 42 },
    ['background']  = { type = 'boolean'  , caption = "Background"   , default = false  , private = false },
    ['border']      = { type = 'boolean'  , caption = "Border"       , default = false  , private = false },
    ['color']       = { type = 'color'    , caption = "Color"        , default = '#AAA' , private = false },
    ['fontcolor']   = { type = 'color'    , caption = "Font Color"   , default = '#000' , private = false },
}
ScadaComponent.Label.final_component = true
ScadaComponent.Label.caption         = "Label"
ScadaComponent.Label.icon            = 'res/scada/images/label.png'
ScadaComponent.Label:change_properties{
    ['w']              = { default = 48 },
    ['h']              = { default = 48 },
}

function ScadaComponent.Label:render( cr )
    local x, y       = self:get_property( 'x' ), self:get_property( 'y' )
    local w, h       = self:get_property( 'w' ), self:get_property( 'h' )
    local caption    = self:get_property( 'caption' )
    local fontsize   = self:get_property( 'fontsize' )
    local background = self:get_property( 'background' )
    local border     = self:get_property( 'border' )
    local color      = self:translate_color( self:get_property( 'color' ) )
    local fontcolor  = self:translate_color( self:get_property( 'fontcolor' ) )
    
    if background then
        cr:set_source_rgba( color[1], color[2], color[3], 1 )
        cr:rectangle( x, y, w, h )
        cr:fill()
    end
    
    if border then
        cr:set_source_rgba( 0, 0, 0, 1 )
        cr:rectangle( x, y, w, h )
        cr:stroke()
    end
    
    self:write_text( cr, x+(w/2), y+(h/2), caption, fontsize, fontcolor )
    
    return x+w/2, y+h/2
end

function ScadaComponent.Label:is_selected( x, y )
    local px, py = self:get_property( 'x' ), self:get_property( 'y' )
    local w, h   = self:get_property( 'w' ), self:get_property( 'h' )
    
    if x >= px and x <= (px+w) and y >= py and y <= (py+h) then
        return true
    end
    
    return false
end
