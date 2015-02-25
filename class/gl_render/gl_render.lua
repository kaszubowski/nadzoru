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
module "GLRender"
--]]
GLRender = letk.Class( function( self, draw )
    self.draw = draw

    self.glconfig = gtkglext.Config.new_by_mode(
        gtkglext.MODE_RGB +
        gtkglext.MODE_DOUBLE +
        gtkglext.MODE_DEPTH
    )
    gtkglext.Widget.set_gl_capability( draw, self.glconfig, true, gtkglext.MODE_RGB)

    --CallBacks
     self.draw:connect("configure-event", self.configure, self )
     self.draw:connect("expose-event", self.expose, self )
end, Object )

---TODO
--TODO
--@param self TODO
--@param fn TODO
function GLRender:set_render_callback( fn )
    self.render_callback = fn
end

---TODO
--TODO
--@param self TODO
--@return Always true.
function GLRender:configure()
    local context       = gtkglext.Widget.get_gl_context(self.draw)
    local drawable      = gtkglext.Widget.get_gl_drawable(self.draw)
    local width, height = self.draw:get_size()

    drawable:gl_begin( context )

    gl.LoadIdentity();
    gl.Viewport (0, 0, width, height);
    gl.Enable (gl.BLEND);
    gl.BlendFunc (gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    --~ drawable:gl_end()

    return true

end

---TODO
--TODO
--@param self TODO
function GLRender:expose()
    local context  = gtkglext.Widget.get_gl_context(self.draw)
    local drawable = gtkglext.Widget.get_gl_drawable(self.draw)

    drawable:gl_begin( context )
    gl.Clear(gl.COLOR_BUFFER_BIT + gl.DEPTH_BUFFER_BIT)
    gl.PushMatrix()
    gl.ShadeModel(gl.FLAT)

    if type(self.render_callback) == 'function' then
        self:render_callback()
    end

    gl.PopMatrix()
    drawable:swap_buffers()
    drawable:gl_end()

end
