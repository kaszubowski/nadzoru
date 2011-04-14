Models    = {}
Primitives    = {}

Models.Base = {}
Models.Base_MT = { __index = Models.Base }

Primitives.block = {}
Primitives.block_MT = { __index = Primitives.block }

function Primitives.block.new( param )
    param = type(param) == 'table' and param or {}
    local self  = {}
    self.dim_x     = param.dim_x  or 1
    self.dim_y     = param.dim_y or 1
    self.dim_z     = param.dim_z or 1
    self.pos_x     = param.pos_x  or 1
    self.pos_y     = param.pos_y or 1
    self.pos_z     = param.pos_z or 1
    self.color_r   = param.color_r or 0.5
    self.color_g   = param.color_g or 0.5
    self.color_b   = param.color_b or 0.5
end

function Primitives.block:render()
    gl.Begin(gl.QUADS)
        gl.Color( self.color_r, self.color_g, self.color_b )

    gl.End
end


require'res.models.esteira'
