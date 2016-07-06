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
module "Treeview"
--]]
Treeview = letk.Class( function( self, multiple )
    Object.new( self )
    self.scrolled   = gtk.ScrolledWindow.new()
    self.data       = letk.List.new()
    self.columns    = {}
    self.render     = {}
    self.model_list = {}
    self.view       = gtk.TreeView.new()
    self.iter       = gtk.TreeIter.new()
    self.selection  = self.view:get_selection()
    self.selection:set_mode( multiple and gtk.SELECTION_MULTIPLE or gtk.SELECTION_BROWSE )
    self.multiple   = multiple or false

    self.scrolled:add( self.view )

    self.scrolled:set_shadow_type(gtk.SHADOW_ETCHED_IN)

end, Object )

---bind a callback for a double click
--@param callback <function>
--@param param an user data to be sent to the callback function
--@return self
function Treeview:bind_ondoubleclick( callback, param )
    self.view:connect( 'row-activated', callback, param )

    return self
end

---bind a callback for a single click
--@param callback <function>
--@param param an user data to be sent to the callback function
--@return self
function Treeview:bind_onclick( callback, param )
    self.view:connect( 'cursor-changed', callback, param )

    return self
end

---adds a text column
--@param caption <string>
--@param width <number-integer>
--@param callback <function>
--@param param an user data to be sent to the callback function
--@return self
function Treeview:add_column_text( caption, width, callback, param )
    local columnID           = #self.columns +1
    self.render[ columnID ]  = gtk.CellRendererText.new()
    self.columns[ columnID ] = gtk.TreeViewColumn.new_with_attributes(
        caption,
        self.render[columnID],
        'text',
        #self.columns
    )
    if tonumber( width ) then
        self.render[columnID]:set('width',width)
    end
    self.view:append_column( self.columns[ columnID ] )
    self.model_list[#self.model_list +1] = 'gchararray'

    if type(callback) == 'function' then
        self.render[ columnID ]:set('editable', true)
        self.render[ columnID ]:connect('edited', callback, param )
    elseif type(callback) == 'boolean' and callback == true then
        self.render[ columnID ]:set('editable', callback)
        local function updateData( treeview, row_id, newValue )
            --~ print( treeview, row_id, new_name )
            local rowData       = treeview.data:get( row_id + 1 )
            rowData[ columnID ] = newValue
            treeview:update()
        end
        self.render[ columnID ]:connect('edited', updateData, self )
    end

    return self
end

---TODO
--TODO
--@param self TODO
--@param caption TODO
--@param width TODO
--@param callback TODO
--@param param TODO
--@return TODO
function Treeview:add_column_toggle( caption, width, callback, param )
    self.render[#self.render +1] = gtk.CellRendererToggle.new()
    self.columns[#self.columns +1] = gtk.TreeViewColumn.new_with_attributes(
        caption,
        self.render[#self.render],
        'active',
        #self.columns
    )
    if tonumber( width ) then
        self.render[#self.render]:set('width', width)
    end
    self.view:append_column( self.columns[#self.columns] )
    self.model_list[#self.model_list +1] = 'gboolean'
    if type(callback) == 'function' then
        self.render[#self.render]:connect('toggled', callback, param)
    elseif type(callback) == 'boolean' then
        --TODO, update model
    end

    return self
end

---TODO
--Unfinished. TODO
--@param self TODO
--@param caption TODO
--@param width TODO
--@param callback TODO
--@param param TODO
--@return TODO
function Treeview:add_column_combobox( caption, width, callback, param )
    
end

---TODO
--TODO
--@param self TODO
--@param options TODO
--@return TODO
function Treeview:preBuild()
    self.model = gtk.ListStore.new( unpack( self.model_list ) )
    self.view:set( 'model', self.model )
end

function Treeview:postBuild( options )
    options = options or {}
    if options.width then
        self.scrolled:set( 'width-request', options.width )
    end
    if options.height then
        self.scrolled:set( 'height-request', options.height )
    end

    return self.scrolled
end

function Treeview:build( options )
    self:preBuild()
    return self:postBuild( options )
end

---TODO
--TODO
--@param self TODO
--@return TODO
function Treeview:clear_data()
    while self.data:get( 1 ) do
        self.data:remove( 1 )
    end

    return self
end

---TODO
--TODO
--@param self TODO
--@return TODO
function Treeview:clear_gui()
    if not self.model then return end
    self.model:clear()

    return self
end

---TODO
--TODO
--@param self TODO
--@return TODO
--@see Treeview:clear_data
--@see Treeview:clear_gui
function Treeview:clear_all()
    self:clear_data()
    self:clear_gui()

    return self
end

---TODO
--TODO
--@param self TODO
--@return TODO
--@see Treeview:clear_gui
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

--function Treeview:set_selected( column, items )
    
--end

---TODO
--TODO
--@param self TODO
--@param column TODO
--@return TODO
function Treeview:get_selected( column )
    if not self.multiple then
        local res, model = self.selection:get_selected( self.iter )
        if res then
            local path = model:get_path( self.iter )
            --~ local pos  = path:get_indices( 0 )[ 1 ]
            local pos  = path:get_indices()[ 1 ]
            if column then
                return model:get( self.iter, column - 1 ), pos + 1
            else
                return pos + 1
            end
        else
            return false
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

---TODO
--TODO
--@param self TODO
--@param row TODO
--@return TODO
function Treeview:add_row( row )
    self.data:append( row )

    return self
end

---TODO
--TODO
--@param self TODO
--@param pos TODO
--@return TODO
function Treeview:remove_row( pos )
    self.data:remove( pos )

    return self
end

---TODO
--TODO
--@param self TODO
--@return TODO
--@see Treeview:get_selected
function Treeview:remove_selected( )
    local pos = self:get_selected()
    if pos then
        self:remove( pos )
    end
    return self
end


--gtk_tree_selection_selected_foreach
--(*GtkTreeSelectionForeachFunc)      (GtkTreeModel *model,GtkTreePath *path,GtkTreeIter *iter,gpointer data);
