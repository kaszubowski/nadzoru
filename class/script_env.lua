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
ScriptEnv.Export.Automaton.supC = {'supc', params={ { "G", 'combobox', 'automaton' }, { "K", 'combobox', 'automaton' } }, description="Computes an automaton that accepts the supremal controllable sublanguage of the specification with respect to the given plant" }
ScriptEnv.Export.Automaton.univocal = {'univocal', params={ { "G", 'combobox', 'automaton' }, { "K", 'combobox', 'automaton' } } }
ScriptEnv.Export.Automaton.accessible = {'accessible', params={ { "Automaton", 'combobox', 'automaton' } } }
ScriptEnv.Export.Automaton.coaccessible = {'coaccessible', params={ { "Automaton", 'combobox', 'automaton' } } }
--~ ScriptEnv.Export.Automaton.complement = {'complement'}
ScriptEnv.Export.Automaton.minimize = {'minimize', params={ { "Automaton", 'combobox', 'automaton' } } }
--~ ScriptEnv.Export.Automaton.deterministic = {'deterministic'}
ScriptEnv.Export.Automaton.product = {'product', 'prod', params={ { "Automaton",'multiple','automaton' } } }
--~ ScriptEnv.Export.Automaton.projection = {'projection'}
ScriptEnv.Export.Automaton.selfloop = {'selfloop', params={ { "Automaton",'combobox','automaton' }, { "Automata",'multiple','automaton' }  } }
ScriptEnv.Export.Automaton.synchronization = {'synchronization', 'sync', params={ { "Automaton",'multiple','automaton' } } }
ScriptEnv.Export.Automaton.trim = {'trim', params={ { "Automaton",'multiple','automaton' } } }
ScriptEnv.Export.Automaton.save_as = {'save'}
ScriptEnv.Export.Automaton.infoString = {'info'}
ScriptEnv.Export.Automaton.infoStringMultiple = {'infom'}
ScriptEnv.Export.Automaton.localityString = {'localityinfo'}
ScriptEnv.Export.Automaton.localPlant = {'localplant'}
ScriptEnv.Export.Automaton.localTarget = {'localtarget'}
ScriptEnv.Export.Automaton.localSupervisor = {'localsupc', params={ { "E", 'combobox', 'automaton' }, { "Gloc", 'multiple', 'automaton' } }}
ScriptEnv.Export.Automaton.determinize = {'determinize'}

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
        if type(value) == 'table' then
            value:set('file_name', key .. '.nza') --UPDATE defClassExtension -- ElementClass arch
        end
        rawset(t, key, value)
    end

    return setmetatable( self.env, { __index=self.fnEnv, __newindex=newIndexFn } )
end

local function scriptErrorHandler ( errMsg )
  return errMsg .. debug.traceback( '', 2 )
end -- err

function ScriptEnv:execScript( script, printErrors )
    if not self.fnEnv then self:loadFnEnv() end
    --~ if not self.env then self:loadEnv() end
    self:loadEnv()
    local f, loadErr = loadstring( script )
    if f then
        setfenv( f, self.env )
        --~ f()
        local status, errMsg = xpcall( f, scriptErrorHandler )
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
