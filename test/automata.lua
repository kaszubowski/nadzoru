package.path = package.path .. ";../?.lua"
_G[ 'lxp' ]  = require 'lxp'
require 'letk'
require 'class.object'
require 'class.des.automaton'

--Check if IDES read is OK: events (controllable, ...), states, transitions
--Check all operations

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
        --~ local s = Automaton.supC( G, K )
        local co = coroutine.create( Automaton.supC )
        local status, s
        while coroutine.status( co ) ~= 'dead' do
            status, s = coroutine.resume( co, G, K )
            print( s )
        end
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
