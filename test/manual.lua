package.path = package.path .. ";../?.lua"
_G[ 'lxp' ]  = require 'lxp'
require 'letk'
require 'class.object'
require 'class.des.automaton'

---create an automata where state n go to states n-1 and n+1 with alternates states
--first state is always initial
local OPTIONS     = {}
OPTIONS.NONE      = 0
OPTIONS.FIRST     = 1
OPTIONS.FIRSTHALF = 2 
OPTIONS.ODD       = 3
OPTIONS.EVEN      = 4
OPTIONS.ALL       = 5
local EVENTS = 'abcdefghijklmnopqrstuvwxyz'
local function createA( states, events, selfloops, mark, controllable, eventShift )
    local a = Automaton.new()
    states  = tonumber(states) or 2
    if states < 1 then states = 1 end
    events  = tonumber(events) or 3
    eventShift = eventShift or 0
    if (events+eventShift) > #EVENTS then events = (#EVENTS-eventShift) end
    if events < 3 then events = 3 end
    selfloops = control or OPTIONS.FIRST
    mark      = mark     or OPTIONS.FIRST
    control   = control  or OPTIONS.FIRSTHALF

    --Add events
    for e = 1, events do
        local controllableValue = false
        if e == 1 and control == OPTIONS.FIRST                       then controllableValue = true end
        if e < math.floor(events/2) and control == OPTIONS.FIRSTHALF then controllableValue = true end
        if e%2 == 1 and control == OPTIONS.ODD                       then controllableValue = true end
        if e%2 == 0 and control == OPTIONS.EVEN                      then controllableValue = true end
        if control == OPTIONS.ALL                                    then controllableValue = true end
        a:event_add(EVENTS:sub(e+eventShift,e+eventShift), true, controllableValue, '')
    end

    --Add states
    for s = 1, states do
        local markValue = false
        if s == 1 and mark == OPTIONS.FIRST                       then markValue = true end
        if s < math.floor(events/2) and mark == OPTIONS.FIRSTHALF then markValue = true end
        if s%2 == 1 and mark == OPTIONS.ODD                       then markValue = true end
        if s%2 == 0 and mark == OPTIONS.EVEN                      then markValue = true end
        if mark == OPTIONS.ALL                                    then markValue = true end
        
        if s == 1 then
            a:state_add( tostring( s ), markValue, true )
        else
            a:state_add( tostring( s ), markValue, false )
        end
    end

    --transitions
    local en = 1
    local function incEvent()
        en = en + 1
        if en > events then
            en = 1
        end
    end
    for s = 1, states do
        if s > 1 then
            a:transition_add(s,s-1,en)
            incEvent()
        end
        if s < states then
            a:transition_add(s,s+1,en)
            incEvent()
        end
        
        if
            ( s == 1 and selfloops == OPTIONS.FIRST                       ) or
            ( s < math.floor(events/2) and selfloops == OPTIONS.FIRSTHALF ) or
            ( s%2 == 1 and selfloops == OPTIONS.ODD                       ) or
            ( s%2 == 0 and selfloops == OPTIONS.EVEN                      ) or
            selfloops == OPTIONS.ALL
        then
            a:transition_add(s,s,en)
            incEvent()
        end
    end

    return a
end

--------------------------------------------------------------------------------

G = Automaton.new():IDES_import('models/t2/G.xmd')
E = Automaton.new():IDES_import('models/t2/E.xmd')
K = Automaton.new():IDES_import('models/t2/K.xmd')
S = Automaton.new():IDES_import('models/t2/S.xmd')

mapU = Automaton.univocal(G,K)

for sK, sG in pairs( mapU ) do
    local nG =  sG.name:gsub('[%(%)]', '')
    local nK =  sK.name:gsub('[%(%)]', '')
    print(nK, nG)
    --~ if not nK:match( nG .. '$' ) then
        --~ print(nK, nG)
    --~ end
end
