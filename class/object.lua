Object  = letk.Class( function( self )
    self.triggers = {}
end )

function Object:trigger(event, ... )
    if self.triggers[event] then
        for ch_fn, fn in ipairs( self.triggers[event] ) do
            if fn.param then
                fn.fn( self, fn.param, ... )
            else
                fn.fn( self, ... )
            end
        end
    end
end

function Object:bind( event, fn, param )
    self.triggers[event] = self.triggers[event] or {}
    self.triggers[event][ #self.triggers[event] + 1 ] = { fn = fn, param = param }
end

function Object:unbind( event )
    self.triggers[event] = nil
end

function Object:set( k, v )
    self.properties = self.properties or {}
    self.properties[ k ] = v
end

function Object:get( k )
    return self.properties and self.properties[ k ]
end
