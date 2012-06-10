PropertyEditor = letk.Class( function( self )
    Object.new( self )
    
    self.enable_callback = true

    self.rows       = {}
    self.hboxs      = {}
    self.callback   = nil
end, Object )

function PropertyEditor:build( label_w, value_w)
    self.vbox       = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
    self.scrolled   = gtk.ScrolledWindow.new()
    self.label_w    = label_w or 128
    self.value_w    = value_w or 200
    self.scrolled:set( 'width-request', self.label_w  + self.value_w + 5 )

    self.scrolled:add_with_viewport( self.vbox )
    self.scrolled:set_shadow_type(gtk.SHADOW_ETCHED_IN)
    --~ self.scrolled:set_policy(gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC)
    
    return self.scrolled
end

function PropertyEditor:clear_interface()
    self.enable_callback = false
    for name, widget in pairs( self.hboxs ) do
        self.vbox:remove( widget )
    end
    self.enable_callback = true
end


function PropertyEditor:clear()
    self:clear_interface()
    self.hboxs    = {}
    self.rows     = {}
    self.callback = nil
end

local function entry_callback( data )
    if not data.self.enable_callback then return end
    local ok       = true
    local new_text = data.row.entry:get_text()
    if data.row.options.type and (data.row.options.type == 'number' or data.row.options.type == 'integer') then
        local new_number
        new_number = tonumber( new_text )
        if not new_number then ok = false end
        if ok and type( data.row.options.min ) == 'number' and new_number < data.row.options.min then ok = false end
        if ok and type( data.row.options.min ) == 'string' then 
            if new_number < tonumber(data.self.rows[ data.row.options.min ].value) then
                ok = false
            end
        end
        if ok and type( data.row.options.max ) == 'number' and new_number > data.row.options.max then ok = false end
        if ok and type( data.row.options.max ) == 'string' then 
            if new_number > tonumber(data.self.rows[ data.row.options.max ].value) then
                ok = false
            end
        end
        if ok and data.row.options.type == 'integer' and math.floor( new_number ) ~= new_number then ok = false end
    end
    
    if (ok or ok == nil) and data.row.callback then
        local temp_text
        ok, temp_text = data.row.callback( data.row.param, data.row.value, new_text )
        new_text      = temp_text or new_text
    end

    if (ok or ok == nil) and data.self.callback and data.self.callback.fn then
        local temp_text
        ok, temp_text = data.self.callback.fn( data.self.callback.param, data.row.name, data.row.value, new_text )
        new_text      = temp_text or new_text
    end
    if ok or ok == nil then
        data.row.value = new_text
    else
        data.row.entry:set_text( data.row.value or '' )
    end
end

local function combobox_callback( data )
    if not data.self.enable_callback then return end
    local ok
    local selected = data.row.combobox:get_active() + 1
    local old_value    = type(data.row.itens[data.row.value]) == 'table' and data.row.itens[data.row.value].value or data.row.value
    local new_value    = type(data.row.itens[selected]) == 'table' and data.row.itens[selected].value or selected

    if data.row.callback then
        ok = data.row.callback( data.row.param, old_value, new_value )
    end
    if (ok or ok == nil) and data.self.callback and data.self.callback.fn then
        ok = data.self.callback.fn( data.self.callback.param, data.row.name, old_value, new_value )
    end
    if ok or ok == nil then
        data.row.value = selected
    else
        data.row.combobox:set('active', data.row.value - 1)
    end
end

local function checkbox_callback( data )
    if not data.self.enable_callback then return end
    local ok
    local active = data.row.checkbox:get_active()

    if data.row.callback then
        ok = data.row.callback( data.row.param, data.row.value, active )
    end
    if (ok or ok == nil) and data.self.callback and data.self.callback.fn then
        ok = data.self.callback.fn( data.self.callback.param, data.row.name, data.row.value, active )
    end
    if ok or ok == nil then
        data.row.value = active
    else
        data.row.checkbox:set('active', data.row.value - 1)
    end
end

local function color_callback( data )
    if not data.self.enable_callback then return end
    local ok
    local color = gdk.color_parse( '#ffffff' )
    data.row.color:get_color( color )
    local color_str = gdk.color_to_string(color)

    if data.row.callback then
        ok = data.row.callback( data.row.param, data.row.value, color_str )
    end
    if (ok or ok == nil) and data.self.callback and data.self.callback.fn then
        ok = data.self.callback.fn( data.self.callback.param, data.row.name, data.row.value, color_str )
    end
    if ok or ok == nil then
        data.row.value = color_str
    else
       data.color:set_color( gdk.color_parse( data.row.value ) )
    end
end

local function link_callback( data )
    if not data.self.enable_callback then return end
    local link_gui = {}
    
    --TODO
    
end

local function code_callback( data )
    if not data.self.enable_callback then return end
    
    local code_gui = {}
    code_gui.win   = gtk.Window.new( gtk.WINDOW_TOPLEVEL )
        code_gui.vbox  = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
            code_gui.hbox  = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                code_gui.scroll_help         = gtk.ScrolledWindow.new()
                    code_gui.help_view       = gtk.TreeView.new()
                code_gui.scroll              = gtk.ScrolledWindow.new()
                    code_gui.code_input_view = gtk.SourceView.new()
            code_gui.hbox_btn  = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                code_gui.btn_cancel = gtk.Button.new_with_label( "Cancel" )
                code_gui.btn_ok = gtk.Button.new_with_label( "OK" )
                code_gui.btn_save = gtk.Button.new_with_label( "Save" )
                
    code_gui.win:add( code_gui.vbox )
        code_gui.vbox:pack_start( code_gui.hbox, true, true, 0 )
            code_gui.hbox:pack_start( code_gui.scroll_help, false, false, 0 )
                code_gui.scroll_help:add(code_gui.help_view)
            code_gui.hbox:pack_start( code_gui.scroll, true, true, 0 )
                code_gui.scroll:add(code_gui.code_input_view)
        code_gui.vbox:pack_start( code_gui.hbox_btn, false, false, 0 )
            code_gui.hbox_btn:pack_start( code_gui.btn_cancel, true, true, 0 )
            code_gui.hbox_btn:pack_start( code_gui.btn_ok, true, true, 0 )
            code_gui.hbox_btn:pack_start( code_gui.btn_save, true, true, 0 )
            
    code_gui.scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    code_gui.code_input_buffer   = code_gui.code_input_view:get('buffer')
    code_gui.code_input_manager  = gtk.source_language_manager_get_default()
    code_gui.code_input_lang     = code_gui.code_input_manager:get_language('lua')
    code_gui.code_input_buffer:set('language', code_gui.code_input_lang)
    
    --Help
    code_gui.scroll_help:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    code_gui.scroll_help:set('width-request', 250 )
    code_gui.help_model      = gtk.TreeStore.new("gchararray","gchararray")
    code_gui.help_col1       = gtk.TreeViewColumn.new_with_attributes("Help", gtk.CellRendererText.new(), "text", 0)
    code_gui.help_selection  = code_gui.help_view:get_selection()
    
    code_gui.help_view:append_column(code_gui.help_col1)
    code_gui.help_view:set("model", code_gui.help_model)
    code_gui.help_selection:set_mode(gtk.SELECTION_SINGLE)
    
    code_gui.win:set("title", "nadzoru::Code Editor", "width-request", 800,
        "height-request", 600, "window-position", gtk.WIN_POS_CENTER,
        "icon-name", "gtk-about")
    
    code_gui.code_input_view:set( 'auto-indent', true )
    code_gui.code_input_view:set( 'show-line-numbers', true )
    code_gui.code_input_view:set( 'highlight-current-line', true )
    code_gui.code_input_view:set( 'insert-spaces-instead-of-tabs', true )
    code_gui.code_input_view:set( 'draw-spaces', gtk.SOURCE_DRAW_SPACES_SPACE  )
    code_gui.code_input_view:set( 'smart-home-end', gtk.SOURCE_SMART_HOME_END_BEFORE  )
    code_gui.code_input_view:set( 'tab-width', 4 )
    code_gui.code_input_buffer:set( 'text', data.row.value )
    code_gui.scroll_help:set_shadow_type(gtk.SHADOW_ETCHED_IN)
    
    local function add_help( tbl, dad )
        local iter = gtk.TreeIter.new()
        for k, v in ipairs( tbl ) do
            code_gui.help_model:append(iter, dad)
            code_gui.help_model:set(iter, 0, v.caption, 1, v.value or '')
            add_help( v, iter )
        end
    end
    
    if data.row.options.help then
        add_help( data.row.options.help )
    end
            
    local function select_help()
        local iter = gtk.TreeIter.new()
        local res, m = code_gui.help_selection:get_selected( iter )
        if res then
            local text = m:get(iter, 1)
            code_gui.code_input_buffer:insert_at_cursor( text, #text ) 
        end
    end
    
    local function cancel()
        code_gui.win:destroy()
    end
    
    local function save()
        local new_value = code_gui.code_input_buffer:get( 'text' )
        local ok
        if data.row.callback then
            ok = data.row.callback( data.row.param, data.row.value, new_value )
        end
        if (ok or ok == nil) and data.self.callback and data.self.callback.fn then
            ok = data.self.callback.fn( data.self.callback.param, data.row.name, data.row.value, new_value )
        end
        if ok or ok == nil then
            data.row.value = new_value
        else
           code_gui.code_input_buffer:set( 'text', data.row.value )
        end
    end
    
    local function okpress()
        save()
        cancel()
    end
    
    --~ code_gui.code_input_treeview:bind_onclick(change_event_input)
    code_gui.btn_cancel:connect( 'clicked', cancel)
    code_gui.btn_ok:connect( 'clicked', okpress)
    code_gui.btn_save:connect( 'clicked', save)
    code_gui.win:connect( 'delete-event', cancel)
    code_gui.help_view:connect( 'row-activated', select_help)
    
    code_gui.win:show_all()
end

function PropertyEditor:draw_interface()
    self:clear_interface()
    local order = {}
    for name, row in pairs( self.rows ) do
        order[#order +1] = name
    end
    table.sort( order )
    for pos, name in pairs( order ) do
        local row = self.rows[ name ]
        self.hboxs[#self.hboxs + 1] = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
        local label                 = gtk.Label.new_with_mnemonic( row.caption )
        label:set( 'width-request', self.label_w )
        self.hboxs[#self.hboxs]:pack_start( label, false, false, 0 )
        if row.type == 'entry' then
            row.entry = gtk.Entry.new()
            row.entry:connect( 'activate', entry_callback, { row = row, self = self } )
            row.entry:connect( 'focus-out-event', entry_callback, { row = row, self = self } )
            row.entry:set( 'width-request', self.value_w )
            self.hboxs[#self.hboxs]:pack_start( row.entry, true, true, 0 )
            row.entry:set_text( row.value )
        elseif row.type == 'combobox' then
            row.combobox = gtk.ComboBoxText.new()
            row.combobox:set( 'width-request', self.value_w )
            for k, dt in ipairs( row.itens ) do
                if type( dt ) == 'string' then
                    row.combobox:append_text( dt )
                elseif type( dt ) == 'table' then
                    row.combobox:append_text( dt.text or '' )
                end
            end
            if #row.itens > 0 then
                row.combobox:set('active', (row.value and row.value - 1) or (row.default and row.default - 1 or 0) )
            end
            row.combobox:connect( 'changed', combobox_callback, { row = row, self = self } )
            self.hboxs[#self.hboxs]:pack_start( row.combobox, true, true, 0 )
        elseif row.type == 'checkbox' then
            row.checkbox = gtk.CheckButton.new()
            row.checkbox:set( 'active', row.value or false )
            row.checkbox:connect( 'toggled', checkbox_callback, { row = row, self = self } )
            self.hboxs[#self.hboxs]:pack_start( row.checkbox, true, true, 0 )
        elseif row.type == 'color' then
            row.color = gtk.ColorButton.new( color )
            row.color:set_color( gdk.color_parse( row.value ) )
            row.color:connect( 'color-set', color_callback, { row = row, self = self } )
            self.hboxs[#self.hboxs]:pack_start( row.color, true, true, 0 )
        elseif row.type == 'code' then
            row.button = gtk.Button.new_with_label('...')
            row.button:connect( 'clicked', code_callback, { row = row, self = self })
            self.hboxs[#self.hboxs]:pack_start( row.button, true, true, 0 )
        elseif row.type == 'link' then
            row.button = gtk.Button.new_with_label('...')
            row.button:connect( 'clicked', link_callback, { row = row, self = self })
            self.hboxs[#self.hboxs]:pack_start( row.button, true, true, 0 )
        end
        self.vbox:pack_start( self.hboxs[#self.hboxs], false, false, 0 )
    end
    self.vbox:show_all()
end

function PropertyEditor:add_change_callback( fn, param )
    self.callback = { fn = fn, param = param }
end

function PropertyEditor:rm_row( name )
    self.rows[ name ] = nil
    if self.hboxs[ name ] then
        self.vbox:remove( self.hboxs[ name ] )
    end
    if self.rows[ name ] then
        self.rows[ name ] = nil
    end
end

function PropertyEditor:add_row_entry( name, caption, default, options, callback, param )
    self.rows[ name ] = {
        name     = name,
        type     = 'entry',
        caption  = caption,
        value    = default or '',
        callback = callback,
        param    = param,
        options  = options or {},
    }
end

function PropertyEditor:add_row_combobox( name, caption, default, itens, options, callback, param )
    if type(itens) == 'function' then
        itens = itens( options )
    end
    self.rows[ name ] = {
        name     = name,
        type     = 'combobox',
        caption  = caption,
        value    = default or 1,
        callback = callback,
        param    = param or {},
        options  = options or {},
        itens    = itens or {},
    }
end

function PropertyEditor:add_row_checkbox( name, caption, default, options, callback, param )
    self.rows[ name ] = {
        name     = name,
        type     = 'checkbox',
        caption  = caption,
        value    = default or false,
        callback = callback,
        options  = options or {},
        param    = param,
    }
end

function PropertyEditor:add_row_color( name, caption, default, options, callback, param )
    self.rows[ name ] = {
        name     = name,
        type     = 'color',
        caption  = caption,
        value    = default or '#FFFFFF',
        callback = callback,
        options  = options or {},
        param    = param,
    }
end

function PropertyEditor:add_row_code( name, caption, default, options, callback, param )
    self.rows[ name ] = {
        name     = name,
        type     = 'code',
        caption  = caption,
        value    = default or '',
        options  = options or {},
        callback = callback,
        param    = param,
    }
end

function PropertyEditor:add_row_link( name, caption, default, options, callback, param )
    self.rows[ name ] = {
        name     = name,
        type     = 'link',
        caption  = caption,
        value    = default or '',
        options  = options or {},
        callback = callback,
        param    = param,
    }
end

function PropertyEditor:change_combobox_itens( name, itens )
    if self.rows[ name ] and self.rows[ name ].type == 'combobox' then
        self.rows[ name ].itens = itens
    end
    self:draw_interface()
end

function PropertyEditor:set_value( name, value )
    if self.rows[ name ] then
        if self.rows[ name ].type == 'entry' then
            self.rows[ name ].entry:set_text( value )
        elseif self.rows[ name ].type == 'entry' then
            self.rows[ name ].combobox:set('active', value - 1)
        end
        self.rows[ name ].value = value
    end
end
