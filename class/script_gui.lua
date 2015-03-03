ScriptGui = letk.Class( function( self, elements )
    Object.__super( self )

    self.elements  = elements
    self.scriptEnv = ScriptEnv.new( elements )
end, Object )

function ScriptGui:buildGui( gui )
    self.gui              = {}

    self.gui.vbox         = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.gui.hbox         = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            --help
            --code
        self.gui.hbox_footer  = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.gui.btn_refresh  = gtk.Button.new_with_label("Refresh Elements")
            self.gui.btn_load     = gtk.Button.new_with_label("Load Script")
            self.gui.btn_save     = gtk.Button.new_with_label("Save Script")
            self.gui.btn_run      = gtk.Button.new_with_label("Run")

    --Help:
    self.gui.scroll_help         = gtk.ScrolledWindow.new()
        self.gui.help_view       = gtk.TreeView.new()

    self.gui.scroll_help:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.gui.scroll_help:set('width-request', 250 )
    self.gui.help_model      = gtk.TreeStore.new("gchararray","gchararray")
    self.gui.help_col1       = gtk.TreeViewColumn.new_with_attributes("Script help", gtk.CellRendererText.new(), "text", 0)
    self.gui.help_selection  = self.gui.help_view:get_selection()
    
    self.gui.help_view:append_column(self.gui.help_col1)
    self.gui.help_view:set("model", self.gui.help_model)
    self.gui.help_selection:set_mode(gtk.SELECTION_SINGLE)

    --Code:
    self.gui.code_view     = gtk.SourceView.new()
    self.gui.code_buffer   = self.gui.code_view:get('buffer')
    self.gui.code_manager  = gtk.source_language_manager_get_default()
    self.gui.code_lang     = self.gui.code_manager:get_language('c')
    self.gui.code_scroll   = gtk.ScrolledWindow.new()
    self.gui.code_view:set('show-line-numbers', true, 'highlight-current-line', true, 'auto-indent', true)
    self.gui.code_scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.gui.code_scroll:add(self.gui.code_view)
    self.gui.code_buffer:set('language', self.gui.code_lang)



    self.gui.vbox:pack_start( self.gui.hbox, true, true, 0 )
        self.gui.hbox:pack_start( self.gui.scroll_help, false, false, 0 )
            self.gui.scroll_help:add(self.gui.help_view)
        self.gui.hbox:pack_start( self.gui.code_scroll, true, true, 0 )
    self.gui.vbox:pack_start( self.gui.hbox_footer, false, false, 0 )
        self.gui.hbox_footer:pack_start( self.gui.btn_refresh, true, true, 0 )
        self.gui.hbox_footer:pack_start( self.gui.btn_load, true, true, 0 )
        self.gui.hbox_footer:pack_start( self.gui.btn_save, true, true, 0 )
        self.gui.hbox_footer:pack_start( self.gui.btn_run, true, true, 0 )


    self.gui.btn_refresh:connect('clicked', self.refresh, self )
    self.gui.btn_load:connect('clicked', self.loadScript, self )
    self.gui.btn_save:connect('clicked', self.saveScript, self )
    self.gui.btn_run:connect('clicked', self.run, self )
    self.gui.help_view:connect( 'row-activated', self.select_help, self)

    self:refresh()

    gui:add_tab( self.gui.vbox, 'Script' )
end

function ScriptGui:updateHelp( tbl )
    --~ local function add_help( tbl, dad )
        --~ local iter = gtk.TreeIter.new()
        --~ for k, v in ipairs( tbl ) do
            --~ self.gui.help_model:append(iter, dad)
            --~ self.gui.help_model:set(iter, 0, v.caption, 1, v.value or '')
            --~ add_help( v, iter )
        --~ end
    --~ end
    local iterMain = gtk.TreeIter.new()
    local iter     = gtk.TreeIter.new()
    
    self.gui.help_model:append( iterMain )
    self.gui.help_model:set( iterMain, 0, "Functions", 1, '' )
    for nameFn, fn in pairs( self.scriptEnv.fnEnv ) do
        self.gui.help_model:append(iter, iterMain)
        self.gui.help_model:set(iter, 0, nameFn, 1, nameFn .. '() ')
    end

    self.gui.help_model:append( iterMain )
    self.gui.help_model:set( iterMain, 0, "Elements", 1, '' )
    for elementName, el in pairs( self.scriptEnv.env ) do
        self.gui.help_model:append(iter, iterMain)
        self.gui.help_model:set( iter, 0, elementName, 1, ' ' .. elementName .. ' ' )
    end
    
end

function ScriptGui:select_help()
    local iter = gtk.TreeIter.new()
    local res, m = self.gui.help_selection:get_selected( iter )
    if res then
        local text = m:get(iter, 1)
        self.gui.code_buffer:insert_at_cursor( text, #text ) 
    end
end


function ScriptGui:refresh()
    self.gui.help_model:clear()
    self.scriptEnv:loadFnEnv()
    self.scriptEnv:loadEnv()
    self:updateHelp()
end

function ScriptGui:loadScript()
    local dialog = gtk.FileChooserDialog.new(
        "Load Script", nil,gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.lua")
    filter:set_name("Lua script")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        local file = io.open( names[1], 'r')
        if file then
            local script = file:read('*a')
            self.gui.code_buffer:set( 'text', script )
        end
    end
end

function ScriptGui:saveScript()
    local dialog = gtk.FileChooserDialog.new(
        "Save Script", nil,gtk.FILE_CHOOSER_ACTION_SAVE,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.lua")
    filter:set_name("Lua script")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        local file = io.open( names[1], 'w')
        if file then
            local script = self.gui.code_buffer:get( 'text' )
            file:write( script )
            file:flush()
            file:close()
        end
    end
end

function ScriptGui:run()
    local script = self.gui.code_buffer:get( 'text' )
    self.scriptEnv:execScript( script )
    self.gui.help_model:clear()
    self:updateHelp()
end


