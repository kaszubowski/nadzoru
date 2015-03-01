package.path = package.path .. ";../?.lua"
_G[ 'lxp' ]  = require 'lxp'
require 'letk'
require 'class.object'
require 'class.des.automaton'

--Check if IDES read is OK: events (controllable, ...), states, transitions
--Check all operations

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

describe( "Test 1", function()

    local G1, G2, E1, E2, G, E, K, S

    setup( function()
        G1 = Automaton.new():IDES_import('models/t1/G1.xmd')
        G2 = Automaton.new():IDES_import('models/t1/G2.xmd')
        E1 = Automaton.new():IDES_import('models/t1/E1.xmd')
        E2 = Automaton.new():IDES_import('models/t1/E2.xmd')
        G = Automaton.new():IDES_import('models/t1/G.xmd')
        E = Automaton.new():IDES_import('models/t1/E.xmd')
        K = Automaton.new():IDES_import('models/t1/K.xmd')
        S = Automaton.new():IDES_import('models/t1/S.xmd')
    end )
    
    teardown( function()
    end )

    it("synchronization", function()
        local g = G1:synchronization( G2 )
        assert.truthy( g )
        assert.is_true( g:check_isomorphic(G) )

        local e = E1:synchronization( E2 )
        assert.truthy( e )
        assert.is_true( e:check_isomorphic(E) )

        local k = g:synchronization( e )
        assert.truthy( k )
        assert.is_true( k:check_isomorphic(K) )
    end )
    
    it("supC", function()
        local s = Automaton.supC( G, K )
        assert.truthy( s )

        assert.is_true( s:check_isomorphic(S) )
    end )
    
    it("isomorphic", function()
        assert.is_true( G1:check_isomorphic(G1) )
        assert.is_false( G1:check_isomorphic(G2) )
        assert.is_false( G1:check_isomorphic(E1) )
        assert.is_false( G1:check_isomorphic(E2) )
        assert.is_false( G1:check_isomorphic(G) )
        assert.is_false( G1:check_isomorphic(E) )
        assert.is_false( G1:check_isomorphic(K) )
        
        assert.is_true( G2:check_isomorphic(G2) )
        assert.is_false( G2:check_isomorphic(E1) )
        assert.is_false( G2:check_isomorphic(E2) )
        assert.is_false( G2:check_isomorphic(G) )
        assert.is_false( G2:check_isomorphic(E) )
        assert.is_false( G2:check_isomorphic(K) )
        
        assert.is_true( E1:check_isomorphic(E1) )
        assert.is_false( E1:check_isomorphic(E2) )
        assert.is_false( E1:check_isomorphic(G) )
        assert.is_false( E1:check_isomorphic(E) )
        assert.is_false( E1:check_isomorphic(K) )
        
        assert.is_true( E2:check_isomorphic(E2) )
        assert.is_false( E2:check_isomorphic(G) )
        assert.is_false( E2:check_isomorphic(E) )
        assert.is_false( E2:check_isomorphic(K) )
        
        assert.is_true( G:check_isomorphic(G) )
        assert.is_false( G:check_isomorphic(E) )
        assert.is_false( G:check_isomorphic(K) )
        
        assert.is_true( E:check_isomorphic(E) )
        assert.is_false( E:check_isomorphic(K) )
        
        assert.is_true( K:check_isomorphic(K) )
        assert.is_true( K:check_isomorphic(S) )
    end )
    
end )

--------------------------------------------------------------------------------

describe( "Test 2", function()

    local G1, G2, G3, G4
    local E1, E2, E3, E4, E5, E6, E7
    local G, E, K, S

    setup( function()
        G1 = Automaton.new():IDES_import('models/t2/G1.xmd')
        G2 = Automaton.new():IDES_import('models/t2/G2.xmd')
        G3 = Automaton.new():IDES_import('models/t2/G3.xmd')
        G4 = Automaton.new():IDES_import('models/t2/G4.xmd')
        E1 = Automaton.new():IDES_import('models/t2/E1.xmd')
        E2 = Automaton.new():IDES_import('models/t2/E2.xmd')
        E3 = Automaton.new():IDES_import('models/t2/E3.xmd')
        E4 = Automaton.new():IDES_import('models/t2/E4.xmd')
        E5 = Automaton.new():IDES_import('models/t2/E5.xmd')
        E6 = Automaton.new():IDES_import('models/t2/E6.xmd')
        E7 = Automaton.new():IDES_import('models/t2/E7.xmd')
        G = Automaton.new():IDES_import('models/t2/G.xmd')
        E = Automaton.new():IDES_import('models/t2/E.xmd')
        K = Automaton.new():IDES_import('models/t2/K.xmd')
        S = Automaton.new():IDES_import('models/t2/S.xmd')
    end )
    
    teardown( function()
    end )

    it("synchronization", function()
        local g = G1:synchronization( G2, G3, G4 )
        assert.truthy( g )
        assert( g:check_isomorphic(G) )
        

        local e = E1:synchronization( E2, E3, E4, E5, E6, E7 )
        assert.truthy( e )
        assert( e:check_isomorphic(E) )

        local k = g:synchronization( e )
        assert.truthy( k )
        assert( k:check_isomorphic(K) )
        
    end )
    
    it("supC", function()
        local s = Automaton.supC( G, K )
        assert.truthy( s )

        --~ s:minimize(true)
        assert( s:check_isomorphic(S) )
    end )
    
    it("isomorphic", function()
        assert.is_true( G1:check_isomorphic(G1) )
        assert.is_false( G1:check_isomorphic(G2) )
        assert.is_false( G1:check_isomorphic(G3) )
        assert.is_false( G1:check_isomorphic(G4) )
        assert.is_false( G1:check_isomorphic(E1) )
        assert.is_false( G1:check_isomorphic(E2) )
        assert.is_false( G1:check_isomorphic(E3) )
        assert.is_false( G1:check_isomorphic(E4) )
        assert.is_false( G1:check_isomorphic(E5) )
        assert.is_false( G1:check_isomorphic(E6) )
        assert.is_false( G1:check_isomorphic(E7) )
        assert.is_false( G1:check_isomorphic(G) )
        assert.is_false( G1:check_isomorphic(E) )
        assert.is_false( G1:check_isomorphic(K) )
        assert.is_false( G1:check_isomorphic(S) )
        
        assert.is_true( G2:check_isomorphic(G2) )
        assert.is_false( G2:check_isomorphic(G3) )
        assert.is_false( G2:check_isomorphic(G4) )
        assert.is_false( G2:check_isomorphic(E1) )
        assert.is_false( G2:check_isomorphic(E2) )
        assert.is_false( G2:check_isomorphic(E3) )
        assert.is_false( G2:check_isomorphic(E4) )
        assert.is_false( G2:check_isomorphic(E5) )
        assert.is_false( G2:check_isomorphic(E6) )
        assert.is_false( G2:check_isomorphic(E7) )
        assert.is_false( G2:check_isomorphic(G) )
        assert.is_false( G2:check_isomorphic(E) )
        assert.is_false( G2:check_isomorphic(K) )
        assert.is_false( G2:check_isomorphic(S) )

        assert.is_true( G3:check_isomorphic(G3) )
        assert.is_false( G3:check_isomorphic(G4) )
        assert.is_false( G3:check_isomorphic(E1) )
        assert.is_false( G3:check_isomorphic(E2) )
        assert.is_false( G3:check_isomorphic(E3) )
        assert.is_false( G3:check_isomorphic(E4) )
        assert.is_false( G3:check_isomorphic(E5) )
        assert.is_false( G3:check_isomorphic(E6) )
        assert.is_false( G3:check_isomorphic(E7) )
        assert.is_false( G3:check_isomorphic(G) )
        assert.is_false( G3:check_isomorphic(E) )
        assert.is_false( G3:check_isomorphic(K) )
        assert.is_false( G3:check_isomorphic(S) )

        assert.is_true( G4:check_isomorphic(G4) )
        assert.is_false( G4:check_isomorphic(E1) )
        assert.is_false( G4:check_isomorphic(E2) )
        assert.is_false( G4:check_isomorphic(E3) )
        assert.is_false( G4:check_isomorphic(E4) )
        assert.is_false( G4:check_isomorphic(E5) )
        assert.is_false( G4:check_isomorphic(E6) )
        assert.is_false( G4:check_isomorphic(E7) )
        assert.is_false( G4:check_isomorphic(G) )
        assert.is_false( G4:check_isomorphic(E) )
        assert.is_false( G4:check_isomorphic(K) )
        assert.is_false( G4:check_isomorphic(S) )

        assert.is_true( E1:check_isomorphic(E1) )
        assert.is_false( E1:check_isomorphic(E2) )
        assert.is_false( E1:check_isomorphic(E3) )
        assert.is_false( E1:check_isomorphic(E4) )
        assert.is_false( E1:check_isomorphic(E5) )
        assert.is_false( E1:check_isomorphic(E6) )
        assert.is_false( E1:check_isomorphic(E7) )
        assert.is_false( E1:check_isomorphic(G) )
        assert.is_false( E1:check_isomorphic(E) )
        assert.is_false( E1:check_isomorphic(K) )
        assert.is_false( E1:check_isomorphic(S) )

        assert.is_true( E2:check_isomorphic(E2) )
        assert.is_false( E2:check_isomorphic(E3) )
        assert.is_false( E2:check_isomorphic(E4) )
        assert.is_false( E2:check_isomorphic(E5) )
        assert.is_false( E2:check_isomorphic(E6) )
        assert.is_false( E2:check_isomorphic(E7) )
        assert.is_false( E2:check_isomorphic(G) )
        assert.is_false( E2:check_isomorphic(E) )
        assert.is_false( E2:check_isomorphic(K) )
        assert.is_false( E2:check_isomorphic(S) )

        assert.is_true( E3:check_isomorphic(E3) )
        assert.is_false( E3:check_isomorphic(E4) )
        assert.is_false( E3:check_isomorphic(E5) )
        assert.is_false( E3:check_isomorphic(E6) )
        assert.is_false( E3:check_isomorphic(E7) )
        assert.is_false( E3:check_isomorphic(G) )
        assert.is_false( E3:check_isomorphic(E) )
        assert.is_false( E3:check_isomorphic(K) )
        assert.is_false( E3:check_isomorphic(S) )

        assert.is_true( E4:check_isomorphic(E4) )
        assert.is_false( E4:check_isomorphic(E5) )
        assert.is_false( E4:check_isomorphic(E6) )
        assert.is_false( E4:check_isomorphic(E7) )
        assert.is_false( E4:check_isomorphic(G) )
        assert.is_false( E4:check_isomorphic(E) )
        assert.is_false( E4:check_isomorphic(K) )
        assert.is_false( E4:check_isomorphic(S) )

        assert.is_true( E5:check_isomorphic(E5) )
        assert.is_false( E5:check_isomorphic(E6) )
        assert.is_false( E5:check_isomorphic(E7) )
        assert.is_false( E5:check_isomorphic(G) )
        assert.is_false( E5:check_isomorphic(E) )
        assert.is_false( E5:check_isomorphic(K) )
        assert.is_false( E5:check_isomorphic(S) )

        assert.is_true( E6:check_isomorphic(E6) )
        assert.is_false( E6:check_isomorphic(E7) )
        assert.is_false( E6:check_isomorphic(G) )
        assert.is_false( E6:check_isomorphic(E) )
        assert.is_false( E6:check_isomorphic(K) )
        assert.is_false( E6:check_isomorphic(S) )

        assert.is_true( E7:check_isomorphic(E7) )
        assert.is_false( E7:check_isomorphic(G) )
        assert.is_false( E7:check_isomorphic(E) )
        assert.is_false( E7:check_isomorphic(K) )
        assert.is_false( E7:check_isomorphic(S) )

        assert.is_true( G:check_isomorphic(G) )
        assert.is_false( G:check_isomorphic(E) )
        assert.is_false( G:check_isomorphic(K) )
        assert.is_false( G:check_isomorphic(S) )

        assert.is_true( E:check_isomorphic(E) )
        assert.is_false( E:check_isomorphic(K) )
        assert.is_false( E:check_isomorphic(S) )
        
        assert.is_true( K:check_isomorphic(K) )
        assert.is_false( K:check_isomorphic(S) )
        
        assert.is_true( S:check_isomorphic(S) )
    end )
    
end )
