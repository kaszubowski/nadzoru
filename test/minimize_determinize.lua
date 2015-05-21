package.path = package.path .. ";../?.lua"
_G[ 'lxp' ]  = require 'lxp'
require 'letk'
require 'class.object'
require 'class.des.automaton'

describe( "deteminize", function()

    local NFA0, NFA1, DFA0, DFA1

    setup( function()
        NFA0 = Automaton.new():IDES_import('models/determinize/NFA0.xmd')
        NFA1 = Automaton.new():IDES_import('models/determinize/NFA1.xmd')
        DFA0 = Automaton.new():IDES_import('models/determinize/DFA0.xmd')
        DFA1 = Automaton.new():IDES_import('models/determinize/DFA1.xmd')
    end )
    
    teardown( function()
    end )

    it("case 0", function()
        local dfa0 = NFA0:determinize()
        assert.truthy( dfa0 )
        assert.is_true( dfa0:check_isomorphic(DFA0) )
    end )

    it("case 1", function()
        local dfa1 = NFA1:determinize()
        assert.truthy( dfa1 )
        assert.is_true( dfa1:check_isomorphic(DFA1) )
    end )
    
end )

describe( "minimize", function()

    local NFA0, NFA1, DFA0, DFA1

    setup( function()
        NFA6 = Automaton.new():IDES_import('models/minimize/NFA6.xmd')
        
        DFA0 = Automaton.new():IDES_import('models/minimize/DFA0.xmd') --state 3 is not accessible
        DFA1 = Automaton.new():IDES_import('models/minimize/DFA1.xmd')
        DFA2 = Automaton.new():IDES_import('models/minimize/DFA2.xmd')
        DFA3 = Automaton.new():IDES_import('models/minimize/DFA3.xmd')
        DFA4 = Automaton.new():IDES_import('models/minimize/DFA4.xmd')
        DFA5 = Automaton.new():IDES_import('models/minimize/DFA5.xmd')
        DFA6 = Automaton.new():IDES_import('models/minimize/DFA6.xmd')
        
        mDFA0 = Automaton.new():IDES_import('models/minimize/mDFA0.xmd')
        mDFA1 = Automaton.new():IDES_import('models/minimize/mDFA1.xmd')
        mDFA2 = Automaton.new():IDES_import('models/minimize/mDFA2.xmd')
        mDFA3 = Automaton.new():IDES_import('models/minimize/mDFA3.xmd')
        mDFA4 = Automaton.new():IDES_import('models/minimize/mDFA4.xmd')
        mDFA5 = Automaton.new():IDES_import('models/minimize/mDFA5.xmd')
        mDFA6 = Automaton.new():IDES_import('models/minimize/mDFA6.xmd')
    end )
    
    teardown( function()
    end )

    it("case 0", function()
        local mdfa = DFA0:minimize()
        assert.truthy( mdfa )
        assert.is_true( mdfa:check_isomorphic(mDFA0) )
    end )
    
    it("case 1", function()
        local mdfa = DFA1:minimize()
        assert.truthy( mdfa )
        assert.is_true( mdfa:check_isomorphic(mDFA1) )
    end )
    
    it("case 2", function()
        local mdfa = DFA2:minimize()
        assert.truthy( mdfa )
        assert.is_true( mdfa:check_isomorphic(mDFA2) )
    end )
    
    it("case 3", function()
        local mdfa = DFA3:minimize()
        assert.truthy( mdfa )
        assert.is_true( mdfa:check_isomorphic(mDFA3) )
    end )
    
    it("case 4", function()
        local mdfa = DFA4:minimize()
        assert.truthy( mdfa )
        assert.is_true( mdfa:check_isomorphic(mDFA4) )
    end )
    
    it("case 5", function()
        local mdfa = DFA5:minimize()
        assert.truthy( mdfa )
        assert.is_true( mdfa:check_isomorphic(mDFA5) )
    end )
    
    it("case 6", function()
        local dfa = NFA6:determinize()
        assert.truthy( dfa )
        local mdfa = dfa:minimize()
        assert.truthy( mdfa )
        assert.is_true( mdfa:check_isomorphic(mDFA6) )
    end )
    
end )
