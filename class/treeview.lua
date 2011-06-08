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

Treeview    = {}
Treeview_MT = { __index = Treeview }

setmetatable( Treeview, Object_MT )

function Treeview.new( multiple )
    local self = Object.new()
    self.data       = List.new()
    self.columns    = {}
    self.render     = {}
    self.model_list = {}
    self.view       = gtk.TreeView.new()
    self.iter       = gtk.TreeIter.new()
    self.selection  = self.view:get_selection()
    self.selection:set_mode( multiple and gtk.SELECTION_MULTIPLE or gtk.SELECTION_BROWSE )
    self.multiple   = multiple or false
    setmetatable( self, Treeview_MT )
    return self
end

function Treeview:bind_ondoubleclick( callback, param )
    self.view:connect( 'row-activated', callback, param )

    return self
end

function Treeview:add_column_text( caption, width )
    self.render[#self.render +1] = gtk.CellRendererText.new()
    self.columns[#self.columns +1] = gtk.TreeViewColumn.new_with_attributes(
        caption,
        self.render[#self.render],
        'text',
        #self.columns
    )
    if tonumber( width ) then
        self.render[#self.render]:set('width',width)
    end
    self.view:append_column( self.columns[#self.columns] )
    self.model_list[#self.model_list +1] = 'gchararray'

    return self
end

function Treeview:add_column_toggle( caption, callback, param )
    self.render[#self.render +1] = gtk.CellRendererToggle.new()
    self.columns[#self.columns +1] = gtk.TreeViewColumn.new_with_attributes(
        caption,
        self.render[#self.render],
        'active',
        #self.columns
    )
    self.view:append_column( self.columns[#self.columns] )
    self.model_list[#self.model_list +1] = 'gboolean'
    if type(callback) == 'function' then
        self.render[#self.render]:connect('toggled', callback, param)
    end

    return self
end

function Treeview:build(  )
    self.model = gtk.ListStore.new( unpack( self.model_list ) )
    self.view:set( 'model', self.model )

    return self.view
end

function Treeview:clear_data()
    while self.data:get( 1 ) do
        self.data:remove( 1 )
    end

    return self
end

function Treeview:clear_gui()
    if not self.model then return end
    self.model:clear()

    return self
end

function Treeview:clear_all()
    self:clear_data()
    self:clear_gui()

    return self
end

function Treeview:update()
    self:clear_gui()
    for ch_row, row in self.data:ipairs() do
        self.model:append( self.iter )
        for ch_fld, fld in ipairs( row ) do
            self.model:set( self.iter, ch_fld - 1, fld )
        end
    end

    return self
end

function Treeview:get_selected( column )
    if not self.multiple then
        local res, model = self.selection:get_selected( self.iter )
        if res then
            local path = model:get_path( self.iter )
            local pos  = path:get_indices( 0 )[ 1 ]
            if column then
                return model:get( self.iter, column - 1 ), pos + 1
            else
                return pos + 1
            end
        end
    else
        local position                = self.selection:get_selected_rows()
        local result_data, result_pos = {}, {}
        for c,v in ipairs( position ) do
            result_pos[#result_pos +1]   = v + 1
            --local model = self.view:get_model() -- need by implementend in lgob.gtk
            --local model:get_iter( self.iter, tostring(v) )
            --result_data[#result_data +1] = model:get( self.iter, column - 1 )
        end

        if column then
            return result_data, result_pos
        else
            return result_pos
        end
    end
end

function Treeview:add_row( row )
    self.data:append( row )

    return self
end

function Treeview:remove_row( pos )
    self.data:remove( pos )

    return self
end

function Treeview:remove_selected( )
    local pos = self:get_selected()
    if pos then
        self:remove( pos )
    end
    return self
end


--gtk_tree_selection_selected_foreach
--(*GtkTreeSelectionForeachFunc)      (GtkTreeModel *model,GtkTreePath *path,GtkTreeIter *iter,gpointer data);
