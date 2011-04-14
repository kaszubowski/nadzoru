GLRender = {}
GLRender_MT = { __index = GLRender }

setmetatable( GLRender, Object_MT )

function GLRender.new( draw )
    local self     = Object.new()
    setmetatable( self, GLRender_MT )
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

    return self
end

function GLRender:set_render_callback( fn )
    self.render_callback = fn
end

function GLRender:configure()
    local context       = gtkglext.Widget.get_gl_context(self.draw)
    local drawable      = gtkglext.Widget.get_gl_drawable(self.draw)
    local width, height = self.draw:get_size()

    drawable:gl_begin( context )

    gl.LoadIdentity();
    gl.Viewport (0, 0, width, height);
    gl.Enable (gl.BLEND);
    gl.BlendFunc (gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    drawable:gl_end()

    return true

end

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
