#!/usr/bin/lua5.1
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

    Copyright (C) 2011-2012 Yuri Kaszubowski Lopes, Eduardo Harbs, Andre Bittencourt Leal and Roberto Silvio Ubertino Rosso Jr.
    Copyright (C) 2013 Yuri Kaszubowski Lopes
--]]

--External Libs
LibLoad = {}
local function safeload( libs, id, required, msg, var )
    local function safeload_call()
        libs = type(libs) == 'table' and libs or { libs }
        for _, lib in ipairs( libs ) do
            if var then
                _G[ var ] = require( lib )
            else
                require( lib )
            end
        end
    end
    LibLoad[id], LibLoad[id .. '_info'] = pcall( safeload_call )
    if not LibLoad[id] then
        if required then
            print('ERROR: fail load library "' .. id .. '"')
            --print(LibLoad[id .. '_info'])
            if msg then print( msg ) end
            os.exit()
        else
            print('WARNING: fail load library "' .. id .. '", some features may not work')
            
            if msg then print( msg ) end
        end
    end
end

safeload('letk', 'letk', true, [[You need install 'letk' to run this software]])
safeload({'lgob.gdk','lgob.gtk','lgob.cairo','lgob.gtksourceview'}, 'gtk', true, [[You need install 'lgob' to run this software, you can found 'lgob' at http://oproj.tuxfamily.org]])
safeload('lxp', 'lxp', false, [[no library 'lxp' to manipulate xml format]], 'lxp')
safeload('redis', 'redis', false, [[no library 'redis' (redis-lua)]])

--Utils
require('class.object')

require('class.gui.info_dialog')
require('class.gui.treeview')
require('class.gui.selector')
require('class.gui.property_editor')

require('class.des.automaton')
require('class.des.automata_group')
require('class.code_gen.init')
require('class.gui.gui')
require('class.des.simulator')
require('class.des.graphviz_simulator')
require('class.scada.plant_simulator')
require('class.des.automaton_render')
require('class.des.automaton_editor')
require('class.script_env')
require('class.script_gui')
require('class.operations_gui')
--require('class.chooser')
--require('class.debug')
--~ require('class.scada.init')

local CodeGenDevices = require 'res.codegen.devices.main'
--local AutomataTemplates = require 'class.automata_templates'

Controller = letk.Class( function( self )
    self.gui              = Gui.new()
    self.elements         = letk.List.new()
    self.active_automaton = nil
    self.simulators       = letk.List.new()

    self.gui:run()
    self:build()

end, Object )

---Creates all Nadzoru's menus.
--Creates the menus file, automata, templates and options, appending all the submenus and actions.
--@param self Controller in which the menus are created.
--@see Gui:append_menu
--@see Gui:add_action
--@see Gui:remove_current_tab
--@see Gui:append_menu_item
--@see Gui:append_menu_separator
function Controller:build()
    -----------------------------------
    --          MENU         --
    -----------------------------------
    
    ---self.gui:append_menu('templates', "_Templates") ---???
    ---self.gui:append_menu('options', "_Options")     ---???

    --File
    --~ self.gui:prepend_menu_separator('file')
    ---self.gui:prepend_menu_item('file'   , "_Save Workspace"  , "Save Workspace", nil, self.save_workspace, self)
    ---self.gui:prepend_menu_item('file'   , "_Load Workspace"  , "Load Workspace", nil, self.load_workspace, self)

    --Automata
    self.gui:append_menu('automata', "_Automata")
    
    self.gui:append_menu_item('automata', "_New"   , "Create a New Automaton"       , 'gtk-new'  , self.create_new_automaton, self)
    self.gui:append_menu_item('automata', "_Open"  , "Open an Automaton"            , 'gtk-open'   , self.open_automaton      , self)
    self.gui:append_menu_item('automata', "_Clone" , "Create a Copy of an Automaton", 'gtk-copy'  , self.clone_automaton     , self)
    self.gui:append_menu_item('automata', "_Remove", "Remove an Automaton"          , 'gtk-delete', self.remove_automaton    , self)
    self.gui:append_sub_menu('automata','import', "_Import") --gtk-convert
        self.gui:append_menu_item('import', "_IDES", "Import a IDES (.xmd) automaton file", './images/icons/ides_export.png', self.import_ides, self)
        self.gui:append_menu_item('import', "_TCT" , "Import a TCT (.ads) automaton file" , './images/icons/tct_export.png' , self.import_tct , self)
    self.gui:append_menu_separator('automata')
    self.gui:append_menu_item('automata', "_Edit"          , "Edit automaton struct"                        , 'gtk-edit'   , self.automaton_edit, self)
    self.gui:append_menu_separator('automata')
    self.gui:append_menu_item('automata', "Operations", "Operations", 'gtk-convert', self.operations_gui  , self)
    self.gui:append_menu_item('automata', "Script operations", "Script operations", 'gtk-media-play', self.script_operation  , self)
    self.gui:append_menu_item('automata', "_Code Generator", "Deterministic Finite Automata - Code Generate", 'gtk-execute', self.code_gen_dfa  , self)
    --~ self.gui:append_sub_menu('automata','operations', "O_perations")
        --~ self.gui:append_menu_item('operations', "Accessible", "Calcule the accessible automata", nil, self.operations_accessible, self)
        --~ self.gui:append_menu_item('operations', "Coaccessible", "Calcule the coaccessible automata", nil, self.operations_coaccessible, self)
        --~ self.gui:append_menu_item('operations', "Trim", "Calcule the trim automata", nil, self.operations_trim, self)
        --~ self.gui:append_menu_item('operations', "Join Coaccessible", "Join Coaccessible States", nil, self.operations_join_no_coaccessible, self)
        --~ self.gui:append_menu_item('operations', "SelfLoop", "Self Loop in a automaton with a set of other automata events", nil, self.operations_selfloop, self)
        --~ self.gui:append_menu_item('operations', "Synchronization", "Synchronization of two or more automatons", nil, self.operations_synchronization, self)
        --~ self.gui:append_menu_item('operations', "Product", "Calculate the Product of two or more automatons", nil, self.operations_product, self)
        --~ self.gui:append_menu_item('operations', "SupC", "Calculate the operations_supc", nil, self.operations_supc, self)
        --~ ---self.gui:add_action('operations_projection', "_Projection", "Calculate the Projection of one automaton", nil, self.operations_projection, self)
        --~ ---self.gui:add_action('operations_deterministic', "_Deterministic", "Make automaton deterministic", nil, self.operations_deterministic, self)
        --~ ---self.gui:add_action('operations_complement', "_Complement", "Calculate the complement automaton", nil, self.operations_complement, self)
        --~ ---self.gui:add_action('operations_minimize', "_Minimize", "Minimize the automaton", nil, self.operations_minimize, self)
        --~ ---self.gui:add_action('operations_mask', "_Mask", "Masks refined events", nil, self.operations_mask, self)
        --~ ---self.gui:add_action('operations_distinguish', "_Distinguish", "Distinguishes events", nil, self.operations_distinguish, self)
        --~ ---self.gui:add_action('operations_check_all', "_Check All", "Check All", nil, self.operations_check_all, self)
        --~ self.gui:append_menu_item('operations', "Check Choice Problem", "Check if states have the choice problem", nil, self.operations_check_choice_problem, self)
        --~ self.gui:append_menu_item('operations', "Check Avalanche Effect", "Check if states have the avalanche effect", nil, self.operations_check_avalanche_effect, self)
        --~ self.gui:append_menu_item('operations', "Check Inexact Synchronization", "Check Inexact Synchronization", nil, self.operations_check_inexact_synchronization, self)
        ---    self.gui:add_action('operations_check_simultaneity', "_Check Simultaneity", "Check Simultaneity", nil, self.operations_check_simultaneity, self)
    self.gui:append_menu_separator('automata')
    self.gui:append_menu_item('automata', "_Simulate Graphviz", "Simulate Automata in a Graphviz render", nil, self.simulate_graphviz, self)

    --SCADA/MES
    --[[
    self.gui:append_menu('scada_mes', "SCADA/MES")
    
    self.gui:append_sub_menu('scada_mes','automata_group', "Automata Group")
        self.gui:append_menu_item('automata_group', "New", "Create a New Automata Group", nil, self.automata_group_new, self)
        self.gui:append_menu_item('automata_group', "Load ", "Load an Automata Group", nil, self.automata_group_load, self)
        self.gui:append_menu_item('automata_group', "Edit", "Edit an Automata Group", nil, self.automata_group_edit, self)
        ---    self.gui:add_action('automata_group_remove'  , "_Remove Automata Group", "Remove an Automata Group", nil, self.automata_group_remove, self)
    self.gui:append_sub_menu('scada_mes','scada_plant', "SCADA Plant")
        self.gui:append_menu_item('scada_plant', "New", "Create a New SCADA Plant", nil, self.create_new_scada_plant, self)
        self.gui:append_menu_item('scada_plant', "Load", "Load a SCADA Plant", nil, self.load_scada_plant, self)
        self.gui:append_menu_item('scada_plant', "Edit", "Edit a SCADA Plant", nil, self.scada_plant_edit, self)
    self.gui:append_menu_item('scada_mes'       , "SCADA View", "SCADA View Interface", nil, self.scada_plant_view, self)
    self.gui:append_menu_item('scada_mes'       , "SCADA/MES Server", "SCADA/MES Server", nil, self.scada_mes_server, self)
    ----]]

    --Templates
    --for i, temp in AutomataTemplates:ipairs() do
    --  self.gui:add_action(temp.name, temp.caption, temp.hint, nil, temp.callback, self)
    --end
end

---Executes the controller.
--Calls the gtk main function.
--@param self Controller to be executed.
function Controller:exec()
    gtk.main()
end

---Adds a new element to the controller.
--Appends 'new_element' to the elements list of the controller.
--@param self Controller in which the element will be added.
--@param new_element Element to be added.
function Controller:element_add( new_element )
    self.elements:append( new_element )
end

local extension_class_map = {
    ['nza'] = { name = 'Nadzoru Automaton'     , class = Automaton     , load = 'load_file'  , save = 'save'        },
    ['xmd'] = { name = 'IDES Automaton'        , class = Automaton     , load = 'IDES_import', save = 'IDES_export' },
    ['ads'] = { name = 'TCT Automaton'         , class = Automaton     , load = 'TCT_import' , save = 'TCT_export'  },
    ['nag'] = { name = 'Nadzoru Automata Group', class = AutomataGroup , load = 'load_file'  , save =  'save'       },
    --~ ['nsp'] = { name = 'Nadzoru Scada Plant'    , class = ScadaPlant    , load = 'load_file'   , save = 'save', variables={'elements'} },
}

function Controller:save_workspace( file_name )
    local data = {}
    for k, e in self.elements:ipairs() do
        local file_type      = e:get('file_type')
        local full_file_name = e:get('full_file_name')
        data[#data + 1] = {
            file_type      = file_type,
            full_file_name = full_file_name,
        }
    end
    
    local f, err = io.open( file_name, 'w' )
    if f then
        f:write( letk.serialize(data) )
        f:close()
        gtk.InfoDialog.showInfo( "Workspace saved!" )
    else
        gtk.InfoDialog.showInfo( "ERROR saving Workspace: " .. (err or '') )
    end
end

function Controller:load_workspace( file_name )
    local file = io.open( file_name, 'r')
    if file then
        local s    = file:read('*a')
        local data = loadstring('return ' .. s)()
        if data then
            for k, e in ipairs( data ) do
                if e.file_type and e.full_file_name then
                    local def = extension_class_map[ e.file_type ]
                    if def then
                        local ElementClass = def.class
                        local new_element  = ElementClass.new()
                        if def.variables then
                            local vars = {}
                            for k_varName, varName in ipairs( def.variables ) do
                                vars[ k_varName ] = self[ varName ]
                            end
                            new_element[ def.load ]( e.full_file_name, unpack( vars )   )
                        else
                            new_element[ def.load ]( e.full_file_name )
                        end
                        
                        self:element_add( new_element )
                    end
                end
            end
        end
    end
end

--[[
---Saves the workspace to a file.
--Creates a chooser that asks if the user is sure about saving. Opens the file chooser. Adds the string ".nzw" to the end of the file. Saves all automata, automata group and Scada plants opened in the program. Saves the workspace events. Changes the name of the program to show the name of the workspace.
--@param self
--@see Chooser:run
--@see Automaton:IDES_export
--@see Automaton:TCT_export
--@see Automaton:save
--@see AutomataGroup:save
--@see ScadaPlant:save
function Controller:save_workspace()
    Chooser.new{
        title = 'nadzoru',
        message = '\n\tEverything will be saved. Are you sure?\t\n',
        choices = {'Yes', 'No'},
        callbacks = {
            function()
                local dialog = gtk.FileChooserDialog.new(
                    "Save", nil,gtk.FILE_CHOOSER_ACTION_SAVE,
                    "gtk-cancel", gtk.RESPONSE_CANCEL,
                    "gtk-ok", gtk.RESPONSE_OK
                )
                if self.file_name then
                    dialog:set_current_folder(string.match(self.file_name, '(.-)[^\\]+%.nzw$'))
                end
                local filter = gtk.FileFilter.new()
                filter:add_pattern("*.nzw")
                filter:set_name("Nadzoru Workspace")
                dialog:add_filter(filter)
                local response = dialog:run() 
                dialog:hide()
                local names = dialog:get_filenames()
                if response == gtk.RESPONSE_OK and names and names[1] then
                    local file_name = names[1]
                    if not file_name:match( '%.nzw$' ) then
                        file_name = file_name .. '.nzw'
                    end
                    local saving_data = {}
                    saving_data.full_file_name = file_name
                    for k, e in self.elements:ipairs() do
                        local file_type   = e:get('file_type') or space_map[ e.__TYPE ]
                        local full_file_name = e:get('full_file_name')
                        
                        --Try to save
                        local status, err, err_list
                        status, err, err_list = e[ extension_class_map[file_type].save ]( e )
                        if not status then
                            if err == err_list.NO_FILE_NAME then
                                gtk.InfoDialog.showInfo( "ERROR saving Workspace: Save models before saving workspace." )
                                return
                            end
                        end
                        
                        saving_data[#saving_data + 1] = {
                            file_type      = file_type,
                            full_file_name = full_file_name,
                        }
                    end
                    saving_data.events = {}
                    for k_event, event in self.events:ipairs() do
                        saving_data.events[k_event] = {
                            name = event.name,
                            controllable = event.controllable,
                            observable = event.observable,
                            refinement = event.refinement,
                            level = event.level,
                        }
                    end
                    
                    local f, err = io.open( file_name, 'w' )
                    if f then
                        f:write( letk.serialize(saving_data) )
                        f:close()
                        self.file_name = file_name
                        self.gui.window:set("title", "nadzoru: " .. string.match(file_name, '[^\\]+%.nzw$'))
                        gtk.InfoDialog.showInfo( "Workspace saved!" )
                    else
                        gtk.InfoDialog.showInfo( "ERROR saving Workspace: " .. (err or '') )
                    end
                end
            end,
        }
    }
    :run()
end



local function max_suffix(s1, s2, s_min, s_max)
    s_min = s_min or 0
    s_max = s_max or math.min(s1:len(), s2:len())
    if s_min>s_max then
        return s_min
    end
    local size = math.floor((s_min+s_max)/2)
    if s1:sub(-size)==s2:sub(-size) then
        return max_suffix(s1, s2, size+1, s_max)
    else
        return max_suffix(s1, s2, s_min, size-1)
    end
end

---Loads a workspace from a file.
--Opens the file chooser. Clears the workspace. Loads the workspace events. Loads automata, automata group and Scada plants. Changes the name of the program to show the name of the workspace.
--@param self
--@see Controller:element_add
--@see Controller:add_event
--@see Controller:add_event
--@see Controller:add_events_from_automaton
--@see Controller:create_automaton_tab
--@see Automaton:IDES_import
--@see Automaton:TCT_import
--@see Automaton:load
--@see AutomataGroup:load
--@see AutomataGroup:start_automaton_window
--@see AutomataGroup:update_automaton_window
--@see ScadaPlant:load
function Controller:load_workspace()
    local dialog = gtk.FileChooserDialog.new(
        "Load", nil,gtk.FILE_CHOOSER_ACTION_LOAD,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.nzw")
    filter:set_name("Nadzoru Workspace")
    dialog:add_filter(filter)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        local file_name = names[1]
        local file, err = io.open( file_name, 'r')
        if file then
            local s    = file:read('*a')
            local loading_data = loadstring('return ' .. s)()
            if loading_data then
                --clear workspace
                self.elements:iremove( function() return true end )
                self.events:iremove( function() return true end )
                self.simulators:iremove( function() return true end )
                self.active_automaton = nil
                while self.gui.tab:len()>0 do
                    self.gui:remove_tab(0)
                end
                
                --load new workspace
                for k_event, event in ipairs(loading_data.events) do
                    local new_event = self:add_event(event.name, event.controllable, event.observable, event.refinement)
                    if event.level then
                        new_event.level = event.level
                    end
                end
                
                --make file names relative
                local old_name = loading_data.full_file_name or file_name
                local suffix = max_suffix(old_name, file_name)
                local old_prefix = old_name:sub(1, -suffix)
                local new_prefix = file_name:sub(1, -suffix)
                
                for k, e in ipairs( loading_data ) do
                    e.full_file_name = e.full_file_name:gsub('^' .. old_prefix, new_prefix)
                    if e.file_type and extension_class_map[ e.file_type ] then
                        local ElementClass = extension_class_map[ e.file_type ].class
                        local new_element  = ElementClass.new()
                        if extension_class_map[ e.file_type ].elements then
                            new_element[extension_class_map[ e.file_type ].load ]( new_element, e.full_file_name, self.elements )
                        else
                            new_element[extension_class_map[ e.file_type ].load ]( new_element, e.full_file_name )
                        end
                        self:element_add( new_element )
                        if e.file_type=='nza' or e.file_type=='xmd' or e.file_type=='ADS' then
                            self:add_events_from_automaton( new_element)
                            self:create_automaton_tab( new_element ) --start editing automaton
                            new_element.controller = self
                        end
                        if e.file_type=='nag' then
                            local AG_editor = AutomataGroupEditor.new( self.gui, new_element, self.elements )
                            AG_editor:start_automaton_window()
                            AG_editor:update_automaton_window()
                        end
                    end
                end
                self.file_name = file_name
                self.gui.window:set("title", "nadzoru: " .. string.match(file_name, '[^\\]+%.nzw$'))
                gtk.InfoDialog.showInfo( "Workspace loaded!" )
            end
        else
            gtk.InfoDialog.showInfo( "ERROR loading Workspace: " .. (err or '') )
        end
    end
end

--]]

------------------------------------------------------------------------
--                           CALLBACKS                                --
------------------------------------------------------------------------

--- AUTOMATA ---

---Creates a new automaton tab. If the automaton has too many states, asks the user if he wants to do so.
--Verifies if the automaton has less than 100 states. If it has, creates a tab for the automaton. Otherwise, creates a chooser to ask if the user wants to open a tab.
--@param new_automaton Automaton whose tab is created.
--@see Chooser:run
--[[
function Controller:create_automaton_tab( new_automaton )
    if new_automaton.states:len()==0 and new_automaton:get('file_name') == "*new automaton" then
        local window       = gtk.Window.new(gtk.WINDOW_TOPLEVEL)
        local zbox         = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        local vbox         = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        local hbox1        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
        local hbox2        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
        local label        = gtk.Label.new("Name")
        local entry        = gtk.Entry.new()
        local btnOk        = gtk.Button.new_with_mnemonic( "OK" )
        --local btnCancel    = gtk.Button.new_with_mnemonic( "Cancel" )
        
        window:add( zbox )
            zbox:pack_start(hbox1, false, false, 0)
                hbox1:pack_start(label, true, true, 0)
                hbox1:pack_start(entry, true, true, 0)
            zbox:pack_start(hbox2, false, false, 0)
                hbox2:pack_start(btnOk, true, true, 0)
                --hbox2:pack_start(btnCancel, true, true, 0)

        entry:set_text( '' )
        window:set_modal( true )
        window:set(
            "title", "Automaton name",
            "width-request", 200,
            "height-request", 70,
            "window-position", gtk.WIN_POS_CENTER,
            "icon-name", "gtk-about"
        )

        window:connect("delete-event", window.destroy, window)
    --  btnCancel:connect('clicked', function()
    --      window:destroy()
    --  end)
        btnOk:connect('clicked', function()
            name = entry:get_text()
            local exists
            local state_id
            if #name>0 then
                window:destroy()
                new_automaton:set('file_name', name )
                AutomatonEditor.new( self.gui, new_automaton, self.elements )
            end
        end)

        window:show_all()
    elseif new_automaton.states:len()<100  then
        AutomatonEditor.new( self.gui, new_automaton, self.elements )
    else
        Chooser.new{
            title = 'nadzoru',
            message = '\n\tThe automaton has ' .. new_automaton.states:len() .. ' states. Do you want to open a tab for it?\t\n',
            choices = {'Yes', 'No'},
            callbacks = {
                function()
                    AutomatonEditor.new( self.gui, new_automaton, self.elements )
                end,
            }
        }
        :run()
    end
end
--]]

---Creates a new automaton.
--Creates an automaton. Adds it to the elements list. Opens a tab for edit it.
--@see Controller:element_add
--@see AutomatonEditor
--@see Automaton.new
function Controller:create_new_automaton()
    local new_automaton = Automaton.new()
    self:element_add( new_automaton )
    AutomatonEditor.new( self.gui, new_automaton, self.elements)
end

---Loads an automaton from a file.
--Opens a file chooser. Loads the selected automata and adds them to the elements list. Adds their events to the workspace events. Creates tabs for them.
--@param self
--@see Automaton:load_file
--@see Controller:add_events_from_automaton
--@see Controller:element_add
--@see Controller:create_automaton_tab
function Controller:open_automaton()
    --Predefined values for use as response ids: gtk.RESPONSE_OK,gtk.RESPONSE_CANCEL
    --All predefined values are negative, GTK+ leaves positive values for application-defined response ids.
    local dialog = gtk.FileChooserDialog.new(
        "Select the file", self.gui.window, gtk.FILE_CHOOSER_ACTION_OPEN,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK,
        "gtk-edit", 1
    )
    if self.gui.dialogCurrentFolder then
        dialog:set_current_folder( self.gui.dialogCurrentFolder )
    end
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.nza")
    filter:set_name("Nadzoru automaton")
    dialog:add_filter(filter)
    dialog:set("select-multiple", true)
    local response = dialog:run()
    dialog:hide()
    local filenames = dialog:get_filenames()
    if (response == gtk.RESPONSE_OK or response == 1) and filenames then
        for k_filename, filename in ipairs( filenames ) do
            local new_automaton = Automaton.new()
            new_automaton:load_file( filename )
            self:element_add( new_automaton )
            if response == 1 then
                AutomatonEditor.new( self.gui, new_automaton, self.elements )
            end
        end
        self.gui.dialogCurrentFolder = dialog:get_current_folder()
    end
end

---Clones an automaton.
--Creates a selector showing all automata. Clones the selected automaton. Adss the clone to the elements list. Creates a tab for it.
--TODO CHECK
--@param self
--@see Automaton:clone
--@see Selector:add_combobox
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:clone_automaton()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:clone()
                new_automaton:set('file_name', 'clone(' .. automaton:get('file_name') .. ')')
                self.elements:append( new_automaton )
                ---self:create_automaton_tab( new_automaton ) --start editing automaton
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = 'Automaton:'
    }
    :run()
end

---Removes automata from the list of editable automata.
--Creates a selector showing all automata. Removes the selected automata from the elements list. Closes the all removed automata tabs.
--TODO CHECK
--@param self
--@see Selector:add_multipler
--@see Selector:run
--@see Gui:remove_tab
function Controller:remove_automaton()
    Selector.new({
        title = 'Select automata to remove',
        success_fn = function( results, numresult )
            local tabs_to_remove = {}
            for k_automaton, automaton in ipairs(results[1]) do
                for k_element, element in self.elements:ipairs() do
                    if element==automaton then
                        self.elements:remove( k_element )
                        break
                    end
                end
            end
            --TODO: remove tabs that use removed elements
            ---local diff = 1
            ---for _, tab in ipairs(tabs_to_remove) do
            --- self.gui:remove_tab(tab-diff)
            --- diff = diff + 1
            ---end
        end,
    })
    :add_multipler{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :run()
end

---Imports an IDES automaton.
--Opens a file chooser. Imports the selected automaton. Adss the automaton to the elements list. Creates a tab for it.
--@param self
--@see Automaton:IDES_import
--@see Controller:element_add
--@see Controller:add_events_from_automaton
--@see Controller:create_automaton_tab
function Controller:import_ides()
    local dialog = gtk.FileChooserDialog.new(
        "Select the file", self.gui.window, gtk.FILE_CHOOSER_ACTION_OPEN,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK,
        "gtk-edit", 1
    )
    if self.gui.dialogCurrentFolder then
        dialog:set_current_folder( self.gui.dialogCurrentFolder )
    end
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.xmd")
    filter:set_name("IDES3 automaton")
    dialog:add_filter(filter)
    dialog:set("select-multiple", true)
    local response = dialog:run()
    dialog:hide()
    local filenames = dialog:get_filenames()
    if (response == gtk.RESPONSE_OK or response == 1) and filenames then
        for k_filename, filename in ipairs( filenames ) do
            local new_automaton = Automaton.new()
            new_automaton:IDES_import( filename )
            self:element_add( new_automaton )
            if response == 1 then
                AutomatonEditor.new( self.gui, new_automaton, self.elements )
            end
        end
        self.gui.dialogCurrentFolder = dialog:get_current_folder()
    end
end

---Imports an TCT automaton.
--Opens a file chooser. Imports the selected automaton. Adss the automaton to the elements list. Creates a tab for it.
--TODO CHECK
--@param self
--@see Automaton:TCT_import
--@see Controller:element_add
--@see Controller:add_events_from_automaton
--@see Controller:create_automaton_tab
function Controller:import_tct()
    local dialog = gtk.FileChooserDialog.new(
        "Select the file", self.gui.window, gtk.FILE_CHOOSER_ACTION_OPEN,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK,
        "gtk-edit", 1
    )
    if self.gui.dialogCurrentFolder then
        dialog:set_current_folder( self.gui.dialogCurrentFolder )
    end
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.ads")
    filter:set_name("TCT automaton")
    dialog:add_filter(filter)
    dialog:set("select-multiple", true)
    local response = dialog:run()
    dialog:hide()
    local filenames = dialog:get_filenames()
    if (response == gtk.RESPONSE_OK or response == 1)and filenames then
        for k_filename, filename in ipairs( filenames ) do
            local new_automaton = Automaton.new( self )
            new_automaton:TCT_import( filename )
            self:element_add( new_automaton )
            if response == 1 then
                AutomatonEditor.new( self.gui, new_automaton, self.elements )
            end
        end
        self.gui.dialogCurrentFolder = dialog:get_current_folder()
    end
end

---Creates a graphviz simulation.
--Creates a selector showing all automata. If the selected automaton has more than zero states, creates a simulator for it and adds the simulator in the simulators list. Otherwise, shows a message indicating that the automaton jas no states.
--@param self
--@see Object:bind
--@see Selector:add_combobox
--@see Selector:run
function Controller:simulate_graphviz()
    Selector.new({
        title = 'Select automaton to simulate',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                if automaton.states:len()>0 then
                    local graphvizsimulator = GraphvizSimulator.new( self.gui, automaton )
                    self.simulators:add(graphvizsimulator)
                    --self.simulators[ graphvizsimulator ] = true
                    graphvizsimulator:bind('destroy', function( graphvizsimulator, controller)
                        self.simulators:remove(graphvizsimulator)
                        --controller.simulators[ graphvizsimulator ] = nil
                    end, self )
                else
                    gtk.InfoDialog.showInfo("Automaton doesn't have any states. Simulation can't be run.")
                end
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = 'Automaton:'
    }
    :run()
end

---Creates a plant simulation.
--TODO
--@param self
--@see Selector:add_combobox
--@see Selector:run
function Controller:simulate_plant()
    Selector.new({
        title = 'Select automaton to simulate',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                PlantSimulator.new( self.gui, automaton )
            end
        end,
    })
    :add_combobox{
        list = self.simulators,
        text_fn  = function( a )
            return a.automaton:get( 'file_name' )
        end,
        text = 'Automaton:'
    }
    :run()
end

---Starts editing an automaton.
--Creates a selector showing all automata. Opens a tab for the selected automaton.
--@param self
--@see Selector:add_combobox
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:automaton_edit()
    Selector.new({
        title = 'Select automaton to edit',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                AutomatonEditor.new( self.gui, automaton, self.elements )
                ---self:create_automaton_tab( automaton )
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = 'Automaton:'
    }
    :run()
end

---Starts code generation.
--TODO
--@param self
--@see Selector:add_combobox
--@see Codegen:execute
--@see Selector:add_multipler
--@see Selector:add_file
--@see Selector:run
function Controller:script_operation()
    local scriptGui = ScriptGui.new( self.elements )
    scriptGui:buildGui( self.gui )
end

function Controller:operations_gui()
    local operationsGui = OperationsGui.new( self.elements )
    operationsGui:buildGui( self.gui )
end


function Controller:code_gen_dfa()
    local devices_list = {}
    for id, device in pairs(CodeGenDevices) do
        if device.display then
            devices_list[#devices_list + 1] = { id , device.name or id }
        end
    end

    table.sort( devices_list, function( a,b ) return a[1] > b[1] end )

    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automata       = results[1]
            --~ local path_name      = results[2]
            local device_id      = results[2] and results[2][1]
            local event_map      = results[3]
            local event_map_file = results[4]
            --~ if #automata > 0 and #path_name > 0 and device_id then
            if #automata > 0 and device_id then
                local lautomata = letk.List.new_from_table( automata )
                local cg = CodeGen.new{ 
                    automata       = lautomata, 
                    device_id      = device_id, 
                    --~ path_name      = path_name,
                    event_map      = event_map,
                    event_map_file = event_map_file
                }
                if cg then
                    cg:execute( self.gui )
                end
            end
        end,
    })
    :add_multipler{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    --~ :add_file{
        --~ text   = "Code Folder:",
        --~ title = "Code Folder",
        --~ method = gtk.FILE_CHOOSER_ACTION_SELECT_FOLDER,
    --~ }
    :add_combobox{
        list = letk.List.new_from_table( devices_list ),
        text_fn  = function( a )
            return a[2]
        end,
        text = "Device:",
    }
    :add_checkbox{
        text = "Generate Event Map"
    }
    :add_file{
        text = "Event Map File (optional):",
        title = "Event Map File",
        filter = 'nem',
        filter_name = "Nadzoru Event Map",
    }
    :run()
end

-- ** Operations ** --

---Creates the accessible automaton of a chosen automaton.
--TODO
--@param self
--@see Automaton:accessible
--@see Selector:add_combobox
--@see Selector:add_checkbox
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_accessible()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local keep = not results[2]
                local new_automaton = automaton:accessible( results[2], keep )
                if new_automaton and not keep then
                    new_automaton:set('file_name', 'accessible(' .. automaton:get('file_name') .. ')')
                    self.elements:append( new_automaton )
                    ---self:create_automaton_tab( new_automaton ) --start editing automaton
                end
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = 'Automaton:'
    }
    :add_checkbox{
        text = 'remove states',
    }
    :run()
end

---Creates the coaccessible automaton of a chosen automaton.
--TODO
--@param self
--@see Automaton:coaccessible
--@see Selector:add_combobox
--@see Selector:add_checkbox
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_coaccessible()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local keep = not results[2]
                local new_automaton = automaton:coaccessible( results[2], keep )
                if not keep then
                    new_automaton:set('file_name', 'coaccessible(' .. automaton:get('file_name') .. ')')
                    self.elements:append( new_automaton )
                    ---self:create_automaton_tab( new_automaton ) --start editing automaton
                end
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = 'Automaton:'
    }
    :add_checkbox{
        text = 'remove states',
    }
    :run()
end

---Creates an automaton that joins in one unique state every no coaccessible state of a chosen automaton.
--TODO
--@param self
--@see Automaton:join_no_coaccessible_states
--@see Selector:add_combobox
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_join_no_coaccessible()
     Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:join_no_coaccessible_states( false )
                new_automaton:set('file_name', 'join_no_coaccessible(' .. automaton:get('file_name') .. ')')
                self.elements:append( new_automaton )
                ---self:create_automaton_tab( new_automaton ) --start editing automaton
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :run()
end

---Creates the trim automaton of a chosen automaton.
--TODO
--@param self
--@see Automaton:trim
--@see Selector:add_combobox
--@see Selector:add_checkbox
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_trim()
     Selector.new({
        title = "nadzoru",
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local keep = not results[2]
                local new_automaton = automaton:trim( results[2], keep )
                if new_automaton and not keep then
                    new_automaton:set('file_name', 'trim(' .. automaton:get('file_name') .. ')')
                    self.elements:append( new_automaton )
                    ---self:create_automaton_tab( new_automaton ) --start editing automaton
                end
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :add_checkbox{
        text = "Remove states",
    }
    :run()
end

---Creates the selflooped automaton of a chosen automaton with chosen automata.
--TODO
--@param self
--@see Automaton:selfloop
--@see Selector:add_combobox
--@see Selector:add_multipler
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_selfloop()
     Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:selfloop( unpack( results[2] ) )
                new_automaton:set('file_name', 'selfloop(' .. automaton:get('file_name') .. ', ...' .. ')')
                self.elements:append( new_automaton )
                ---self:create_automaton_tab( new_automaton ) --start editing automaton
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :add_multipler{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automata (events):"
    }
    :run()
end

---Creates the synchronized automaton of chosen automata.
--TODO
--@param self
--@see Automaton:synchronization
--@see Selector:add_multipler
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_synchronization()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automatons = results[1]
             if automatons then
                local new_automaton = Automaton.synchronization( unpack( automatons ) )
                if new_automaton then
                    new_automaton:set('file_name', 'synchronization(' .. '...' .. ')')
                    self.elements:append( new_automaton )
                    ---self:create_automaton_tab( new_automaton ) --start editing automaton
                end
            end
        end,
    })
    :add_multipler{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automata:"
    }
    :run()
end

---Creates the product automaton of chosen automata.
--TODO
--@param self
--@see Automaton:product
--@see Selector:add_multipler
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_product()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automatons = results[1]
            if automatons then
                local new_automaton = Automaton.product( unpack( automatons ) )
                if new_automaton then
                    new_automaton:set('file_name', 'product(' .. '...' .. ')')
                    self.elements:append( new_automaton )
                    ---self:create_automaton_tab( new_automaton ) --start editing automaton
                end
            end
        end,
    })
    :add_multipler{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automata:"
    }
    :run()
end

---Creates the product automaton of chosen automata.
--TODO
--@param self
--@see Automaton:product
--@see Selector:add_multipler
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_projection()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:projection( unpack( automaton ))
                if new_automaton and not keep then
                    new_automaton:set('file_name', 'projection(' .. automaton:get('file_name') .. ')')
                    self.elements:append( new_automaton )
                    ---self:create_automaton_tab( new_automaton ) --start editing automaton
                end
            end
        end,
    })
   :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :add_multipler{
        list = self.events,
        text_fn  = function( a )
            return a.name
        end,
        filter_fn = function( v )
            return v.refinement ~= ''
        end,
        text = "Events:"
    }
    :run()
end
---Creates the max controllable language automaton of chosen automata.
--TODO
--@param self
--@see Automaton.supC
--@see Selector:add_combobox
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_supc()
     Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local g = results[1]
            local k = results[2]
            if g and k then
                local new_automaton = Automaton.supC(g, k)
                if new_automaton then
                    new_automaton:set( 'file_name', 'supC(' .. ')' )
                    self.elements:append( new_automaton )
                    ---self:create_automaton_tab( new_automaton ) --start editing automaton
                end
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = 'G:'
    }
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = 'K:'
    }
    :run()
end

---Creates the automaton with masked events of a chosen automaton.
--TODO CHECK
--@param self
--@see Automaton:mask
--@see Selector:add_combobox
--@see Selector:add_multipler
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_mask()
    local masks = {}
    for k_event, event in self.events:ipairs() do
        if event.refinement~='' then
            masks[ event.refinement ] = true
        end
    end
    
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton and #results[2]>0 then
                local new_automaton = automaton:mask( false, results[2] )
                new_automaton:set('file_name', 'mask(' .. automaton:get('file_name') .. ', ...' .. ')')
                self.elements:append( new_automaton )
                self:create_automaton_tab( new_automaton ) --start editing automaton
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :add_multipler{
        list = self.events,
        text_fn  = function( a )
            return a.name
        end,
        filter_fn = function( v )
            return masks[ v.name ]
        end,
        text = "Events:"
    }
    :run()
end

---Creates the automaton with distinghuished events of a chosen automaton.
--TODO CHECK
--@param self
--@see Automaton:distinguish
--@see Selector:add_combobox
--@see Selector:add_multipler
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_distinguish()
     Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton and #results[2]>0 then
                local new_automaton = automaton:distinguish( false, results[2] )
                new_automaton:set('file_name', 'distinguish(' .. automaton:get('file_name') .. ', ...' .. ')')
                self.elements:append( new_automaton )
                self:create_automaton_tab( new_automaton ) --start editing automaton
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :add_multipler{
        list = self.events,
        text_fn  = function( a )
            return a.name
        end,
        filter_fn = function( v )
            return v.refinement ~= ''
        end,
        text = "Events:"
    }
    :run()
end

---Checks all the problems of a chosen automaton.
--TODO CHECK
--@param self
--@see Automaton:check_choice_problem
--@see Automaton:check_avalanche_effect
--@see Automaton:check_inexact_synchronization
--@see Automaton:check_simultaneity
--@see Selector:add_combobox
--@see Selector:run
function Controller:operations_check_all()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                automaton:check_choice_problem( true )
                         :check_avalanche_effect( true, results[2] )
                         :check_inexact_synchronization( true )
                         :check_simultaneity( true )
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :add_checkbox{
        text = "Uncontrollable only (Avalanche)",
    }
    :run()
end

---Checks the choice problem of a chosen automaton.
--TODO CHECK
--@param self
--@see Automaton:check_choice_problem
--@see Selector:add_combobox
--@see Selector:run
function Controller:operations_check_choice_problem()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                automaton:check_choice_problem( true )
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :run()
end

---Checks the avalanche effect of a chosen automaton.
--TODO
--@param self
--@see Automaton:check_avalanche_effect
--@see Selector:add_combobox
--@see Selector:add_checkbox
--@see Selector:run
function Controller:operations_check_avalanche_effect()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                automaton:check_avalanche_effect( true, results[2] )
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :add_checkbox{
        text = "Uncontrollable only",
    }
    :run()
end

---Checks the inexact synchronization problem of a chosen automaton.
--TODO
--@param self
--@see Automaton:check_inexact_synchronization
--@see Selector:add_combobox
--@see Selector:run
function Controller:operations_check_inexact_synchronization()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                automaton:check_inexact_synchronization( true )
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :run()
end

---Checks the simultaneity problem of a chosen automaton.
--TODO
--@param self
--@see Automaton:check_simultaneity
--@see Selector:add_combobox
--@see Selector:run
function Controller:operations_check_simultaneity()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                automaton:check_simultaneity( true )
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :run()
end

---Creates the deterministic automaton of a chosen automaton.
--TODO
--@param self
--@see Automaton:deterministic
--@see Selector:add_combobox
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_deterministic()
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:deterministic( false )
                if new_automaton then
                    new_automaton:set('file_name', 'deterministic(' .. automaton:get('file_name') .. ')')
                    self.elements:append( new_automaton )
                    ---self:create_automaton_tab( new_automaton ) --start editing automaton
                end
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = 'Automaton:'
    }
    :run()
end

---Creates the complement automaton of a chosen automaton.
--TODO
--@param self
--@see Automaton:complement
--@see Selector:add_combobox
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_complement()
     Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:complement( false )
                if new_automaton then
                    new_automaton:set('file_name', 'complement(' .. automaton:get('file_name') .. ')')
                    self.elements:append( new_automaton )
                    ---self:create_automaton_tab( new_automaton ) --start editing automaton
                end
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :run()
end

---Creates the minimal automaton of a chosen automaton.
--TODO
--@param self
--@see Automaton:minimize
--@see Selector:add_combobox
--@see Selector:run
--@see Controller:create_automaton_tab
function Controller:operations_minimize()
     Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:minimize( false )
                if new_automaton then
                    new_automaton:set('file_name', 'minimize(' .. automaton:get('file_name') .. ')')
                    self.elements:append( new_automaton )
                    ---self:create_automaton_tab( new_automaton ) --start editing automaton
                end
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :run()
end

--- Automata Group ---

---Creates a new automata group.
--TODO
--@param self
--@see Controller:element_add
--@see AutomataGroup:start_automaton_window
--@see AutomataGroup:update_automaton_window
function Controller:automata_group_new()
    local nag = AutomataGroup.new()
    self:element_add( nag )
    ---local AG_editor = AutomataGroupEditor.new( self.gui, nag, self.elements )
    ---AG_editor:start_automaton_window()
    ---AG_editor:update_automaton_window()
end

---Opens the window to load an automata group from a file.
--TODO
--@param self
--@see AutomataGroup:load_file
--@see Controller:element_add
--@see AutomataGroup:start_automaton_window
--@see AutomataGroup:update_automaton_window
function Controller:automata_group_load()
    local dialog = gtk.FileChooserDialog.new(
        "Select the file", self.gui.window, gtk.FILE_CHOOSER_ACTION_OPEN,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK,
        "gtk-edit", 1
    )
    if self.gui.dialogCurrentFolder then
        dialog:set_current_folder( self.gui.dialogCurrentFolder )
    end
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.nag")
    filter:set_name("Nadzoru Automata Group")
    dialog:add_filter(filter)
    dialog:set("select-multiple", true)
    local response = dialog:run()
    dialog:hide()
    local filenames = dialog:get_filenames()
    if (response == gtk.RESPONSE_OK or response == 1) and filenames then
        for k_filename, filename in ipairs( filenames ) do
            local nag = AutomataGroup.new()
            nag:load_file( filename )
            self:element_add( nag )
            if response == 1 then
                AutomataGroupEditor.new( self.gui, nag, self.elements )
            end
        end
        self.gui.dialogCurrentFolder = dialog:get_current_folder()
    end
end

---Starts editing an automata group.
--TODO
--@param self
--@see AutomataGroupEditor:start_automaton_window
--@see AutomataGroupEditor:update_automaton_window
--@see Selector:add_combobox
--@see Selector:run
function Controller:automata_group_edit()
    Selector.new({
        title = "Select an Automata Group to edit",
        success_fn = function( results, numresult )
            local ag = results[1]
            if ag then
                local AG_editor = AutomataGroupEditor.new( self.gui, ag, self.elements )
                AG_editor:start_automaton_window()
                AG_editor:update_automaton_window()
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automatagroup'
        end,
        text = "Automata Group:"
    }
    :run()
end

---Removes an automata group from the list of editable automata groups.
--TODO
--@param self
--@see Selector:add_multipler
--@see Selector:run
function Controller:automata_group_remove()
    Selector.new({
        title = 'Select Automata Groups to remove',
        success_fn = function( results, numresult )
            local tabs_to_remove = {}
            for group_id, group in ipairs(results[1]) do
                for ag_id, ag in self.elements:ipairs() do
                    if ag==group then
                        self.elements:remove( ag_id )
                        break
                    end
                end
                ---for tab_id, tab in self.gui.tab:ipairs() do
                    ---TODO: fix, no access to content, OR will we have? What should be done when the data displayed by a tab is removed?
                    ---if tab.content.automata_group==group then
                    --- tabs_to_remove[ #tabs_to_remove+1 ] = tab_id
                    --- --no 'break' because can be more than one
                    ---end
                ---end
            end
            ---local diff = 1
            ---for _, tab in ipairs(tabs_to_remove) do
            --- self.gui:remove_tab(tab-diff)
            --- diff = diff + 1
            ---end
        end,
    })
    :add_multipler{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automatagroup'
        end,
        text = "Automata Group:"
    }
    :run()
end

--- SCADA ---
--[[
---Creates a new scada plant.
--TODO
--@param self
--@see Controller:element_add
function Controller:create_new_scada_plant()
    local new_scada_plant = ScadaPlant.new()
    self:element_add( new_scada_plant )
end

---Loads a scada plant from a file.
--TODO
--@param self
--@see ScadaPlant:load_file
--@see Controller:element_add
function Controller:load_scada_plant()
    local dialog = gtk.FileChooserDialog.new(
        "Select the file", nil, gtk.FILE_CHOOSER_ACTION_OPEN,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.nsp")
    filter:set_name("Nadzoru SCADA Plant")
    dialog:add_filter(filter)
    dialog:set("select-multiple", true)
    local response = dialog:run()
    dialog:hide()
    local filenames = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and filenames then
        for k_filename, filename in ipairs( filenames ) do
            local new_scada_plant = ScadaPlant.new()
            new_scada_plant:load_file( filename, self.elements )
            self:element_add( new_scada_plant )
        end
    end
end

---Starts editing an scada plant.
--TODO
--@param self
--@see Selector:add_combobox
--@see Selector:run
function Controller:scada_plant_edit()
    Selector.new({
        title = "Select scada plant to edit",
        success_fn = function( results, numresult )
            local plant = results[1]
            if plant then
                ScadaEditor.new( self.gui, plant, self.elements )
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'scadaplant'
        end,
        text = "Plant:"
    }
    :run()
end

---Runs a scada plant.
--TODO
--@param self
--@see Selector:add_combobox
--@see Selector:run
function Controller:scada_plant_view()
    Selector.new({
        title = "Select scada plant to view/run",
        success_fn = function( results, numresult )
            local plant = results[1]
            if plant then
                ScadaView.new( self.gui, plant, self.elements )
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'scadaplant'
        end,
        text = "Plant:"
    }
    :run()
end

---Opens scada mes server.
--TODO
--@param self
--@see Selector:add_combobox
--@see Selector:add_file
--@see Selector:run
function Controller:scada_mes_server()
     Selector.new({
        title = "Open Server",
        success_fn = function( results, numresult )
            local automata_group = results[1]
            local event_map_file = results[2]
            if automata_group and event_map_file then
                ScadaServer.new( self.gui, automata_group, event_map_file, self.elements )
            end
        end,
    })
    :add_combobox{
        list = self.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automatagroup'
        end,
        text = "Automata Group:"
    }
    :add_file{
        text = "Event Map:",
        filter = 'nem',
        filter_name = "Nadzoru Event Map",
    }
    :run()
end

----]]

--- OPTIONS ---
---TODO: BIG CHECK ALL OVER THIS POINT

--- EVENT TREEVIEW ---

---Updates the list of events.
--Clears the event treeview. For each event in the workspace, draws a row with its name, controllable, observable and refinement property. Resizes the treeview to fit the event names. Updates other treeviews.
--@param self
--@param hist Historic of updated treeviews.
--@see Treeview:clear_data
--@see Treeview:add_row
--@see Treeview:update
--@see AutomatonEditor:update_treeview_events
--@see AutomatonRender:draw
function Controller:update_treeview_events(hist)
    local max1 = 0
    local max2 = 0
    self.gui.treeview_events:clear_data()
    for event_id, event in self.events:ipairs() do
        if #event.name > max1 then
            max1 = #event.name
        end
        if #event.refinement > max2 then
            max2 = #event.refinement
        end
        self.gui.treeview_events:add_row{ event.name, event.controllable, event.observable, event.refinement }
    end
    
    max1 = 7*max1
    if max1 < 36 then
        max1 = 36
    end
    max2 = 7*max2
    if max2 < 10 then
        max2 = 10
    end
    self.gui.treeview_events.scrolled:set('width-request', 60+max1+max2+64)
    self.gui.treeview_events.render[1]:set('width', max1+6)
    self.gui.treeview_events.render[2]:set('width', 32)
    self.gui.treeview_events.render[3]:set('width', 32)
    self.gui.treeview_events:update()
    
    --Update other treeviews
    hist = hist or {}
    hist[self.gui] = true
    for tab_id, tab in self.gui.tab:ipairs() do
        if not hist[tab.content] and tab.content and tab.content.automaton then
            tab.content:update_treeview_events(hist)
            tab.content.render:draw()
        end
    end
end

---Receives input from user for a new event name.
--TODO
--@param self, the Controller in which the operations is applied.
--@param event_id Id of the event whose name is received.
--@see Controller:update_treeview_events
function Controller:new_event_input( event_id)
    local window       = gtk.Window.new(gtk.WINDOW_TOPLEVEL)
    local vbox         = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
    local hbox1        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    local hbox2        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
    local label        = gtk.Label.new("Name")
    local entry        = gtk.Entry.new()
    local btnOk        = gtk.Button.new_with_mnemonic( "OK" )
    local btnCancel    = gtk.Button.new_with_mnemonic( "Cancel" )
    local ev = self.events:get(event_id)
    
    window:add( vbox )
        vbox:pack_start(hbox1, false, false, 0)
            hbox1:pack_start(label, true, true, 0)
            hbox1:pack_start(entry, true, true, 0)
        vbox:pack_start(hbox2, false, false, 0)
            hbox2:pack_start(btnOk, true, true, 0)
            hbox2:pack_start(btnCancel, true, true, 0)
    
    entry:set_text( 'new' )
    window:set_modal( true )
    window:set(
        "title", "New event",
        "width-request", 200,
        "height-request", 70,
        "window-position", gtk.WIN_POS_CENTER,
        "icon-name", "gtk-about"
    )

    window:connect("delete-event", function()
        self.events:remove( event_id )
        self:update_treeview_events()
        window:destroy()
    end)
    btnCancel:connect('clicked', function()
        self.events:remove( event_id )
        self:update_treeview_events()
        window:destroy()
    end)
    btnOk:connect('clicked', function()
        local name = entry:get_text()
        name = name:gsub('[^%&%w%_]','')
        if name:find('%&') then
            name = '&'
        end
        if name:find('EMPTYWORD') then
            name = '&'
        end
        
        --Verify if event already exists
        local exists
        for id, wev in self.events:ipairs() do
            if wev.name == name then
                exists = id
                break
            end
        end
        if (not exists or exists==event_id) and #name>0 then
            ev.name = name
            self:update_treeview_events()
            window:destroy()
        end
    end)

    window:show_all()
end

---Adds a new event to the workspace.
--TODO
--@param self Controller in which the operation is applied.
--@param name Name of the new event.
--@param observable If true, the new event is observable.
--@param controllable If true, the new event is controllable.
--@param refinement Name of the event refined by the new event.
--@return New event.
--@see Controller:update_treeview_events
--@see Controller:new_event_input
--~ function Controller:add_event(name, controllable, observable, refinement)
    --~ if observable==nil then
        --~ observable = true
    --~ end
    --~ local event = {
        --~ name = name or 'new',
        --~ observable = observable or false,
        --~ controllable = controllable or false,
        --~ refinement = refinement or '',
        --~ automata = {},
        --~ level = {},
    --~ }
    --~ 
    --~ local level_list = get_list('level')
    --~ for i,e in ipairs(level_list) do
        --~ event.level[e] = {
            --~ observable = event.observable,
            --~ controllable = event.controllable,
        --~ }
    --~ end
    --~ 
    --~ local id = self.events:append(event)
    --~ self:update_treeview_events() 
    --~ 
    --~ if not name then
        --~ self:new_event_input(id)
    --~ end
    --~ 
    --~ return event
--~ end

---Adds all events from chosen automaton to the workspace.
--TODO
--@param self, the Controller in which the operation is applied.
--@param automaton Automaton whose events are added to the workspace.
--@see Controller:add_event
--~ function Controller:add_events_from_automaton( automaton )
    --~ for event_id, event in automaton.events:ipairs() do
        --~ local ev
        --~ 
        --~ --Verify if event already exists
        --~ for _, wev in self.events:ipairs() do
            --~ if wev.name == event.name then
                --~ ev = wev
                --~ --[[
                --~ if ev.controllable ~= event.controllable or ev.observable ~= event.observable or ev.refinement ~= event.refinement then
                    --~ gtk.InfoDialog.showInfo('Inconsistency found on event ' .. event.name .. '.\n\nControllable:\n\tWorkspace=' .. tostring(ev.controllable) .. '\n\t' .. automaton:get('file_name') .. '=' .. tostring(event.controllable) .. '\n\nObservable:\n\tWorkspace=' .. tostring(ev.observable) .. '\n\t' .. automaton:get('file_name') .. '=' .. tostring(event.observable)  .. '\n\nRefinement:\n\tWorkspace=' .. tostring(ev.refinement) .. '\n\t' .. automaton:get('file_name') .. '=' .. tostring(event.refinement))
                    --~ event.controllable = ev.controllable
                    --~ event.observable = ev.observable
                    --~ event.refinement = ev.refinement
                --~ end
                --~ ]]--
                --~ ev.level[automaton.level] = {
                    --~ observable = event.observable,
                    --~ controllable = event.controllable,
                --~ }
            --~ end
        --~ end
        --~ if not ev then
            --~ ev = self:add_event(event.name, event.controllable, event.observable, event.refinement)
        --~ end
        --~ ev.automata[automaton] = event
        --~ event.workspace = ev
    --~ end
--~ end

---Deletes an event from the workspace.
--TODO
--@param self, the Controller in which the operation is applied.
--@see Controller:edit_refinement
--@see Controller:update_treeview_events
--~ function Controller:delete_event()
    --~ local events = self.gui.treeview_events:get_selected()
    --~ --Remove refinements
    --~ for _, event_id in ipairs( events ) do
        --~ local e = self.events:get( event_id )
        --~ for wid, wev in self.events:ipairs() do
            --~ if wev.refinement == e.name then
                --~ self:edit_refinement( wid-1, '')
            --~ end
        --~ end
    --~ end
    --~ 
    --~ --Remove events
    --~ for diff, event_id in ipairs( events ) do
        --~ local e = self.events:get( event_id-diff+1 )
        --~ for automaton, ev_id in pairs(e.automata) do
            --~ automaton:event_remove(ev_id)
            --~ automaton:write_log(function()
                --~ self:update_treeview_events()
            --~ end)
        --~ end
        --~ self.events:remove( event_id-diff+1 )
    --~ end
    --~ self:update_treeview_events()
--~ end

---Adds events from the workspace to the current automaton.
--TODO
--@self Controller in which the operation is applied.
--@see Treeview:get_selected
--@see Automaton:event_add
--@see Automaton:write_log
--@see Controller:update_treeview_events
--~ function Controller:to_automaton(self)
    --~ local editor = self.gui:get_current_content()
    --~ if editor and editor.automaton then
        --~ local events = self.gui.treeview_events:get_selected()
        --~ for _, event_id in ipairs( events ) do
            --~ local e = self.events:get( event_id )
            --~ if not e.automata[editor.automaton] then
                --~ editor.automaton:event_add(e.name, e.observable, e.controllable, e.refinement, e)
            --~ end
        --~ end
        --~ editor.automaton:write_log(function()
            --~ self:update_treeview_events()
        --~ end)
        --~ self:update_treeview_events()
    --~ end
--~ end

---Toggles the controllable property of an event.
--TODO
--@param self, the Controller in which the operation is applied.
--@param row_id Id of the row of the event.
--@param hist Historic of updated events.
--@see Automaton:event_set_controllable
--@see Automaton:write_log
--@see Controller:update_treeview_events
function Controller:toggle_controllable( row_id, level, hist)
    local event = self.events:find(row_id+1)
    if not event then return end
    
    level = level or self.level
    
    hist = hist or {}
    hist[event] = true
    
    if level==self.level then
        event.controllable = not event.controllable
    end
    event.level[level].controllable = not event.level[level].controllable
    if event.level[level].controllable then
        for automaton, ev_id in pairs(event.automata) do
            if level==automaton.level then
                automaton:event_set_controllable(ev_id, true)
                automaton:write_log()
            end
        end
    else
        for automaton, ev_id in pairs(event.automata) do
            if level==automaton.level then
                automaton:event_set_controllable(ev_id, false)
                automaton:write_log()
            end
        end
    end
    
    --Change refinements
    for wid, wev in self.events:ipairs() do
        if not hist[wev] and (wev.refinement==event.name or event.refinement==wev.name) then
            self:toggle_controllable(wid-1, level, hist)
        end
    end
    
    self:update_treeview_events()
end

---Toggles the observable property of an event.
--TODO
--@param self, the Controller in which the operation is applied.
--@param row_id Id of the row of the event.
--@param hist Historic of updated events.
--@see Automaton:event_set_observable
--@see Automaton:write_log
--@see Controller:update_treeview_events
--~ function Controller:toggle_observable(self, row_id, level, hist)
    --~ local event = self.events:find(row_id+1)
    --~ if not event then return end
    --~ 
    --~ level = level or self.level
    --~ 
    --~ hist = hist or {}
    --~ hist[event] = true
    --~ 
    --~ if level==self.level then
        --~ event.observable = not event.observable
    --~ end
    --~ event.level[level].observable = not event.level[level].observable
    --~ if event.level[level].observable then
        --~ for automaton, ev_id in pairs(event.automata) do
            --~ if level==automaton.level then
                --~ automaton:event_set_observable(ev_id, true)
                --~ automaton:write_log()
            --~ end
        --~ end
    --~ else
        --~ for automaton, ev_id in pairs(event.automata) do
            --~ if level==automaton.level then
                --~ automaton:event_set_observable(ev_id, false)
                --~ automaton:write_log()
            --~ end
        --~ end
    --~ end
    --~ 
    --~ --Change refinements
    --~ for wid, wev in self.events:ipairs() do
        --~ if not hist[wev] and (wev.refinement==event.name or event.refinement==wev.name) then
            --~ self:toggle_observable(wid-1, level, hist)
        --~ end
    --~ end
    --~ 
    --~ self:update_treeview_events()
--~ end

---Changes the name of an workspace event.
--TODO
--@param self, Controller is which the operation is applied.
--@param row_id Id of the row of the event.
--@param new_name New name of the event.
--@see Automaton:event_set_name
--@see Automaton:write_log
--@see Controller:update_treeview_events
--@see Controller:edit_refinement
--~ function Controller:edit_event( row_id, new_name )
    --~ local event = self.events:find(row_id+1)
    --~ if not event then return end
    --~ 
    --~ new_name = new_name:gsub('[^%&%w%_]','')
    --~ if new_name:find('%&') then
        --~ new_name = '&'
    --~ end
    --~ if new_name:find('EMPTYWORD') then
        --~ new_name = '&'
    --~ end
    --~ 
    --~ --Verify if event already exists
    --~ local exists
    --~ for _, wev in self.events:ipairs() do
        --~ if wev.name == new_name then
            --~ exists = true
        --~ end
    --~ end
    --~ if not exists and #new_name>0 then
        --~ local old_name = event.name
        --~ event.name = new_name
        --~ for automaton, ev_id in pairs(event.automata) do
            --~ automaton:event_set_name(ev_id, new_name)
            --~ automaton:write_log(function()
                --~ self:update_treeview_events()
            --~ end)
        --~ end
        --~ 
        --~ --Change old refinements
        --~ for wid, wev in self.events:ipairs() do
            --~ if wev.refinement == old_name then
                --~ self:edit_refinement( wid-1, event.name)
            --~ end
        --~ end
        --~ 
        --~ self:update_treeview_events()
    --~ end
--~ end

---Changes the name of an workspace event refinement.
--TODO
--@param self, the Controller is which the operation is applied.
--@param row_id Id of the row of the event.
--@param new_name New refinement.
--@see Controller:toggle_controllable
--@see Controller:toggle_observable
--@see Automaton:event_set_refinement
--@see Automaton:write_log
--@see Controller:update_treeview_events
function Controller:edit_refinement( row_id, new_ref )
    local event = self.events:find(row_id+1)
    if not event then return end
    
    --Verify if event is not refined
    for _, wev in self.events:ipairs() do
        if wev.refinement == event.name then
            return
        end
    end
    
    new_ref = new_ref:gsub('[^%&%w%_]','')
    if new_ref:find('%&') then
        new_ref = '&'
    end
    if new_ref:find('EMPTYWORD') then
        new_ref = '&'
    end
    
    --Verify if event already exists
    local exists
    for _, wev in self.events:ipairs() do
        if wev.name == new_ref then
            if wev.refinement == '' then
                exists = wev
            end
            break
        end
    end
    if (exists and new_ref~=event.name) or new_ref=='' then
        if exists then
            local level_list = get_list('level')
            for i,e in ipairs(level_list) do
                if exists.level[e].controllable~=event.level[e].controllable then
                    self:toggle_controllable( row_id, e)
                end
                if exists.level[e].observable~=event.level[e].observable then
                    self:toggle_observable( row_id, e)
                end
            end
        end
        
        event.refinement = new_ref
        for automaton, ev_id in pairs(event.automata) do
            automaton:event_set_refinement(ev_id, new_ref)
            automaton:write_log()
        end
        self:update_treeview_events()
    end
end

---Changes the level of the workspace.
--Verifies if the level really changed. Changes the observable and controllable properties of the events to the new level. Sets the level. If 'automaton' is not nil, changes its events properties as well. Updates the event treeview.
function Controller:change_level(level, automaton)
    if level==self.level then return end
    
    for k_event, event in self.events:ipairs() do
        event.observable = event.level[level].observable
        event.controllable = event.level[level].controllable
    end
    self.level = level
    
    if automaton then
        automaton.level = level
        local ew
        for k_event, event in automaton.events:ipairs() do
            ew = event.workspace
            if ew.observable then
                automaton:event_set_observable(k_event, true)
            else
                automaton:event_set_observable(k_event, false)
            end
            if ew.controllable then
                automaton:event_set_controllable(k_event, true)
            else
                automaton:event_set_controllable(k_event, false)
            end
        end
    end
    
    self:update_treeview_events()
end

------------------------------------------------------------------------
--                          Main Chuck                                --
------------------------------------------------------------------------

controller_instance = Controller.new()
controller_instance:exec()

