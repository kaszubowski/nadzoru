--[[
@module ScriptEnv

--]]
ScriptEnv = letk.Class( function( self, elements )
    Object.__super( self )

    self.elements = elements
end, Object )

ScriptEnv.Export = {}
ScriptEnv.Export.Automaton      = {}
ScriptEnv.Export.Automaton.supC = {'supc'}
ScriptEnv.Export.Automaton.univocal = {'univocal'}
ScriptEnv.Export.Automaton.accessible = {'accessible', 'ac'}
ScriptEnv.Export.Automaton.coaccessible = {'coaccessible', 'co'}
ScriptEnv.Export.Automaton.complement = {'complement'}
ScriptEnv.Export.Automaton.minimize = {'minimize', 'minimise'}
ScriptEnv.Export.Automaton.deterministic = {'deterministic', 'det'}
ScriptEnv.Export.Automaton.product = {'product', 'prod'}
ScriptEnv.Export.Automaton.projection = {'projection','proj'}
ScriptEnv.Export.Automaton.selfloop = {'selfloop'}
ScriptEnv.Export.Automaton.synchronization = {'synchronization', 'sync'}
ScriptEnv.Export.Automaton.trim = {'trim'}


function ScriptEnv:loadFnEnv()
    self.fnEnv  = {}
    for className, classDef in pairs( ScriptEnv.Export ) do
        local class = _G[ className ]
        for methodName, envFnNames in pairs( classDef ) do
            local method = class[ methodName ]
            local fn = function( ... )
                return method( ... )
            end
            for k_envFnName, envFnName in ipairs( envFnNames ) do
                self.fnEnv[ envFnName ] = fn
            end
        end
    end

    function self.fnEnv.save( el, name )
        if name then
            el:set('file_name', name .. '.nza')
        else
            for envName, envEl in pairs( self.env ) do
                if envEl == el then
                    el:set('file_name', envName .. '.nza')
                    break
                end
            end
        end
        return self.elements:append( el )
    end
end

--~ function ScriptEnv:loadEnv( autoSave ) --newindex save ?
function ScriptEnv:loadEnv()
    self.env    = {}
    for k_el, el in self.elements:ipairs()  do
        local elName = el:get('file_name'):match('([^%.]*).-')
        self.env[ elName ] = el
    end

    return setmetatable( self.env, { __index=self.fnEnv } )
end

function ScriptEnv:execScript( script )
    if not self.fnEnv then self:loadFnEnv() end
    if not self.enf then self:loadEnv() end
    local f = loadstring( script )
    setfenv( f, self.env )
    return pcall( f )
end

function ScriptEnv:get( name )
    return env[ name ]
end
