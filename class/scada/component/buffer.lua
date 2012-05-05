ScadaComponent.Buffer = letk.Class( function( self )
    ScadaComponent.Base.__super( self )
end, ScadaComponent.Base )

ScadaComponent.Buffer:init_properties{
    ['capacity']           = { type = 'integer'  , caption = "Capacity"   , default = 1      , private = false, min=1 },
    ['itens']              = { type = 'integer'  , caption = "Itens"      , default = 0      , private = false, min=0, max = 'capacity' },
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

function ScadaComponent.Buffer:render( cr )
    local x, y       = self:get_property( 'x' ), self:get_property( 'y' )
    local w, h       = self:get_property( 'w' ), self:get_property( 'h' )
    local color      = self:translate_color( self:get_property( 'color' ) )
    local fontcolor  = self:translate_color( self:get_property( 'fontcolor' ) )
    local itens      = self:get_property( 'itens' )
    local capacity   = self:get_property( 'capacity' )
    
    cr:set_source_rgba( color[1], color[2], color[3], 1 )
    cr:rectangle( x, y, w, h)
    cr:fill()
    
    cr:set_source_rgba( 0, 0, 0, 1 )
    cr:rectangle( x, y, w, h)
    cr:stroke()
    
    self:write_text( cr, x+(w/2), y+(h/2), itens .. "/" .. capacity, 16, fontcolor )
    
    return x+w, y+h
end

function ScadaComponent.Buffer:is_selected( x, y )
    local px, py = self:get_property( 'x' ), self:get_property( 'y' )
    local w, h   = self:get_property( 'w' ), self:get_property( 'h' )
    
    if x >= px and x <= (px+w) and y >= py and y <= (py+h) then
        return true
    end
    
    return false
end
