local NCompact = require'class.ncompact'

ScadaComponentLibrary = letk.Class( function( self )
    self.lib_file      = NCompact.new()
    self.componets     = letk.List.new()
end )

function ScadaComponentLibrary:add_resource( path, file_name )
    if path == 'lib' then return end
    self.lib_file:read_file( path, file_name )
end

function ScadaComponentLibrary:save()

end
