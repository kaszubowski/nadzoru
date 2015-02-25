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
module "Object"
--]]
Object  = letk.Class( function( self )
    self.triggers = {}
end )

---TODO
--TODO
--@param self TODO
--@param event TODO
--@param ... TODO
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

---TODO
--TODO
--@param self TODO
--@param event TODO
--@param fn TODO
--@param param TODO
function Object:bind( event, fn, param )
    self.triggers[event] = self.triggers[event] or {}
    self.triggers[event][ #self.triggers[event] + 1 ] = { fn = fn, param = param }
end

---TODO
--TODO
--@param self TODO
--@param event TODO
--@return TODO
function Object:unbind( event )
    self.triggers[event] = nil
end

---Changes the value of a property of the object.
--TODO
--@param self Object whose property is changed.
--@param k Property to be changed.
--@param v New value of the property.
function Object:set( k, v )
    self.properties = self.properties or {}
    self.properties[ k ] = v
end

---Returns the value of a property of the object.
--TODO
--@param self Object whose property is returned.
--@param k Property to be returned.
--@return Value of the property.
function Object:get( k )
    return self.properties and self.properties[ k ]
end
