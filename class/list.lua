--[[
    This file is part of nadzoru.

    nadzoru is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    nadzoru is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with nadzoru.  If not, see <http://www.gnu.org/licenses/>.

    Copyright (C) 2011 Yuri Kaszubowski Lopes, Eduardo Harbs, Andre Bittencourt Leal and Roberto Silvio Ubertino Rosso Jr.
--]]

--[[
[a,b,c] -4:[1,1] -3:[1,1], -2:[2,2], -1:[3,3], 0:[3,4], 1:[1,1], 2:[2,2], 3:[3,3], 4:[3,4]
--]]

List    = {}
List_MT = {
    __index = List,
}

setmetatable( List, Object_MT )

function List.new()
    local self = Object.new()
    self.root  = nil
    --self.last  = nil
    self.itens = 0

    return setmetatable( self, List_MT )
end

function List:normalize_position( pos )
    --return GET, INSERT
    if self.itens == 0 then
        return false, 1
    end
    if pos == 0 or pos > self.itens then
        return self.itens, self.itens + 1
    end
    if pos < 0 then
        local aux = self.itens + pos +1
        if aux <= 0 then
            return 1, 1
        else
            return aux, aux
        end
    end
    return pos, pos
end

function List:add( data, pos )
    local gpos, ipos = self:normalize_position( pos )

    local node = {
        data = data,
    }

    local p_prev  = nil
    local p_atual = self.root
    --local p_next  = nil

    while ipos > 1 and p_atual do
        ipos = ipos - 1
        p_prev   = p_atual
        p_atual  = p_atual.next
    end

    if p_atual and p_prev then
        node.next    = p_atual
        p_prev.next  = node
    elseif p_atual then
        node.next    = p_atual
        self.root    = node
    elseif p_prev then
        p_prev.next = node
    else
        self.root = node
    end

    self.itens = self.itens + 1
end

function List:get( pos )
    local gpos, ipos = self:normalize_position( pos )

    if not gpos then
        return
    end

    local p_atual = self.root

    while gpos > 1 and p_atual do
        gpos = gpos - 1
        p_atual = p_atual.next
    end

    if p_atual then
        return p_atual.data
    end

end

function List:remove( pos )
    local gpos, ipos = self:normalize_position( pos )
    if not gpos then
        return
    end

    local p_prev  = nil
    local p_atual = nil
    local p_next  = self.root

    while gpos > 0 and p_next do
        gpos = gpos - 1
        p_prev  = p_atual
        p_atual = p_next
        p_next  = p_next.next
    end

    if p_atual then
        if p_prev then
            p_prev.next = p_next
        else
            self.root = p_next
        end

        self.itens = self.itens - 1
        return p_atual.data
    end
end

function List:append( data )
    self:add( data, 0) --last position
    return self.itens
end

function List:prepend( data )
    self:add( data, 1) --first position
    return 1
end

function List:ipairs()
    local iter = function( list, last_pos )
        local pos  = last_pos and last_pos + 1 or 1
        if pos > self.itens then return end
        local data = list:get( pos )
        return pos, data
    end
    return iter, self, nil
end

function List:find( arg, force_data )
    force_data = force_data or false
    local t = type( arg )
    if t == 'number' and not force_data then
        return self:get( arg ), arg
    end

    for pos, data in self:ipairs() do
        if t == 'function' then
            if arg( data ) then
                return data, pos
            end
        else
            if data == arg then
                return data, pos
            end
        end
    end
end

function List:find_remove( arg, force_data )
     while true do
        local _, pos = self:find( arg, force_data )
        if not pos then return end

        self:remove( pos )
    end
end

function List:len()
    return self.itens
end
