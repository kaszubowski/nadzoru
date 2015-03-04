--[[
@module ScriptEnv

--]]
ScriptEnv = letk.Class( function( self, elements )
    Object.__super( self )

    self.elements = elements
    self.print    = print
    self.printObj = nil
end, Object )

ScriptEnv.Export = {}
ScriptEnv.Export.Automaton      = {}
ScriptEnv.Export.Automaton.supC = {'supc'}
ScriptEnv.Export.Automaton.univocal = {'univocal'}
ScriptEnv.Export.Automaton.accessible = {'accessible'}
ScriptEnv.Export.Automaton.coaccessible = {'coaccessible'}
--~ ScriptEnv.Export.Automaton.complement = {'complement'}
--~ ScriptEnv.Export.Automaton.minimize = {'minimize'}
--~ ScriptEnv.Export.Automaton.deterministic = {'deterministic'}
ScriptEnv.Export.Automaton.product = {'product', 'prod'}
--~ ScriptEnv.Export.Automaton.projection = {'projection'}
ScriptEnv.Export.Automaton.selfloop = {'selfloop'}
ScriptEnv.Export.Automaton.synchronization = {'synchronization', 'sync'}
ScriptEnv.Export.Automaton.trim = {'trim'}
ScriptEnv.Export.Automaton.save_as = {'save'}
ScriptEnv.Export.Automaton.infoString = {'info'}

function ScriptEnv:setPrintCallback( fn, object )
    self.print    = fn
    self.printObj = object
end

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

    function self.fnEnv.export( el, name )
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

    function self.fnEnv.print( ... )
        if self.printObj then
            self.print( self.printObj, ... )
        else
            self.print( ... )
        end
    end
end

--~ function ScriptEnv:loadEnv( autoSave ) --newindex save ?
function ScriptEnv:loadEnv()
    self.env    = {}
    for k_el, el in self.elements:ipairs()  do
        --~ local elName = el:get('file_name'):match('([^%.]*).-')
        local elName = el:getName()
        self.env[ elName ] = el
    end

    local function newIndexFn( t, key, value )
        value:set('file_name', key .. '.nza') --UPDATE defClassExtension -- ElementClass arch
        rawset(t, key, value)
    end

    return setmetatable( self.env, { __index=self.fnEnv, __newindex=newIndexFn } )
end

function ScriptEnv:execScript( script, printErrors )
    if not self.fnEnv then self:loadFnEnv() end
    if not self.enf then self:loadEnv() end
    local f, loadErr = loadstring( script )
    if f then
        setfenv( f, self.env )
        local status, errMsg = pcall( f )
        if not status and printErrors then
            if self.printObj then
                self.print( self.printObj, errMsg )
            else
                self.print( errMsg )
            end
        end
        return status, errMsg
    elseif printErrors then
        if self.printObj then
            self.print( self.printObj, loadErr )
        else
            self.print( loadErr )
        end
    end
end

function ScriptEnv:get( name )
    return env[ name ]
end
