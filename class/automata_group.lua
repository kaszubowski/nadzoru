AutomataGroup = letk.Class( function( self )
    Object.__super( self )
    
    self.automata_file = {
        g = {},
        e = {},
        k = {},
        s = {},
        x = {}
    }
    self.automata_object = nil
    self:set('file_name', '*new automata group' )
end, Object )

AutomataGroup.__TYPE = 'automatagroup'

function AutomataGroup:load_automata( element_list )
    self.automata_object = {}
    for k, v in element_list:ipairs() do
        if v.__TYPE == 'automaton' then
            local file_nm = v:get( 'file_name' )
            if file_nm and (
                self.automata_file.g[ file_nm ] or
                self.automata_file.e[ file_nm ] or
                self.automata_file.k[ file_nm ] or
                self.automata_file.s[ file_nm ] or
                self.automata_file.x[ file_nm ]
            ) then
                self.automata_object[ file_nm ] = v
            end
        end
    end
end

function AutomataGroup:check_automata()
    for t, l in pairs( self.automata_file ) do
        for name, const in pairs( l ) do
            if not self.automata_object[ name ] then
                return false
            end
        end
    end
    return true
end

function AutomataGroup:save_serialize()
    local data = {}
    
    for t, l in pairs( self.automata_file ) do
        data[ t ] = {}
        for name, const in pairs( l ) do
            data[ t ][ name ] = true
        end
    end

    return letk.serialize( data )
end
local FILE_ERROS = {}
FILE_ERROS.ACCESS_DENIED     = 1
FILE_ERROS.NO_FILE_NAME      = 2
FILE_ERROS.INVALID_FILE_TYPE = 3

function AutomataGroup:save()
    local file_type = self:get( 'file_type' )
    local file_name = self:get( 'full_file_name' )
    if file_type == 'nag' and file_name then
        if not file_name:match( '%.nag$' ) then
            file_name = file_name .. '.nag'
        end
        local file = io.open( file_name, 'w')
        if file then
            local code = self:save_serialize()
            file:write( code )
            file:close()
            return true
        end
        return false, FILE_ERROS.ACCESS_DENIED, FILE_ERROS
    elseif not file_type then
        return false, FILE_ERROS.NO_FILE_NAME, FILE_ERROS
    else
        return false, FILE_ERROS.INVALID_FILE_TYPE, FILE_ERROS
    end
end

function AutomataGroup:save_as( file_name )
    if file_name then
        if not file_name:match( '%.nag$' ) then
            file_name = file_name .. '.nag'
        end
        local file = io.open( file_name, 'w')
        if file then
            local code = self:save_serialize()
            file:write( code )
            file:close()
            self:set( 'file_type', 'nag' )
            self:set( 'full_file_name', file_name )
            self:set( 'file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
            return true
        end
        return false, FILE_ERROS.ACCESS_DENIED, FILE_ERROS
    else
        return false, FILE_ERROS.NO_FILE_NAME, FILE_ERROS
    end
end

function AutomataGroup:load_file( file_name )
    local file = io.open( file_name, 'r')
    if file then
        local s    = file:read('*a')
        local data = loadstring('return ' .. s)()
        if data then            
            for t, l in pairs( data ) do
                for name, const in pairs( l ) do
                    self.automata_file[ t ][ name ] = true
                end
            end

            self:set( 'file_type', 'nag' )
            self:set( 'full_file_name', file_name )
            self:set( 'file_name', select( 3, file_name:find( '.-([^/^\\]*)$' ) ) )
            return true
        end
        return false
    end
    return false
end

------------------------GUI---------------------------------------------

AutomataGroupEditor = letk.Class( function( self, gui, automata_group, elements )
    Object.__super( self )
    self.gui            = gui
    self.automata_group = automata_group
    self.elements       = elements

    self:build_gui()
end, Object )

function AutomataGroupEditor:build_gui()
        self.AWgui = {}
        self.AWgui.vbox                          = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
            self.AWgui.hbox                      = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            
                self.AWgui.treeview_automata     = Treeview.new( true )
                
                self.AWgui.vbox_g                = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                    self.AWgui.label_g           = gtk.Label.new_with_mnemonic( "G" )
                    self.AWgui.hbox_g_btn        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                        self.AWgui.btn_g_add     = gtk.Button.new_from_stock('gtk-add')
                        self.AWgui.btn_g_rm      = gtk.Button.new_from_stock('gtk-delete')
                    self.AWgui.treeview_g        = Treeview.new( true )
                    
                self.AWgui.vbox_e                = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                    self.AWgui.label_e           = gtk.Label.new_with_mnemonic( "E" )
                    self.AWgui.hbox_e_btn        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                        self.AWgui.btn_e_add     = gtk.Button.new_from_stock('gtk-add')
                        self.AWgui.btn_e_rm      = gtk.Button.new_from_stock('gtk-delete')
                    self.AWgui.treeview_e       = Treeview.new( true )
                    
                self.AWgui.vbox_k                = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                    self.AWgui.label_k           = gtk.Label.new_with_mnemonic( "K" )
                    self.AWgui.hbox_k_btn        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                        self.AWgui.btn_k_add     = gtk.Button.new_from_stock('gtk-add')
                        self.AWgui.btn_k_rm      = gtk.Button.new_from_stock('gtk-delete')
                    self.AWgui.treeview_k        = Treeview.new( true )
                    
                self.AWgui.vbox_s                = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                    self.AWgui.label_s           = gtk.Label.new_with_mnemonic( "S" )
                    self.AWgui.hbox_s_btn        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                        self.AWgui.btn_s_add     = gtk.Button.new_from_stock('gtk-add')
                        self.AWgui.btn_s_rm      = gtk.Button.new_from_stock('gtk-delete')
                    self.AWgui.treeview_s        = Treeview.new( true )
                    
                self.AWgui.vbox_x                = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                    self.AWgui.label_x           = gtk.Label.new_with_mnemonic( "Exclusive AFD" )
                    self.AWgui.hbox_x_btn        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                        self.AWgui.btn_x_add     = gtk.Button.new_from_stock('gtk-add')
                        self.AWgui.btn_x_rm      = gtk.Button.new_from_stock('gtk-delete')
                    self.AWgui.treeview_x        = Treeview.new( true )
                    
        self.AWgui.hbox_btn                      = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.AWgui.btn_refresh               = gtk.Button.new_with_label("Refresh Automata")
            self.AWgui.btn_save                  = gtk.Button.new_with_label("Save")
            self.AWgui.btn_save_as               = gtk.Button.new_with_label("Save As")
            
    self.AWgui.treeview_automata:add_column_text( "Automaton",120 )
    self.AWgui.treeview_g:add_column_text( "Automaton",120 )
    self.AWgui.treeview_e:add_column_text( "Automaton",120 )
    self.AWgui.treeview_k:add_column_text( "Automaton",120 )
    self.AWgui.treeview_s:add_column_text( "Automaton",120 )
    self.AWgui.treeview_x:add_column_text( "Automaton",120 )
            
    self.AWgui.vbox:pack_start( self.AWgui.hbox, true, true, 0 )
        self.AWgui.hbox:pack_start( self.AWgui.treeview_automata:build{width = 120}, true, true, 0 )
        
        self.AWgui.hbox:pack_start( self.AWgui.vbox_g, true, true, 0 )
            self.AWgui.vbox_g:pack_start( self.AWgui.label_g, false, false, 0 )
            self.AWgui.vbox_g:pack_start( self.AWgui.hbox_g_btn, false, false, 0 )
                self.AWgui.hbox_g_btn:pack_start( self.AWgui.btn_g_add, true, true, 0 )
                self.AWgui.hbox_g_btn:pack_start( self.AWgui.btn_g_rm, true, true, 0 )
            self.AWgui.vbox_g:pack_start( self.AWgui.treeview_g:build(), true, true, 0 )
        
        self.AWgui.hbox:pack_start( self.AWgui.vbox_e, true, true, 0 )
            self.AWgui.vbox_e:pack_start( self.AWgui.label_e, false, false, 0 )
            self.AWgui.vbox_e:pack_start( self.AWgui.hbox_e_btn, false, false, 0 )
                self.AWgui.hbox_e_btn:pack_start( self.AWgui.btn_e_add, true, true, 0 )
                self.AWgui.hbox_e_btn:pack_start( self.AWgui.btn_e_rm, true, true, 0 )
            self.AWgui.vbox_e:pack_start( self.AWgui.treeview_e:build(), true, true, 0 )
        
        self.AWgui.hbox:pack_start( self.AWgui.vbox_k, true, true, 0 )
            self.AWgui.vbox_k:pack_start( self.AWgui.label_k, false, false, 0 )
            self.AWgui.vbox_k:pack_start( self.AWgui.hbox_k_btn, false, false, 0 )
                self.AWgui.hbox_k_btn:pack_start( self.AWgui.btn_k_add, true, true, 0 )
                self.AWgui.hbox_k_btn:pack_start( self.AWgui.btn_k_rm, true, true, 0 )
            self.AWgui.vbox_k:pack_start( self.AWgui.treeview_k:build(), true, true, 0 )
            
        self.AWgui.hbox:pack_start( self.AWgui.vbox_s, true, true, 0 )
            self.AWgui.vbox_s:pack_start( self.AWgui.label_s, false, false, 0 )
            self.AWgui.vbox_s:pack_start( self.AWgui.hbox_s_btn, false, false, 0 )
                self.AWgui.hbox_s_btn:pack_start( self.AWgui.btn_s_add, true, true, 0 )
                self.AWgui.hbox_s_btn:pack_start( self.AWgui.btn_s_rm, true, true, 0 )
            self.AWgui.vbox_s:pack_start( self.AWgui.treeview_s:build(), true, true, 0 )
            
        self.AWgui.hbox:pack_start( self.AWgui.vbox_x, true, true, 0 )
            self.AWgui.vbox_x:pack_start( self.AWgui.label_x, false, false, 0 )
            self.AWgui.vbox_x:pack_start( self.AWgui.hbox_x_btn, false, false, 0 )
                self.AWgui.hbox_x_btn:pack_start( self.AWgui.btn_x_add, true, true, 0 )
                self.AWgui.hbox_x_btn:pack_start( self.AWgui.btn_x_rm, true, true, 0 )
            self.AWgui.vbox_x:pack_start( self.AWgui.treeview_x:build(), true, true, 0 )
                
    self.AWgui.vbox:pack_start( self.AWgui.hbox_btn, false, false, 0 )
        self.AWgui.hbox_btn:pack_start( self.AWgui.btn_refresh, true, true, 0 )
        self.AWgui.hbox_btn:pack_start( self.AWgui.btn_save, true, true, 0 )
        self.AWgui.hbox_btn:pack_start( self.AWgui.btn_save_as, true, true, 0 )
        
        local function AWgui_add( opt )
            local positions = self.AWgui.treeview_automata:get_selected()
            for k,v in ipairs( positions ) do
                self.automata_group.automata_file[ opt ][ self.AWgui.automata.all[v] ] = true
            end
            self:update_automaton_window()
        end
        self.AWgui.btn_g_add:connect('clicked', AWgui_add, 'g') 
        self.AWgui.btn_e_add:connect('clicked', AWgui_add, 'e') 
        self.AWgui.btn_k_add:connect('clicked', AWgui_add, 'k') 
        self.AWgui.btn_s_add:connect('clicked', AWgui_add, 's') 
        self.AWgui.btn_x_add:connect('clicked', AWgui_add, 'x') 
        
        self.AWgui.btn_refresh:connect('clicked', self.start_automaton_window, self) 
        
        self.AWgui.btn_save:connect('clicked', self.save, self) 
        self.AWgui.btn_save_as:connect('clicked', self.save_as, self) 
        
        local function AWgui_rm( opt )
            local positions = self.AWgui['treeview_' .. opt]:get_selected()
            for k,v in ipairs( positions ) do
                self.automata_group.automata_file[ opt ][ self.AWgui.automata[ opt ][v] ] = nil
            end
            self:update_automaton_window()
        end
        self.AWgui.btn_g_rm:connect('clicked', AWgui_rm, 'g') 
        self.AWgui.btn_e_rm:connect('clicked', AWgui_rm, 'e') 
        self.AWgui.btn_k_rm:connect('clicked', AWgui_rm, 'k') 
        self.AWgui.btn_s_rm:connect('clicked', AWgui_rm, 's') 
        self.AWgui.btn_x_rm:connect('clicked', AWgui_rm, 'x') 
        
        self.gui:add_tab( self.AWgui.vbox, "edit " .. (self.automata_group:get('file_name') or "-x-") )
end

function AutomataGroupEditor:start_automaton_window()
    if not self.AWgui then return end
    self.AWgui.treeview_automata:clear_data()
    
    self.AWgui.automata = {
        all = {},
    }
    
    for k, v in self.elements:ipairs() do
        if v.__TYPE == 'automaton' then
            self.AWgui.automata.all[#self.AWgui.automata.all + 1] = v:get( 'file_name' )
        end
    end
    table.sort( self.AWgui.automata.all )
    for k,v in ipairs( self.AWgui.automata.all ) do
        self.AWgui.treeview_automata:add_row{ v }
    end
    self.AWgui.treeview_automata:update()
end

function AutomataGroupEditor:update_automaton_window()
    if not self.AWgui then return end
    self.AWgui.treeview_g:clear_data()
    self.AWgui.treeview_e:clear_data()
    self.AWgui.treeview_k:clear_data()
    self.AWgui.treeview_s:clear_data()
    self.AWgui.treeview_x:clear_data()

    self.AWgui.automata.g = {}
    self.AWgui.automata.e = {}
    self.AWgui.automata.k = {}
    self.AWgui.automata.s = {}
    self.AWgui.automata.x = {}
    
    for kp, p in ipairs{'g','e','k','s','x'} do
        for v, s in pairs( self.automata_group.automata_file[p] ) do
            self.AWgui.automata[p][#self.AWgui.automata[p] + 1] = v
        end
        table.sort( self.AWgui.automata[p] )
        for k,v in ipairs( self.AWgui.automata[p] ) do
            self.AWgui['treeview_' .. p]:add_row{ v }
        end
        self.AWgui['treeview_' .. p]:update()
    end
end

function AutomataGroupEditor:save_as()
    local dialog = gtk.FileChooserDialog.new(
        "Save AS", nil,gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.nag")
    filter:set_name("Nadzoru Automata Group")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        local status, err, err_list = self.automata_group:save_as( names[1] )
        if not status then
            if err == err_list.ACCESS_DENIED then
                gtk.InfoDialog.showInfo("Access denied for file: " .. tostring(self.automata_group:get('full_file_name')) )
            end
        else
            self.gui:set_tab_page_title( self.AWgui.vbox, "edit " .. (self.automata_group:get('file_name') or "-x-") )
        end
    end
end

function AutomataGroupEditor:save()
    local status, err, err_list = self.automata_group:save()
    if not status then
        if err == err_list.NO_FILE_NAME then
            self:save_as()
        elseif err == err_list.INVALID_FILE_TYPE then
            gtk.InfoDialog.showInfo("This plant is not a .nag, use 'save as'")
        elseif err == err_list.ACCESS_DENIED then
            gtk.InfoDialog.showInfo("Access denied for file: " .. tostring(self.automata_group:get('full_file_name')) )
        end
    end
end
