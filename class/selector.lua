--[[
    TODO:
    --text input: e.g. for automaton name
    --use multiple_selector in a language field (button)
--]]

Selector = letk.Class( function( self, options, nowindow )
    options = table.complete( options or {}, {
        title      = 'nadzoru selector',
        success_fn = nil,
    })
    self             = {}
    self.options     = options
    self.result      = {}
    self.num_columns = 0
    setmetatable( self, Selector )

    if not nowindow then
        self.window                   = gtk.Window.new( gtk.TOP_LEVEL )
    end
        self.vbox_main            = gtk.VBox.new(false, 0)
            self.hbox_main        = gtk.HBox.new(false, 0)
            self.hbox_footer      = gtk.HBox.new(true, 0)
                if not nowindow then
                    self.btn_cancel   = gtk.Button.new_with_label("Cancel")
                end
                self.btn_ok       = gtk.Button.new_with_label("OK")

    if not nowindow then
        self.window:add(self.vbox_main)
    end
        self.vbox_main:pack_start( self.hbox_main, true, true, 0 )
        self.vbox_main:pack_start( self.hbox_footer, false, false, 0 )
            if not nowindow then
                self.hbox_footer:pack_start( self.btn_cancel, false, true, 0 )
            end
            self.hbox_footer:pack_start( self.btn_ok, false, true, 0 )

    if not nowindow then
    self.window:connect("delete-event", self.window.destroy, self.window)
    self.window:set_modal( true )
    end

    function success()
        if type(options.success_fn) == 'function' then
            local result = {}
            for c,k in ipairs( self.result ) do
                result[c] = k()
            end
            if not nowindow then
                self.window:destroy()
            end
            options.success_fn( result, #self.result, self )
        end
    end

    if not nowindow then
        self.btn_cancel:connect("clicked", self.window.destroy, self.window )
    end
    self.btn_ok:connect("clicked", success)

    return self, self.vbox_main
end, Object )

function Selector:multipler_selector( options )
    options = table.complete( options or {}, {
        list        = letk.List.new(),
        text_fn     = nil,
        text_input  = 'input',
        text_output = 'output',
        success_fn  = nil,
        cancel_fn   = nil,
        multiple    = false,
    })

    local window = gtk.Window.new( gtk.TOP_LEVEL )
        local vbox_main               = gtk.VBox.new(false, 0)
            local hbox_main           = gtk.HBox.new(false, 0)
                local input           = Treeview.new()
                    :add_column_text(options.text_input, 150)
                local vbox_buttons    = gtk.VBox.new(false, 0)
                    local btn_add     = gtk.Button.new_with_label(">")
                    --local btn_add_all = gtk.Button.new_with_label(">>")
                    local btn_rm      = gtk.Button.new_with_label("<")
                    --local btn_rm_all  = gtk.Button.new_with_label("<<")
                local output          = Treeview.new()
                    :add_column_text(options.text_output, 150)
            local hbox_footer         = gtk.HBox.new(true, 0)
                local btn_cancel      = gtk.Button.new_with_label("Cancel")
                local btn_ok          = gtk.Button.new_with_label("OK")

    window:add(vbox_main)
        vbox_main:pack_start( hbox_main, true, true, 0 )
            hbox_main:pack_start( input:build(), true, true, 0 )
            hbox_main:pack_start( vbox_buttons, false, false, 10 )
                vbox_buttons:pack_start( btn_add, false, true, 12 )
                --vbox_buttons:pack_start( btn_add_all, false, true, 12 )
                vbox_buttons:pack_start( btn_rm, false, true, 12 )
                --vbox_buttons:pack_start( btn_rm_all, false, true, 12 )
            hbox_main:pack_start( output:build(), true, true, 0 )
        vbox_main:pack_start( hbox_footer, false, false, 0 )
            hbox_footer:pack_start( btn_cancel, false, true, 0 )
            hbox_footer:pack_start( btn_ok, false, true, 0 )

    window:set("width-request", 400,
        "height-request", 300, "window-position", gtk.WIN_POS_CENTER,
        "icon-name", "gtk-about")

    window:set_modal( true )
    window:show_all()

    window:connect("delete-event", window.destroy, window)
    --btn_cancel:connect("clicked", function())

    local list_input  = letk.List.new()
    local list_output = letk.List.new()

    for k, v in options.list:ipairs() do
        list_input:append( v )
        input:add_row{ type(options.text_fn) == 'function' and options.text_fn( v ) or tostring( v ) }
    end
    input:update()

    local function add_selected()
        local pos = input:get_selected()
        if pos then
            local data = list_input:get( pos )
            list_output:append( data )
            output:add_row{ type(options.text_fn) == 'function' and options.text_fn( data ) or tostring( data ) }
            output:update()
            if not options.multiple then
                list_input:remove( pos )
                input:remove_row( pos )
                input:update()
            end
        end
    end

    local function rm_selected()
        local pos = output:get_selected()
        if pos then
            local data = list_output:get( pos )
            list_output:remove( pos )
            output:remove_row( pos )
            output:update()
            if not options.multiple then
                list_input:append( data )
                input:add_row{ type(options.text_fn) == 'function' and options.text_fn( data ) or tostring( data ) }
                input:update()
            end
        end
    end

    btn_add:connect("clicked", add_selected)
    btn_rm:connect("clicked", rm_selected)
    btn_cancel:connect("clicked", function()
        if type(options.cancel_fn) == 'function' then
            options.cancel_fn(list_output)
        end
        window:destroy()
    end)
    btn_ok:connect("clicked", function()
        if type(options.success_fn) == 'function' then
            options.success_fn(list_output)
        end
        window:destroy()
    end)
end

function Selector:add_combobox( options )
    options = table.complete( options or {}, {
        list        = letk.List.new(),
        text_fn     = nil,
        result_fn   = nil,
        text        = 'input',
    })

    if not self.single_box then
        self.single_box = gtk.VBox.new(false, 0)
        self.hbox_main:pack_start( self.single_box , true, true, 0 )
        self.num_columns = self.num_columns + 1
    end

    local label    = gtk.Label.new_with_mnemonic( options.text )
    local combobox = gtk.ComboBox.new_text( )
    for k, v in options.list:ipairs() do
        combobox:append_text(type(options.text_fn) == 'function' and options.text_fn( v ) or tostring( v ) )
    end

    self.single_box:pack_start( label , false, false, 0 )
    self.single_box:pack_start( combobox , false, false, 0 )
    self.result[#self.result + 1] = function()
        local v = options.list:get( combobox:get_active() + 1 )
        return type(options.result_fn) == 'function' and options.result_fn( v ) or v
    end

    return self
end

function Selector:add_multipler( options )
    options = table.complete( options or {}, {
        list        = letk.List.new(),
        text_fn     = nil,
        text        = 'input',
    })
    local treeview = Treeview.new( true )
        :add_column_text(options.text)
    for k, v in options.list:ipairs() do
        treeview:add_row{ type( options.text_fn ) == 'function' and options.text_fn( v ) or tostring( v ) }
    end
    self.result[#self.result + 1] = function()
        local selecteds_pos = treeview:get_selected()
        local result = {}
        for c,v in ipairs( selecteds_pos ) do
            result[#result + 1] = options.list:get( v )
        end
        return result
    end
    self.hbox_main:pack_start( treeview:build() , true, true, 0 )
    treeview:update()
    self.num_columns = self.num_columns + 1
    return self
end

function Selector:add_checkbox( options )
     options = table.complete( options or {}, {
        text        = 'input',
    })
    local checkbutton = gtk.CheckButton.new_with_mnemonic( options.text )
    if not self.single_box then
        self.single_box = gtk.VBox.new(false, 0)
        self.hbox_main:pack_start( self.single_box , true, true, 0 )
        self.num_columns = self.num_columns + 1
    end
    self.single_box:pack_start( checkbutton , false, false, 0 )
    self.result[#self.result + 1] = function()
        return checkbutton:get_active()
    end

    return self
end

function Selector:add_file( options )
     options = table.complete( options or {}, {
        text        = 'input',
    })
    local vbox_file = gtk.VBox.new(false, 0)
        local label_info     = gtk.Label.new_with_mnemonic( options.text )
        local hbox_file      = gtk.HBox.new(false, 5)
            local label_file = gtk.Label.new( )
            local button     = gtk.Button.new_with_mnemonic( '...' )

    local dialog = gtk.FileChooserDialog.new(
        "Create the file", self.window,gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local file = ''
    if not self.single_box then
        self.single_box = gtk.VBox.new(false, 0)
        self.hbox_main:pack_start( self.single_box , true, true, 0 )
        self.num_columns = self.num_columns + 1
    end
    self.single_box:pack_start( vbox_file , false, false, 0 )
        vbox_file:pack_start( label_info , false, false, 0 )
        vbox_file:pack_start( hbox_file , false, false, 0 )
            hbox_file:pack_start( label_file , true, true, 0 )
            hbox_file:pack_start( button , false, false, 0 )

    button:connect( 'clicked', function()
        local response = dialog:run()
        dialog:hide()
        local names = dialog:get_filenames()
        if response == gtk.RESPONSE_OK and names and names[1] then
            local display = (#names[1] <= 25) and names[1] or (names[1]:sub(1,5) .. '...' .. names[1]:sub(-17,-1))
            label_file:set_text( display )
            file = names[1]
        end
    end)

    self.result[#self.result + 1] = function()
        return file
    end

    return self
end

function Selector:add_spin( options )

end

function Selector:run()
    if not nowindow then
        local nc = self.num_columns
        if nc == 0 then nc = 1 end
        if nc > 5 then nc  = 5 end

        self.window:set("title", self.options.title, "width-request", nc * 200,
            "height-request", 450, "window-position", gtk.WIN_POS_CENTER,
            "icon-name", "gtk-about")

        self.window:show_all()
    end
end
