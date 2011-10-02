Object         = {}
Object.__index = Object

function Object.new( )
    local self = {}
    setmetatable( self, Object )

    self.triggers = {}

    return self
end

function Object:trigger(event)
    if self.triggers[event] then
        for ch_fn, fn in ipairs( self.triggers[event] ) do
            fn.fn( self, fn.param )
        end
    end
end

function Object:bind( event, fn, param )
    self.triggers[event] = self.triggers[event] or {}
    self.triggers[event][ #self.triggers[event] + 1 ] = { fn = fn, param = param }
end
