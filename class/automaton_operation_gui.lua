AutomatonOperationGui = letk.Class( function( self, gui, controller )
    self.gui        = {}
    self.gui.gui    = gui
    self.controller = controller

    self:build_gui()
end)

function AutomatonOperationGui:build_gui()
        self.gui.vbox                           = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.gui.hbox                       = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.gui.treeview_operation     = Treeview.new()
            self.gui.vbox_automaton         = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
                self.gui.treeview_automaton = Treeview.new( true )
                self.gui.label_automaton    = gtk.Label.new_with_mnemonic( "Return name:" )
                self.gui.name_automaton     = gtk.Entry.new()
                self.gui.btn_add_operation  = gtk.Button.new_with_mnemonic( "Add Operation" )
        self.gui.hbox_button                = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.gui.btn_load_script        = gtk.Button.new_with_mnemonic( "Load Script" )
            self.gui.btn_save_script        = gtk.Button.new_with_mnemonic( "Save Script" )
            self.gui.btn_execute            = gtk.Button.new_with_mnemonic( "Execute" )

    self.gui.code_script_view     = gtk.SourceView.new()
    self.gui.code_script_buffer   = self.code_script_view:get('buffer')
    self.gui.code_script_manager  = gtk.source_language_manager_get_default()
    self.gui.code_script_lang     = self.gui.code_script_manager:get_language('lua')
    self.gui.code_script_scroll   = gtk.ScrolledWindow.new()
    self.gui.code_script_view:set('show-line-numbers', true, 'highlight-current-line', true, 'auto-indent', true)
    self.gui.code_script_scroll:set('hscrollbar-policy', gtk.POLICY_AUTOMATIC, 'vscrollbar-policy', gtk.POLICY_AUTOMATIC)
    self.gui.code_script_scroll:add(self.gui.code_script_view)
    self.gui.code_script_buffer:set('language', self.gui.code_script_lang)

    self.gui.vbox:pack_start( self.gui.hbox, true, true, 0 )
        self.gui.hbox:pack_start( self.gui.treeview_operation, false, false, 0 )
        self.gui.hbox:pack_start( self.gui.vbox_automaton, false, false, 0 )
            self.gui.vbox_automaton:pack_start( self.gui.treeview_automaton, true, true, 0 )
            self.gui.vbox_automaton:pack_start( self.gui.label_automaton, false, false, 0 )
            self.gui.vbox_automaton:pack_start( self.gui.name_automaton, false, false, 0 )
            self.gui.vbox_automaton:pack_start( self.gui.btn_add_operation, false, false, 0 )
        self.gui.hbox:pack_start( self.gui.code_script_scroll, true, true, 0 )
    self.gui.vbox:pack_start( self.gui.hbox_button, false, false, 0 )
        hbox_button.gui.vbox:pack_start( self.gui.btn_load_script, true, true, 0 )
        hbox_button.gui.vbox:pack_start( self.gui.btn_save_script, true, true, 0 )
        hbox_button.gui.vbox:pack_start( self.gui.btn_execute, true, true, 0 )

    self.gui.gui:add_tab( self.gui.vbox, "Operations" )
end

function AutomatonOperationGui:add_operation()
    local xxxxxxxxxx =  self.gui.treeview_automaton:get_selected()
end
