ScriptGui = letk.Class( function( self, elements )
    Object.__super( self )

    self.elements  = elements
    self.scriptEnv = ScriptEnv.new( elements )
    self.scriptEnv:setPrintCallback( self.print, self )
end, Object )

function ScriptGui:buildGui( gui )
    self.gui       = gui
    self.scriptGui = {}

    self.scriptGui.vbox         = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.scriptGui.paned  = gtk.Paned.new( gtk.ORIENTATION_VERTICAL )
            self.scriptGui.hbox         = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
                --help
                --code
            --Info
        self.scriptGui.hbox_footer  = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.scriptGui.btn_cleanInfo    = gtk.Button.new_with_label("Clean Info")
            self.scriptGui.btn_refresh  = gtk.Button.new_with_label("Refresh Elements")
            self.scriptGui.btn_load     = gtk.Button.new_with_label("Load Script")
            self.scriptGui.btn_save     = gtk.Button.new_with_label("Save Script")
            self.scriptGui.btn_run      = gtk.Button.new_with_label("Run")
        
    --~ self.scriptGui.separator        = gtk.Separator.new(gtk.ORIENTATION_HORIZONTAL);

    self.scriptGui.paned:set_position(600)

    --Help:
    self.scriptGui.scroll_help         = gtk.ScrolledWindow.new()
        self.scriptGui.help_view       = gtk.TreeView.new()

    self.scriptGui.scroll_help:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.scriptGui.scroll_help:set('width-request', 250 )
    self.scriptGui.help_model      = gtk.TreeStore.new('gchararray','gchararray','gint')
    self.scriptGui.help_col1       = gtk.TreeViewColumn.new_with_attributes("Script help", gtk.CellRendererText.new(), "text", 0)
    self.scriptGui.help_selection  = self.scriptGui.help_view:get_selection()
    
    self.scriptGui.help_view:append_column(self.scriptGui.help_col1)
    self.scriptGui.help_view:set('model', self.scriptGui.help_model)
    self.scriptGui.help_selection:set_mode(gtk.SELECTION_SINGLE)

    --Code:
    self.scriptGui.code_view     = gtk.SourceView.new()
    self.scriptGui.code_buffer   = self.scriptGui.code_view:get('buffer')
    self.scriptGui.code_manager  = gtk.source_language_manager_get_default()
    self.scriptGui.code_lang     = self.scriptGui.code_manager:get_language('c')
    self.scriptGui.code_scroll   = gtk.ScrolledWindow.new()
    self.scriptGui.code_view:set('show-line-numbers', true, 'highlight-current-line', true, 'auto-indent', true)
    self.scriptGui.code_scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.scriptGui.code_scroll:add(self.scriptGui.code_view)
    self.scriptGui.code_buffer:set('language', self.scriptGui.code_lang)

    --Info:
    self.scriptGui.info_view     = gtk.TextView.new()
    self.scriptGui.info_buffer   = self.scriptGui.info_view:get('buffer')
    self.scriptGui.scroll_info   = gtk.ScrolledWindow.new()
    self.scriptGui.scroll_info:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.scriptGui.scroll_info:add(self.scriptGui.info_view)
    self.scriptGui.info_view:set_editable(false)


    
    self.scriptGui.vbox:pack_start( self.scriptGui.paned, true, true, 0 )
        self.scriptGui.paned:add1( self.scriptGui.hbox )
            self.scriptGui.hbox:pack_start( self.scriptGui.scroll_help, false, false, 0 )
                self.scriptGui.scroll_help:add(self.scriptGui.help_view)
            self.scriptGui.hbox:pack_start( self.scriptGui.code_scroll, true, true, 0 )
        self.scriptGui.paned:add2( self.scriptGui.scroll_info )
    self.scriptGui.vbox:pack_start( self.scriptGui.hbox_footer, false, false, 0 )
        self.scriptGui.hbox_footer:pack_start( self.scriptGui.btn_cleanInfo, true, true, 0 )
        self.scriptGui.hbox_footer:pack_start( self.scriptGui.btn_refresh, true, true, 0 )
        self.scriptGui.hbox_footer:pack_start( self.scriptGui.btn_load, true, true, 0 )
        self.scriptGui.hbox_footer:pack_start( self.scriptGui.btn_save, true, true, 0 )
        self.scriptGui.hbox_footer:pack_start( self.scriptGui.btn_run, true, true, 0 )


    self.scriptGui.btn_cleanInfo:connect('clicked', self.cleanInfo, self )
    self.scriptGui.btn_refresh:connect('clicked', self.refresh, self )
    self.scriptGui.btn_load:connect('clicked', self.loadScript, self )
    self.scriptGui.btn_save:connect('clicked', self.saveScript, self )
    self.scriptGui.btn_run:connect('clicked', self.run, self )
    self.scriptGui.help_view:connect( 'row-activated', self.select_help, self)

    self:refresh()

    gui:add_tab( self.scriptGui.vbox, 'Script' )
end

function ScriptGui:updateHelp( tbl )
    --~ local function add_help( tbl, dad )
        --~ local iter = gtk.TreeIter.new()
        --~ for k, v in ipairs( tbl ) do
            --~ self.scriptGui.help_model:append(iter, dad)
            --~ self.scriptGui.help_model:set(iter, 0, v.caption, 1, v.value or '')
            --~ add_help( v, iter )
        --~ end
    --~ end
    local iterMain = gtk.TreeIter.new()
    local iter     = gtk.TreeIter.new()
    
    self.scriptGui.help_model:append( iterMain )
    self.scriptGui.help_model:set( iterMain, 0, "Functions", 1, '', 2, 0 )
    local envFunctions = {}
    for functionName, fn in pairs( self.scriptEnv.fnEnv ) do
        table.insert( envFunctions, functionName )
    end
    table.sort( envFunctions, function(a,b)
        return a < b
    end )
    for k_functionName, functionName in ipairs( envFunctions ) do
        self.scriptGui.help_model:append(iter, iterMain)
        self.scriptGui.help_model:set(iter, 0, functionName, 1, functionName .. '()', 2, 1) --Display, insert, move cursor n positions backwards after insert
    end

    self.scriptGui.help_model:append( iterMain )
    self.scriptGui.help_model:set( iterMain, 0, "Elements", 1, '', 2, 0 )
    local envElements = {}
    for elementName, element in pairs( self.scriptEnv.env ) do
        table.insert( envElements, elementName )
        
    end
    table.sort( envElements, function(a,b)
        return a < b
    end )
    for k_elementName, elementName in ipairs( envElements ) do
        self.scriptGui.help_model:append(iter, iterMain)
        self.scriptGui.help_model:set( iter, 0, elementName, 1, ' ' .. elementName, 2, 0 )
    end
    
end

function ScriptGui:select_help()
    local iter = gtk.TreeIter.new()
    local res, m = self.scriptGui.help_selection:get_selected( iter )
    if res then
        local text       = m:get(iter, 1)
        self.scriptGui.code_buffer:insert_at_cursor( text, #text )

        local cursorBack = m:get(iter, 2) 
        local cursorIterCode = gtk.TextIter.new()
        local cursorMarkCode = self.scriptGui.code_buffer:get_insert()
        self.scriptGui.code_buffer:get_iter_at_mark( cursorIterCode, cursorMarkCode  )
        gtk.TextIter.backward_cursor_positions( cursorIterCode, cursorBack )
        self.scriptGui.code_buffer:place_cursor( cursorIterCode )

        self.scriptGui.code_view:grab_focus() 
    end
end

function ScriptGui:print( ... )
    local str = { ... }
    for k_s, s in ipairs( str ) do
        str[ k_s ] = tostring( s )
    end
    str = table.concat( str, '\t' ) .. '\n'
    local iter = gtk.TextIter.new()
    self.scriptGui.info_buffer:get_end_iter( iter )
    self.scriptGui.info_buffer:insert( iter, str, #str )
end


function ScriptGui:cleanInfo()
    self.scriptGui.info_buffer:set_text( '', 0 ) 
end

function ScriptGui:refresh()
    self.scriptGui.help_model:clear()
    self.scriptEnv:loadFnEnv()
    self.scriptEnv:loadEnv()
    self:updateHelp()
end

function ScriptGui:loadScript()
    local dialog = gtk.FileChooserDialog.new(
        "Load Script", self.gui.window, gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    if self.gui.dialogCurrentFolder then
        dialog:set_current_folder( self.gui.dialogCurrentFolder )
    end
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.lua")
    filter:set_name("Lua script")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        self.gui.lastFileName = names[1]
        local file = io.open( names[1], 'r')
        if file then
            local script = file:read('*a')
            self.scriptGui.code_buffer:set( 'text', script )
        end
    end
end

function ScriptGui:saveScript()
    local dialog = gtk.FileChooserDialog.new(
        "Save Script", self.gui.window, gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    if self.gui.dialogCurrentFolder then
        dialog:set_current_folder( self.gui.dialogCurrentFolder )
    end
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.lua")
    filter:set_name("Lua script")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        self.gui.lastFileName = names[1]
        local file = io.open( names[1], 'w')
        if file then
            local script = self.scriptGui.code_buffer:get( 'text' )
            file:write( script )
            file:flush()
            file:close()
        end
    end
end

function ScriptGui:run()
    local script = self.scriptGui.code_buffer:get( 'text' )
    self.scriptEnv:execScript( script, true )
    self.scriptGui.help_model:clear()
    self:updateHelp()
end


