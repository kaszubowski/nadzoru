ScadaBlocks = letk.Class( function( self )
    self.type = nil
end )

function ScadaBlocks:get( k )
    return self.properties[ k ]
end

function ScadaBlocks:set( k, v )
    self.properties[ k ] = v
end

function ScadaBlocks:render( cr )

end

------------------------------------------------------------------------

ScadaBlocksFigure = letk.Class( function( self, args )
    args = args or {}
    if not args.path or not fs then return end
    if fs:write_file( args.path, './temp.png' ) then
        self.image = cairo.ImageSurface.create_from_png( './temp.png' )
    end
    self.properties = {}
    self.properties.x         = args.x or 0
    self.properties.y         = args.y or 0
    self.properties.width     = args.width or 32
    self.properties.height    = args.height or 32
end, ScadaBlocks)

function ScadaBlocksFigure:render( cr )
    if self.image then
        local surface = cairo.ImageSurface.create(cairo.FORMAT_ARGB32, iWidth, iHeight)
        local ic      = cairo.Context.create(surface)
        ic:rectangle(0, 0, self.properties.width, self.properties.height)
        ic:fill()

        cr:set_source_surface(self.image, 10, 10)
        cr:mask_surface(surface, 10, 10)
        surface:destroy()
        ic:destroy()
    end
end

return {
    figure = { "Figure", ScadaBlocksFigure },
}
