AutomatonEditor    = {}
AutomatonEditor_MT = { __index = AutomatonEditor }

setmetatable( AutomatonEditor, Object_MT )

function AutomatonEditor.new( gui, automaton )
    local self = {}
    setmetatable( self, AutomatonEditor_MT )

    self.operation = nil
    self.automaton = automaton

    self.vbox                  = gtk.VBox.new( false, 0 )
        self.toolbar           = gtk.Toolbar.new()
        self.render, self.scrolled, self.drawing_area = AutomatonRender.new( automaton )

    self.drawing_area:add_events( gdk.BUTTON_PRESS_MASK )
    self.drawing_area:connect("button_press_event", self.drawing_area_press, self )

    self.vbox:pack_start( self.toolbar, false, false, 0 )
    self.vbox:pack_start( self.scrolled, true, true, 0 )

    --save
    self.img_act_save = gtk.Image.new_from_file( './images/icons/save.gif' )
    self.btn_act_save = gtk.ToolButton.new( self.img_act_save, "Edit" )
    self.btn_act_save:connect( 'clicked', self.set_act_save, self )
    self.toolbar:insert( self.btn_act_save, -1 )

    --edit
    self.img_act_edit = gtk.Image.new_from_file( './images/icons/edit.gif' )
    self.btn_act_edit = gtk.ToggleToolButton.new( )
    self.btn_act_edit:set_icon_widget( self.img_act_edit )
    self.btn_act_edit:connect( 'toggled', self.set_act_edit, self )
    self.toolbar:insert( self.btn_act_edit, -1 )

    --move
    self.img_act_move = gtk.Image.new_from_file( './images/icons/move.gif' )
    self.btn_act_move = gtk.ToggleToolButton.new( )
    self.btn_act_move:set_icon_widget( self.img_act_move )
    self.btn_act_move:connect( 'toggled', self.set_act_move, self )
    self.toolbar:insert( self.btn_act_move, -1 )

    --state
    self.img_act_state = gtk.Image.new_from_file( './images/icons/state.gif' )
    self.btn_act_state = gtk.ToggleToolButton.new( )
    self.btn_act_state:set_icon_widget( self.img_act_state )
    self.btn_act_state:connect( 'toggled', self.set_act_state, self )
    self.toolbar:insert( self.btn_act_state, -1 )

    --transition
    self.img_act_transition = gtk.Image.new_from_file( './images/icons/transition.gif' )
    self.btn_act_transition = gtk.ToggleToolButton.new( )
    self.btn_act_transition:set_icon_widget( self.img_act_transition )
    self.btn_act_transition:connect( 'toggled', self.set_act_transition, self )
    self.toolbar:insert( self.btn_act_transition, -1 )

    --delete
    self.img_act_delete = gtk.Image.new_from_file( './images/icons/delete.gif' )
    self.btn_act_delete = gtk.ToggleToolButton.new( )
    self.btn_act_delete:set_icon_widget( self.img_act_delete )
    self.btn_act_delete:connect( 'toggled', self.set_act_delete, self )
    self.toolbar:insert( self.btn_act_delete, -1 )

    --state marked
    self.img_act_marked = gtk.Image.new_from_file( './images/icons/state_marked.gif' )
    self.btn_act_marked = gtk.ToggleToolButton.new( )
    self.btn_act_marked:set_icon_widget( self.img_act_marked )
    self.btn_act_marked:connect( 'toggled', self.set_act_marked, self )
    self.toolbar:insert( self.btn_act_marked, -1 )

    gui:add_tab( self.vbox, 'edit ' .. (automaton:info_get('short_file_name') or '-x-') )

    return self
end

function AutomatonEditor:toolbar_set_unset_operation( mode )
    local btn      = {'edit','move','state','transition','delete','marked'}
    local active   = self['btn_act_' .. mode]:get('active')

    if active then
        self.operation = mode

        for _, b in ipairs( btn ) do
            if b ~= mode then
                self['btn_act_' .. b]:set('active',false)
            end
        end
    else
        if self.operation == mode then
            self.operation = nil
        end
    end
end

function AutomatonEditor:set_act_save()
    print'saved'
end

function AutomatonEditor:set_act_edit()
    self:toolbar_set_unset_operation( 'edit' )
end

function AutomatonEditor:set_act_move()
    self:toolbar_set_unset_operation( 'move' )
end

function AutomatonEditor:set_act_state()
    self:toolbar_set_unset_operation( 'state' )
end

function AutomatonEditor:set_act_transition()
    self:toolbar_set_unset_operation( 'transition' )
end

function AutomatonEditor:set_act_delete()
    self:toolbar_set_unset_operation( 'delete' )
end

function AutomatonEditor:set_act_marked()
    self:toolbar_set_unset_operation( 'marked' )
end

function AutomatonEditor:drawing_area_press( event )
    if self.last_drawing_area_lock then return end
    self.last_drawing_area_lock = true

    glib.timeout_add(glib.PRIORITY_DEFAULT, 100, function( self )
        self.last_drawing_area_lock = nil
    end, self )

    local _, x, y = gdk.Event.get_coords( event )
    local element = self.render:select_element( x, y )

    --Botão para estado marcado, botão para estado inicial

    if self.operation == 'state' then
        local id = self.automaton:state_add()
        self.automaton:state_set_position( id, x, y )
        self.render:draw()
    elseif self.operation == 'move' then
        if self.last_element and self.last_element.type == 'state' then
            self.automaton:state_set_position( self.last_element.id, x, y )
            self.last_element = nil
            self.render:draw()
        elseif element and element.type == 'state' then
            self.last_element = element
        end
    elseif self.operation == 'delete' then
        if element and element.type == 'state' then
            self.automaton:state_remove( element.id )
            self.render:draw()
        end
    elseif self.operation == 'transition' then
        if self.last_element and self.last_element.type == 'state' and element and element.type == 'state' then
            --Os eventos serão os selecionados na Treeview
            self.automaton:transition_add( self.last_element.id, element.id, 1 )
            self.last_element = nil
            self.render:draw()
        elseif element and element.type == 'state' then
            self.last_element = element
        end
    elseif self.operation == 'marked' then
        if element and element.type == 'state' then
            if self.automaton:state_get_marked( element.id ) then
                self.automaton:state_unset_marked( element.id )
            else
                self.automaton:state_set_marked( element.id )
            end
            self.render:draw()
        end
    end
end
