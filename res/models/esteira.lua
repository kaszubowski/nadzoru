Models.Esteira    = {}
Models.Esteira_MT = { __index = Models.Esteira }

setmetatable( Models.Esteira , Models.Base_MT )

function Models.Esteira.new()
    local self = {}
    setmetatable( self, Models.Esteira_MT )

    return self
end
