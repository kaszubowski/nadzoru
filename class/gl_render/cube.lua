GLRenderCube = {}
GLRenderCube_MT = { __index = GLRenderCube }

setmetatable( GLRenderCube, Object_MT )

function GLRenderCube.new( args )
    args = args or {}
end

function GLRenderCube:render()

end
