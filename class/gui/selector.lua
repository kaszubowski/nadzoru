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
    TODO:
    --text input: e.g. for automaton name
    --use multiple_selector in a language field (button)
--]]

--[[
module "Selector"
--]]
Selector = letk.Class( function( self, options, nowindow)
    options = table.complete( options or {}, {
        title      = 'nadzoru selector',
        success_fn = nil,
        no_cancel = nil,
    })
    self             = {}
    self.options     = options
    self.result      = {}
    self.num_columns = 0
    self.nowindow    = nowindow
    setmetatable( self, Selector )

    if not nowindow then
        self.window                   = gtk.Window.new( gtk.TOP_LEVEL )
    end
        self.vbox_main            = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
            self.hbox_main        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                if not nowindow then
                    self.hbox_footer      = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                        if not options.no_cancel then
                        	self.btn_cancel   = gtk.Button.new_with_label("Cancel")
                        end
                        self.btn_ok       = gtk.Button.new_with_label("OK")
                end

    if not nowindow then
        self.window:add(self.vbox_main)
    end
        self.vbox_main:pack_start( self.hbox_main, true, true, 0 )
            if not nowindow then
                self.vbox_main:pack_start( self.hbox_footer, false, false, 0 )
                    if not options.no_cancel then
                    	self.hbox_footer:pack_start( self.btn_cancel, true, true, 0 )
                    end
                    self.hbox_footer:pack_start( self.btn_ok, true, true, 0 )
            end

    if not nowindow then
        self.window:connect("delete-event", self.window.destroy, self.window)
        self.window:set_modal( true )
        if not options.no_cancel then
        	self.btn_cancel:connect("clicked", self.window.destroy, self.window )
        end
        self.btn_ok:connect("clicked", self.success, self)
    end

    return self, self.vbox_main
end, Object )

---TODO
--TODO
--@param self TODO
function Selector:success()
    if type(self.options.success_fn) == 'function' then
        local result = {}
        for c,k in ipairs( self.result ) do
            result[c] = k()
        end
        if not self.nowindow then
            self.window:destroy()
        end
        self.options.success_fn( result, #self.result, self, self.options.success_fn_param )
    else
        if not self.nowindow then
            self.window:destroy()
        end
    end
end

---TODO
--TODO
--@param self TODO
--@param options TODO
--@see Treeview:add_column_text
--@see Treeview:build
--@see Treeview:add_row
--@see Treeview:update
--@see Treeview:get_selected
--@see Treeview:remove_row
function Selector:multipler_selector( options )
    options = table.complete( options or {}, {
        list        = letk.List.new(),
        text_fn     = nil,
        filter_fn   = nil,
        text_input  = 'input',
        text_output = 'output',
        success_fn  = nil,
        cancel_fn   = nil,
        multiple    = false,
    })

    local window = gtk.Window.new( gtk.TOP_LEVEL )
        local vbox_main               = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
            local hbox_main           = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                local input           = Treeview.new()
                    :add_column_text(options.text_input, 150)
                local vbox_buttons    = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                    local btn_add     = gtk.Button.new_with_label(">")
                    --local btn_add_all = gtk.Button.new_with_label(">>")
                    local btn_rm      = gtk.Button.new_with_label("<")
                    --local btn_rm_all  = gtk.Button.new_with_label("<<")
                local output          = Treeview.new()
                    :add_column_text(options.text_output, 150)
            local hbox_footer         = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
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
        if type(options.filter_fn) ~= 'function' or options.filter_fn( v ) then
            list_input:append( v )
            input:add_row{ type(options.text_fn) == 'function' and options.text_fn( v ) or tostring( v ) }
        end
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

---Adds a combobox to the selector.
--TODO
--@param self Selector in which the combobox is added.
--@param options Table containing the parameters of the combobox.
--@return Selector with the combobox.
function Selector:add_combobox( options )
    options = table.complete( options or {}, {
        list        = letk.List.new(),
        text_fn     = nil,
        filter_fn   = nil,
        result_fn   = nil,
        text        = 'input',
    })
    options.valid_list = letk.List.new()

    if not self.single_box then
        self.single_box = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.hbox_main:pack_start( self.single_box , true, true, 0 )
        self.num_columns = self.num_columns + 1
    end

    local label    = gtk.Label.new_with_mnemonic( options.text )
    local combobox = gtk.ComboBoxText.new()
    for k, v in options.list:ipairs() do
        if type(options.filter_fn) ~= 'function' or options.filter_fn( v ) then
            combobox:append_text(type(options.text_fn) == 'function' and options.text_fn( v ) or tostring( v ) )
            options.valid_list:append( v )
        end
    end

    if options.valid_list:len() > 0 then
        combobox:set('active', 0)
    end

    self.single_box:pack_start( label , false, false, 0 )
    self.single_box:pack_start( combobox , false, false, 0 )
    self.result[#self.result + 1] = function()
        local v = options.valid_list:get( combobox:get_active() + 1 )
        return type(options.result_fn) == 'function' and options.result_fn( v ) or v
    end

    return self
end

---TODO
--TODO
--@param self TODO
--@param options TODO
--@return TODO
--@see Treeview:add_column_text
--@see Treeview:add_row
--@see Treeview:get_selected
--@see Treeview:build
--@see Treeview:update
function Selector:add_multipler( options )
    options = table.complete( options or {}, {
        list        = letk.List.new(),
        text_fn     = nil,
        filter_fn   = nil,
        text        = 'input',
    })
    local treeview = Treeview.new( true )
        :add_column_text(options.text)
    for k, v in options.list:ipairs() do
        if type(options.filter_fn) ~= 'function' or options.filter_fn( v ) then
            treeview:add_row{ type( options.text_fn ) == 'function' and options.text_fn( v ) or tostring( v ) }
        end
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

---Adds a checkbox to the selector.
--TODO
--@param self Selector in which the checkbox is added.
--@param options Table containing the parameters of the checkbox.
--@return Selector with the checkbox.
function Selector:add_checkbox( options )
     options = table.complete( options or {}, {
        text        = 'input',
    })
    local checkbutton = gtk.CheckButton.new_with_mnemonic( options.text )
    if not self.single_box then
        self.single_box = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.hbox_main:pack_start( self.single_box , true, true, 0 )
        self.num_columns = self.num_columns + 1
    end
    self.single_box:pack_start( checkbutton , false, false, 0 )
    self.result[#self.result + 1] = function()
        return checkbutton:get_active()
    end

    return self
end

---TODO
--TODO
--@param self TODO
--@param options TODO
--@return TODO
function Selector:add_file( options )
     options = table.complete( options or {}, {
        text        = 'input',
        method      = gtk.FILE_CHOOSER_ACTION_SAVE,
        title       = "...",
        filter      = nil,
        filter_name = nil,
    })
    local vbox_file = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        local label_info = gtk.Label.new_with_mnemonic( options.text )
        local button     = gtk.Button.new( )
            local hbox_btn  = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                local btn_img   = gtk.Image.new_from_icon_name( 'gtk-file', gtk.ICON_SIZE_BUTTON )
                local btn_label = gtk.Label.new_with_mnemonic( "..." )

    local dialog = gtk.FileChooserDialog.new(
        options.title, 
        self.window,
        options.method,
        'gtk-cancel', gtk.RESPONSE_CANCEL,
        'gtk-ok', gtk.RESPONSE_OK
    )
    
    local useFilter = options.filter and ( options.method == gtk.FILE_CHOOSER_ACTION_OPEN or options.method == gtk.FILE_CHOOSER_ACTION_SAVE ) 
    if useFilter then
        local filter = gtk.FileFilter.new()
        filter:add_pattern('*.' .. options.filter)
        filter:set_name( options.filter_name or options.filter )
        dialog:add_filter( filter )
    end
    local file = ''
    if not self.single_box then
        self.single_box = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.hbox_main:pack_start( self.single_box , true, true, 0 )
        self.num_columns = self.num_columns + 1
    end
    self.single_box:pack_start( vbox_file , false, false, 0 )
        vbox_file:pack_start( label_info , false, false, 0 )
        vbox_file:pack_start( button , false, false, 0 )
            button:add( hbox_btn )
                hbox_btn:pack_start( btn_img , false, false, 0 )
                hbox_btn:pack_start( btn_label , true, true, 0 )

    button:connect( 'clicked', function()
        local response = dialog:run()
        dialog:hide()
        local names = dialog:get_filenames()
        if response == gtk.RESPONSE_OK and names and names[1] then
            if useFilter then
                if not names[1]:match( '%.' .. options.filter .. '$' ) then
                    names[1] = names[1] .. '.' .. options.filter
                end
            end
            local display = (#names[1] <= 25) and names[1] or (names[1]:sub(1,5) .. "..." .. names[1]:sub(-17,-1))
            btn_label:set_text   ( display )
            file = names[1]
        end
    end)

    self.result[#self.result + 1] = function()
        return file
    end

    return self
end

---TODO
--Unfinished. TODO
--@param self TODO
--@param options TODO
--@return TODO
function Selector:add_spin( options )
     options = table.complete( options or {}, {
        text        = 'input',
        min_value = 0,
        max_value = 100,
        step      = 1,
        digits    = 0,
    })
   
   local vbox_spin      = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        local label_spin = gtk.Label.new_with_mnemonic( options.text )
        local spinbutton = gtk.SpinButton.new_with_range( options.min_value, options.max_value, options.step )
   
    spinbutton:set_digits( options.digits )
    
    if not self.single_box then
        self.single_box = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.hbox_main:pack_start( self.single_box , true, true, 0 )
        self.num_columns = self.num_columns + 1
    end
    
    self.single_box:pack_start( vbox_spin , false, false, 0 )
        vbox_spin:pack_start( label_spin , false, false, 0 )
        vbox_spin:pack_start( spinbutton , false, false, 0 )
    
    self.result[#self.result + 1] = function()
        return spinbutton:get_value()
    end

    return self
end

---Runs the selector.
--TODO
--@param self Selector to be run.
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
    
    return self
end
