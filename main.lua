#!/usr/bin/lua
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
--External Libs
LibLoad = {}
local function safeload( libs, id, required, msg )
    local function safeload_call()
        libs = type(libs) == 'table' and libs or { libs }
        for _, lib in ipairs( libs ) do
            require( lib )
        end
    end
    LibLoad[id], LibLoad[id .. '_info'] = pcall( safeload_call )
    if not LibLoad[id] then
        if required then
            print('ERRO: fail load library "' .. id .. '"')
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
safeload('lxp', 'lxp', false, [[no library 'lxp' to manipulate xml format]])
safeload('redis', 'redis', false, [[no library 'redis' (redis-lua)]])

--Utils
require('class.object')

require('class.info_dialog')
require('class.treeview')
require('class.selector')
require('class.property_editor')

require('class.automaton')
require('class.automata_group')
require('class.code_gen.init')
require('class.gui')
require('class.simulator')
require('class.graphviz_simulator')
require('class.plant_simulator')
require('class.automaton_render')
require('class.automaton_editor')
require('class.scada.init')

local CodeGenDevices = require 'res.codegen.devices.main'

Controller = letk.Class( function( self )
    self.gui              = Gui.new()
    self.elements         = letk.List.new()
    self.active_automaton = nil
    self.simulators       = {}

    self.gui:run()
    self:build()
end, Object )

function Controller:build()
    -----------------------------------
    --          MENU/ACTIONS         --
    -----------------------------------

    -- ** Menu Itens ** --
    self.gui:append_menu('automata', "_Automata")
    self.gui:append_menu('scada_mes', "_SCADA/MES")

    -- ** Actions * --

    --File
    self.gui:add_action('tab_close_current'   , "_Close Current Tab", "Close CurrentTab", nil, function()
        self.gui:remove_current_tab()
    end)

    --Automata
    self.gui:add_action('automata_new'        , "_New Automaton", "Create a New Automaton", nil, self.create_new_automaton, self)
    self.gui:add_action('automata_open'       , "_Open Automaton", "Open a New Automaton", nil, self.open_automaton, self)
    self.gui:add_action('automata_import_ides', "_Import IDES Automaton", "Import a IDES (.xmd) automaton file", nil, self.import_ides, self)
    self.gui:add_action('automata_group_new'  , "_New Automata Group", "Create a New Automata Group", nil, self.automata_group_new, self)
    self.gui:add_action('automata_group_load'  , "_Load Automata Group", "Load an Automata Group", nil, self.automata_group_load, self)
    self.gui:add_action('automata_group_edit'  , "_Edit Automata Group", "Edit an Automata Group", nil, self.automata_group_edit, self)
    self.gui:add_action('automaton_edit', "Edit Automaton", "Edit automaton struct", nil, self.automaton_edit, self)
    self.gui:add_action('code_gen_dfa', "DFA - Code Generator", "Deterministic Finite Automata - Code Generate", nil, self.code_gen_dfa, self)
    self.gui:add_action('operations_accessible', "_Accessible", "Calcule the accessible automata", nil, self.operations_accessible, self)
    self.gui:add_action('operations_coaccessible', "_Coaccessible", "Calcule the coaccessible automata", nil, self.operations_coaccessible, self)
    self.gui:add_action('operations_trim', "_Trim", "Calcule the trim automata", nil, self.operations_trim, self)
    self.gui:add_action('operations_join_no_coaccessible', "_Join Coaccessible", "Join Coaccessible States", nil, self.operations_join_no_coaccessible, self)
    self.gui:add_action('operations_selfloop', "_SelfLoop", "Self Loop in a automaton with a set of other automata events", nil, self.operations_selfloop, self)
    self.gui:add_action('operations_synchronization', "_Synchronization", "Synchronization of two or more automatons", nil, self.operations_synchronization, self)
    self.gui:add_action('operations_product', "_Product", "Calculate the Product of two or more automatons", nil, self.operations_product, self)
    self.gui:add_action('operations_supc', "_SupC", "Calculate the operations_supc", nil, self.operations_supc, self)
    self.gui:add_action('operations_check_choice_problem', "_Check Choice Problem", "Check if states have the choice problem", nil, self.operations_check_choice_problem, self)
    self.gui:add_action('operations_check_avalanche_effect', "_Check Avalanche Effect", "Check if states have the avalanche effect", nil, self.operations_check_avalanche_effect, self)
    self.gui:add_action('operations_check_inexact_synchronization', "_Check Inexact Synchronization", "Check Inexact Synchronization", nil, self.operations_check_inexact_synchronization, self)

    --Simulate
    self.gui:add_action('simulategraphviz', "Automaton Simulate _Graphviz", "Simulate Automata in a Graphviz render", nil, self.simulate_graphviz, self)
    --self.gui:add_action('simulateplant', "Automaton Simulate _Plant", "Simulate the Plant in a OpenGL render", nil, self.simulate_plant, self)

    --SCADA
    self.gui:add_action('scada_plant_new'   , "_New SCADA Plant", "Create a New SCADA Plant", nil, self.create_new_scada_plant, self)
    self.gui:add_action('scada_plant_load'   , "_Load SCADA Plant", "Load a SCADA Plant", nil, self.load_scada_plant, self)
    self.gui:add_action('scada_plant_edit'  , "Edit SCADA Plant", "Edit a SCADA Plant", nil, self.scada_plant_edit, self)
    self.gui:add_action('scada_plant_view'  , "SCADA View", "SCADA View Interface", nil, self.scada_plant_view, self)
    self.gui:add_action('scada_mes_server', "SCADA/MES Server", "SCADA/MES Server", nil, self.scada_mes_server, self)

    -- ** Menu-Action Link ** --
    --File
    self.gui:prepend_menu_separator('file')
    self.gui:prepend_menu_item('file','tab_close_current')
    

    --Automaton Operations
    self.gui:append_menu_item('automata','automata_new')
    self.gui:append_menu_item('automata','automata_open')
    self.gui:append_menu_item('automata','automata_import_ides')
    self.gui:append_menu_separator('automata')
    self.gui:append_menu_item('automata','automata_group_new')
    self.gui:append_menu_item('automata','automata_group_load')
    self.gui:append_menu_item('automata','automata_group_edit')
    self.gui:append_menu_separator('automata')
    self.gui:append_menu_item('automata','automaton_edit')
    self.gui:append_menu_item('automata','code_gen_dfa')
    self.gui:append_sub_menu('automata','operations', "Operations")
    self.gui:append_menu_item('operations','operations_accessible')
    self.gui:append_menu_item('operations','operations_coaccessible')
    self.gui:append_menu_item('operations','operations_trim')
    self.gui:append_menu_item('operations','operations_join_no_coaccessible')
    self.gui:append_menu_item('operations','operations_selfloop')
    self.gui:append_menu_item('operations','operations_synchronization')
    self.gui:append_menu_item('operations','operations_product')
    self.gui:append_menu_item('operations','operations_supc')
    self.gui:append_menu_item('operations','operations_check_choice_problem')
    self.gui:append_menu_item('operations','operations_check_avalanche_effect')
    self.gui:append_menu_item('operations','operations_check_inexact_synchronization')
    self.gui:append_menu_item('automata', 'simulategraphviz')

    --SCADA
    self.gui:append_menu_item('scada_mes', 'scada_plant_new')
    self.gui:append_menu_item('scada_mes', 'scada_plant_load')
    self.gui:append_menu_item('scada_mes', 'scada_plant_edit')
    self.gui:append_menu_item('scada_mes', 'scada_plant_view')
    self.gui:append_menu_item('scada_mes', 'scada_mes_server')

end

function Controller:exec()
    gtk.main()
end

function Controller:element_add( new_element )
    self.elements:append( new_element )
end

local space_things = {
    ['xmd'] = { class = Automaton     , fn = 'IDES_import' },
    ['nza'] = { class = Automaton     , fn = 'load_file'   },
    ['nag'] = { class = AutomataGroup , fn = 'load_file'   },
    ['nsp'] = { class = ScadaPlant    , fn = 'load_file', elements = true },
}

function Controller:save_workspace( file_name )
    local data = {}
    for k, e in self.elements:ipairs() do
        local file_type   = e:get('file_type')
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
                if e.file_type and space_things[ e.file_type ] then
                    local ElementClass = space_things[ e.file_type ].class
                    local new_element  = ElementClass.new()
                    if space_things[ e.file_type ].elements then
                        new_element[space_things[ e.file_type ].fn ]( e.full_file_name, self.elements  )
                    else
                        new_element[space_things[ e.file_type ].fn ]( e.full_file_name )
                    end
                    self:element_add( new_element )
                end
            end
        end
    end
end

------------------------------------------------------------------------
--                           CALLBACKS                                --
------------------------------------------------------------------------

--- AUTOMATA ---

function Controller.create_new_automaton( data )
    local new_automaton = Automaton.new()
    data.param:element_add( new_automaton )
end

function Controller.open_automaton( data )
    local dialog = gtk.FileChooserDialog.new(
        "Select the file", nil, gtk.FILE_CHOOSER_ACTION_OPEN,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.nza")
    filter:set_name("Nadzoru automaton")
    dialog:add_filter(filter)
    dialog:set("select-multiple", true)
    local response = dialog:run()
    dialog:hide()
    local filenames = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and filenames then
        for k_filename, filename in ipairs( filenames ) do
            local new_automaton = Automaton.new()
            new_automaton:load_file( filename )
            data.param:element_add( new_automaton )
        end
    end
end

function Controller.import_ides( data )
    local dialog = gtk.FileChooserDialog.new(
        "Select the file", nil, gtk.FILE_CHOOSER_ACTION_OPEN,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.xmd")
    filter:set_name("IDES3 automaton")
    dialog:add_filter(filter)
    dialog:set("select-multiple", true)
    local response = dialog:run()
    dialog:hide()
    local filenames = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and filenames then
        for k_filename, filename in ipairs( filenames ) do
            local new_automaton = Automaton.new()
            new_automaton:IDES_import( filename )
            data.param:element_add( new_automaton )
        end
    end
end

function Controller.simulate_graphviz( data )
    Selector.new({
        title = 'Select automaton to simulate',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local graphvizsimulator = GraphvizSimulator.new( data.gui, automaton )
                data.param.simulators[ graphvizsimulator ] = true
                graphvizsimulator:bind('destroy', function( graphvizsimulator, controller)
                    controller.simulators[ graphvizsimulator ] = nil
                end, data.param )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

function Controller.simulate_plant( data )
    local simulators = letk.List.new()
    for c,v in pairs( data.param.simulators ) do
        simulators:add( c )
    end
    Selector.new({
        title = 'Select automaton to simulate',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                PlantSimulator.new( data.gui, automaton )
            end
        end,
    })
    :add_combobox{
        list = simulators,
        text_fn  = function( a )
            return a.automaton:get( 'file_name' )
        end,
        text = 'Automaton:'
    }
    :run()
end

function Controller.automaton_edit( data )
    Selector.new({
        title = 'Select automaton to edit',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                AutomatonEditor.new( data.gui, automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

function Controller.code_gen_dfa( data )
    local devices_list = {}
    for id, device in pairs(CodeGenDevices) do
        if device.display then
            devices_list[#devices_list + 1] = { id , device.name }
        end
    end

    table.sort( devices_list, function( a,b ) return a[1] > a[2] end )

    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automata       = results[1]
            local file_name      = results[2]
            local device_id      = results[3] and results[3][1]
            local event_map      = results[4]
            local event_map_file = results[5]
            if #automata > 0 and #file_name > 0 and device_id then
                local lautomata = letk.List.new_from_table( automata )
                local cg = CodeGen.new{ 
                    automata       = lautomata, 
                    device_id      = device_id, 
                    file_name      = file_name,
                    event_map      = event_map,
                    event_map_file = event_map_file
                }
                if  cg then
                    cg:execute( data.gui )
                end
            end
        end,
    })
    :add_multipler{
        list = data.param.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :add_file{
        text = "Code File:",
        filter = 'c',
        filter_name = "C Code",
    }
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
        text = "Event Map File:",
        filter = 'nem',
        filter_name = "Nadzoru Event Map",
    }
    :run()
end

-- ** Operations ** --
function Controller.operations_accessible( data )
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:accessible( results[2], false )
                new_automaton:set('file_name', 'accessible(' .. automaton:get('file_name') .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

function Controller.operations_coaccessible( data )
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:coaccessible( results[2], false )
                new_automaton:set('file_name', 'coaccessible(' .. automaton:get('file_name') .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

function Controller.operations_join_no_coaccessible( data )
     Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:join_no_coaccessible_states( false )
                new_automaton:set('file_name', 'join_no_coaccessible(' .. automaton:get('file_name') .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

function Controller.operations_trim( data )
     Selector.new({
        title = "nadzoru",
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:trim( results[2], false )
                new_automaton:set('file_name', 'trim(' .. automaton:get('file_name') .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

function Controller.operations_selfloop( data )
     Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:selfloop( false, unpack( results[2] ) )
                new_automaton:set('file_name', 'selfloop(' .. automaton:get('file_name') .. ', ...' .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = "Automaton:"
    }
    :add_multipler{
        list = data.param.elements,
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

function Controller.operations_synchronization( data )
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automatons = results[1]
             if automatons then
                local new_automaton = Automaton.synchronization( unpack( automatons ) )
                new_automaton:set('file_name', 'synchronization(' .. '...' .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_multipler{
        list = data.param.elements,
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

function Controller.operations_product( data )
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automatons = results[1]
            if automatons then
                local new_automaton = Automaton.product( unpack( automatons ) )
                new_automaton:set('file_name', 'product(' .. '...' .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_multipler{
        list = data.param.elements,
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

function Controller.operations_supc( data )
     Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local g = results[1]
            local k = results[2]
            if g and k then
                local new_automaton = Automaton.supC(g, k)
                new_automaton:set( 'file_name', 'supC(' .. ')' )
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
        text_fn  = function( a )
            return a:get( 'file_name' )
        end,
        filter_fn = function( v )
            return v.__TYPE == 'automaton'
        end,
        text = 'G:'
    }
    :add_combobox{
        list = data.param.elements,
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

function Controller.operations_check_choice_problem( data )
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:check_choice_problem( false )
                new_automaton:set('file_name', 'choice(' .. automaton:get('file_name') .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

function Controller.operations_check_avalanche_effect( data )
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:check_avalanche_effect( false, results[2]  )
                new_automaton:set('file_name', 'avalanche(' .. automaton:get('file_name') .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

function Controller.operations_check_inexact_synchronization( data )
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:check_inexact_synchronization( false )
                new_automaton:set('file_name', 'inexactsync(' .. automaton:get('file_name') .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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
function Controller.automata_group_new( data )
    local nag = AutomataGroup .new()
    data.param:element_add( nag )
end

function Controller.automata_group_load( data )
    local dialog = gtk.FileChooserDialog.new(
        "Select the file", nil, gtk.FILE_CHOOSER_ACTION_OPEN,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.nag")
    filter:set_name("Nadzoru Automata Group")
    dialog:add_filter(filter)
    dialog:set("select-multiple", true)
    local response = dialog:run()
    dialog:hide()
    local filenames = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and filenames then
        for k_filename, filename in ipairs( filenames ) do
            local nag = AutomataGroup.new()
            nag:load_file( filename )
            data.param:element_add( nag )
        end
    end
end

function Controller.automata_group_edit( data )
    Selector.new({
        title = "Select an Automata Group to edit",
        success_fn = function( results, numresult )
            local ag = results[1]
            if ag then
                local AG_editor = AutomataGroupEditor.new( data.gui, ag, data.param.elements )
                AG_editor:start_automaton_window()
                AG_editor:update_automaton_window()
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

function Controller.create_new_scada_plant( data )
    local new_scada_plant = ScadaPlant.new()
    data.param:element_add( new_scada_plant )
end

function Controller.load_scada_plant( data )
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
            new_scada_plant:load_file( filename, data.param.elements )
            data.param:element_add( new_scada_plant )
        end
    end
end

function Controller.scada_plant_edit( data )
    Selector.new({
        title = "Select scada plant to edit",
        success_fn = function( results, numresult )
            local plant = results[1]
            if plant then
                ScadaEditor.new( data.gui, plant, data.param.elements )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

function Controller.scada_plant_view( data )
    Selector.new({
        title = "Select scada plant to view/run",
        success_fn = function( results, numresult )
            local plant = results[1]
            if plant then
                ScadaView.new( data.gui, plant, data.param.elements )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

function Controller.scada_mes_server( data )
     Selector.new({
        title = "Open Server",
        success_fn = function( results, numresult )
            local automata_group = results[1]
            local event_map_file = results[2]
            if automata_group and event_map_file then
                ScadaServer.new( data.gui, automata_group, event_map_file, data.param.elements )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
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

------------------------------------------------------------------------
--                          Main Chuck                                --
------------------------------------------------------------------------
controller_instance = Controller.new()
controller_instance:exec()

