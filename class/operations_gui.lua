OperationsGui = letk.Class( function( self, elements )
    Object.__super( self )

    self.elements = elements

end, Object )

function OperationsGui:buildGui( gui )
    self.gui   = gui
    self.opGui = {}
    

    
    self.opGui.vbox = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.opGui.hbox = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.opGui.paned  = gtk.Paned.new( gtk.ORIENTATION_VERTICAL )
            self.selector, self.selector_widget = nil, nil --This one is cleared and fill for every operation selected in the treeview
        self.opGui.hbox_footer = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.opGui.btn_run      = gtk.Button.new_with_label("Run")


    self.opGui.paned:set_position(400)

     --Operations menu:
    self.opGui.scroll_menu   = gtk.ScrolledWindow.new()
        self.opGui.menu_view = gtk.TreeView.new()
    self.opGui.scroll_menu:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.opGui.scroll_menu:set('width-request', 350 )
    self.opGui.menu_model      = gtk.TreeStore.new('gchararray','gchararray','gchararray') --name, className, methodName
    self.opGui.menu_col1       = gtk.TreeViewColumn.new_with_attributes("Operations", gtk.CellRendererText.new(), "text", 0)
    self.opGui.menu_selection  = self.opGui.menu_view:get_selection()

    self.opGui.menu_view:append_column(self.opGui.menu_col1)
    self.opGui.menu_view:set('model', self.opGui.menu_model)
    self.opGui.menu_selection:set_mode(gtk.SELECTION_SINGLE)

     --Info:
    self.opGui.scroll_info   = gtk.ScrolledWindow.new()
        self.opGui.info_view     = gtk.TextView.new()   

    self.opGui.info_buffer   = self.opGui.info_view:get('buffer')
    self.opGui.scroll_info:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.opGui.info_view:set_editable(false)
    self.opGui.info_view:set_wrap_mode( gtk.WRAP_WORD_CHAR )

    --Pack
    self.opGui.hbox_footer:set_halign( gtk.ALIGN_END )
    
    self.opGui.vbox:pack_start( self.opGui.hbox, true, true, 1 )
        self.opGui.hbox:pack_start( self.opGui.paned, false, false, 1 )
            self.opGui.paned:add1( self.opGui.scroll_menu )
                self.opGui.scroll_menu:add(self.opGui.menu_view)
            self.opGui.paned:add2( self.opGui.scroll_info )
                self.opGui.scroll_info:add(self.opGui.info_view)
        --Selector widget 
    self.opGui.vbox:pack_start( self.opGui.hbox_footer, false, false, 1 )
        self.opGui.hbox_footer:pack_start( self.opGui.btn_run, false, false, 1 )

    --Callbacks
    --~ self.opGui.menu_view:connect( 'row-activated', self.select_menu, self)
    self.opGui.menu_view:connect( 'cursor-changed', self.select_menu, self)
    self.opGui.btn_run:connect('clicked', self.run, self )

    self:updateMenu()

    --Add to tab
    gui:add_tab( self.opGui.vbox, "Operations" )
end

function OperationsGui:updateMenu()
    self.opGui.menu_model:clear()
    local iter     = gtk.TreeIter.new()
    for className, classDef in pairs( ScriptEnv.Export ) do
        for methodName, envFnNames in pairs( classDef ) do
            for k_caption, caption in ipairs( envFnNames ) do
                self.opGui.menu_model:append( iter )
                self.opGui.menu_model:set( iter, 0, caption, 1, className, 2, methodName )
            end
        end
    end 
end

function OperationsGui:select_menu()
    local iter = gtk.TreeIter.new()
    local res, m = self.opGui.menu_selection:get_selected( iter )
    if res then
        local className  = m:get(iter, 1)
        local methodName = m:get(iter, 2)
        local def        = ScriptEnv.Export[ className ][ methodName ]

        --update operator description:
        if def.description then
            self.opGui.info_buffer:set_text( def.description, #def.description )
        else
            self.opGui.info_buffer:set_text( "", 0 )
        end

        --Remove selector widget
        if self.selector_widget then
            self.selector_widget:destroy()
        end

        --Build param selector interface
        self.selector, self.selector_widget = Selector.new( {
            success_fn = OperationsGui.select_run,
            success_fn_param = self,
        }, true )
        self.opGui.hbox:pack_start( self.selector_widget, true, true, 1 )
        self.selector:add_entry({ text="Result:", default="G" })
        for k_param, param in ipairs( def.params or {} ) do
            if param[2] == 'combobox' then
                self.selector:add_combobox{
                    list = self.elements,
                    text_fn  = function( a )
                        return a:get( 'file_name' )
                    end,
                    filter_fn = function( v )
                        return v.__TYPE == param[3]
                    end,
                    text = param[1]
                }
            elseif param[2] == 'multiple' then
                self.selector:add_multipler{
                    list = self.elements,
                    text_fn  = function( a )
                        return a:get( 'file_name' )
                    end,
                    filter_fn = function( v )
                        return v.__TYPE == param[3]
                    end,
                    text = param[1]
                }
            end
        end
        self.selector:run()
    end
end

function OperationsGui.select_run( result, result_size, selector, self )
    local iter   = gtk.TreeIter.new()
    local res, m = self.opGui.menu_selection:get_selected( iter )
    if res then
        local className  = m:get(iter, 1)
        local methodName = m:get(iter, 2)
        local def        = ScriptEnv.Export[ className ][ methodName ]
        local params     = {}
        for k_param, param in ipairs( def.params or {} ) do
            if param[2] == 'combobox' then
                if not result[ k_param+1 ] then return end
                params[ #params + 1 ] = result[ k_param+1 ] --skip entry
            elseif param[2] == 'multiple' then
                for k_el, el in ipairs( result[ k_param+1 ] ) do --skip entry
                    params[ #params + 1 ] = el
                end
            end
        end
        local method = _G[ className ][ methodName ]
        local newElement = method( unpack( params ) )
        if not def.keep then
            newElement:set ('file_name', result[1] )
            self.elements:append( newElement )
            self:select_menu()
        end
    end
end

function OperationsGui:run()
    if self.selector then
        self.selector:success()
    end

    --clear/update list of elements if any
end
