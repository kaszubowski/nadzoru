package.path = package.path .. ";../?.lua"
_G[ 'lxp' ]  = require 'lxp'
require 'letk'
require 'class.object'
require 'class.des.automaton'

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
