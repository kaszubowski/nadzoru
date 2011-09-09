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
            print('ERRO: fail load library "id"')
            if msg then print( msg ) end
            os.exit()
        else
            print('WARNING: fail load library "id", some features may not work')
            if msg then print( msg ) end
        end
    end
end

safeload({'lgob.gdk','lgob.gtk','lgob.cairo'}, 'gtk', true, [[You need install 'lgob' to run this software, you can found 'lgob' at http://oproj.tuxfamily.org]])
safeload({'lgob.gtkglext', 'luagl' }, 'opengl', false, [[OpenGL features are disable, a 'lgob' version with 'gtkglext' suport and 'luagl' are required to enable this features]])
safeload('lxp', 'lxp', false, [[no library 'lxp' to manipulate xml format]])

function table.complete( dst, src )
    for k, v in pairs( src ) do
        if dst[ k ] == nil then
            dst[ k ] = v
        end
    end
    return dst
end



--Utils
require('class.object')

require('class.info_dialog')
require('class.list')
require('class.treeview')
require('class.gl_render')
require('class.selector')

require('class.automaton')
require('class.code_gen.init')
require('class.gui')
require('class.simulator')
require('class.graphviz_simulator')
require('class.plant_simulator')
require('class.automaton_render')
require('class.automaton_editor')

Controller    = {}
Controller_MT = { __index = Controller }

setmetatable( Controller, Object_MT )

function Controller.new()
    local self = Object.new()
    setmetatable( self, Controller_MT )

    self.gui              = Gui.new()
    self.elements         = List.new()
    self.active_automaton = nil
    self.simulators       = {}

    self.gui:run()
    self:build()

    return self
end

function Controller:build()
    -----------------------------------
    --          MENU/ACTIONS         --
    -----------------------------------

    -- ** Menu Itens ** --
    --self.gui:append_menu('automatonlist', "_Automatons")
    self.gui:append_menu('automata_operations', "_Automata")
    self.gui:append_menu('simulate', "_Simulate")
    self.gui:append_menu('code', "_Code")



    -- ** Actions * --

    --File
    self.gui:add_action('import_ides', "_Import IDES", "Import a IDES (.xmd) automaton file", nil, self.import_ides, self)

    --Automatons
    --~ self.gui:add_action('remove_automaton', "_Close Automaton", "Close Activate Automaton", nil, self.close_automaton, self)

    --Automata Operations
    self.gui:add_action('automaton_edit', "Edit Automaton", "Edit automaton struct", nil, self.automaton_edit, self)
    self.gui:add_action('operations_accessible', "_Accessible", "Calcule the accessible automata", nil, self.operations_accessible, self)
    self.gui:add_action('operations_coaccessible', "_Coaccessible", "Calcule the coaccessible automata", nil, self.operations_coaccessible, self)
    self.gui:add_action('operations_sync', "_Sync", "Syncronize two or more automatons", nil, self.operations_sync, self)
    self.gui:add_action('operations_join_no_coaccessible', "_Join Coaccessible", "Join Coaccessible States", nil, self.operations_join_no_coaccessible, self)

    --Simulate
    self.gui:add_action('simulategraphviz', "Automaton Simulate _Graphviz", "Simulate Automata in a Graphviz render", nil, self.simulate_graphviz, self)
    self.gui:add_action('simulateplant', "Automaton Simulate _Plant", "Simulate the Plant in a OpenGL render", nil, self.simulate_plant, self)

    --Code
    self.gui:add_action('code_gen_pic_c_monolitic', "PIC C (monolitic)", "Generate C code for PIC - Monolitic", nil, self.code_gen_pic_c_monolitic, self)
    self.gui:add_action('code_gen_pic_c_modular', "PIC C (modular)", "Generate C code for PIC - Modular", nil, self.code_gen_pic_c_modular, self)
    -- TODO: local modular

    -- ** Menu-Action Link ** --
    --File
    self.gui:prepend_menu_item('file','import_ides')

    --Automaton
    --~ self.gui:prepend_menu_item('automatonlist','remove_automaton')

    --Automaton Operations
    self.gui:append_menu_item('automata_operations', 'automaton_edit')
    self.gui:append_menu_item('automata_operations','operations_accessible')
    self.gui:append_menu_item('automata_operations','operations_coaccessible')
    self.gui:append_menu_item('automata_operations','operations_join_no_coaccessible')
    self.gui:append_menu_item('automata_operations','operations_sync')

    --Simulate
    self.gui:append_menu_item('simulate', 'simulategraphviz')
    self.gui:append_menu_item('simulate', 'simulateplant')

    --Code
    self.gui:append_menu_item('code','code_gen_pic_c_monolitic')
    self.gui:append_menu_item('code','code_gen_pic_c_modular')
end

function Controller:exec()
    gtk.main()
end

function Controller:automaton_add( new_automaton )
    self.elements:append( new_automaton )
--[[
    new_automaton:info_set( 'position', position )
    local menu_item = self.gui:append_menu_item(
        'automatonlist',
        {
            caption = new_automaton:info_get( 'short_file_name' ) or new_automaton:info_get( 'file_name' ),
            fn      = function( data )
                data.param.controller.active_automaton = data.param.position
            end,
            param   = { controller = self, position = position },
            type    = 'radio',
        }
    )

    new_automaton:info_set( 'menu_item', menu_item )
--]]
end

--[[
function Controller:automaton_remove( automaton_pos )
    local r_automaton = self.elements:remove( automaton_pos )
    if self.active_automaton == automaton_pos then
        self.active_automaton = nil
    end
    local menu_item = r_automaton:get_info( 'menu_item' )
    self.gui:remove_menu_item( 'automatonlist', menu_item )
end
--]]



------------------------------------------------------------------------
--                           CALLBACKS                                --
------------------------------------------------------------------------

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
            new_automaton:info_set('file_name', filename)
            new_automaton:info_set('short_file_name', select( 3, filename:find( '.-([^/^\\]*)$' ) ) )
            data.param:automaton_add( new_automaton )
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
            return a:info_get( 'short_file_name' )
        end,
        text = 'Automaton:'
    }
    :run()
end

function Controller.simulate_plant( data )
    local simulators = List.new()
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
            return a.automaton:info_get( 'short_file_name' )
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
            return a:info_get( 'short_file_name' )
        end,
        text = 'Automaton:'
    }
    :run()
end

function Controller.code_gen_pic_c_modular( data )
Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automatons  = results[1]
            local random_type = results[2] and results[2][1] or 1
            local choice      = results[3] and results[3][1] or 1
            local input_fn    = results[4] and results[4][1] or 1
            local file        = results[5] or './nofilename'
            if automatons and random_type then
                local cg = CodeGen.new{
                    automatons = List.new_from_table( automatons ) ,
                    random_fn  = random_type,
                    choice_fn  = choice,
                    input_fn   = input_fn,
                    file_name  = file,
                }
                if  cg then
                    cg:execute()
                end
            end
        end,
    })
    :add_multipler{
        list = data.param.elements,
        text_fn  = function( a )
            return a:info_get( 'short_file_name' )
        end,
        text = 'Automaton:'
    }
    :add_combobox{
        list = List.new_from_table{
            { CodeGen.RANDOM_PSEUDOFIX , "Pseudo Random Seed Fixed"    },
            { CodeGen.RANDOM_PSEUDOAD  , "Pseudo Random Seed AD input" },
            { CodeGen.RANDOM_AD        , "AD input"                    },
        },
        text_fn  = function( a )
            return a[2]
        end,
        text = 'Random Type:',
    }
    :add_combobox{
        list = List.new_from_table{
            { CodeGen.CHOICE_RANDOM       , "Random"                       },
            --{ CodeGen.CHOICE_GLOBAL       , "Sequential Global Event List" },
            --{ CodeGen.CHOICE_GLOBALRANDOM , "Random Global Event List"     },
            --{ CodeGen.CHOICE_LOCAL        , "Sequential Local Event List"  },
            --{ CodeGen.CHOICE_LOCALRANDOM  , "Random Local Event List"      },
        },
        text_fn  = function( a )
            return a[2]
        end,
        text = 'Choice:',
    }
    :add_combobox{
        list = List.new_from_table{
            { CodeGen.INPUT_TIMER       , "Timer Interruption"                },
            { CodeGen.INPUT_MULTIPLEXED , "Multiplexed External Interruption" },
            --{ CodeGen.INPUT_EXTERNAL    , "External Interruption"             },
        },
        text_fn  = function( a )
            return a[2]
        end,
        text = 'Input (Delay Sensibility):',
    }
    :add_file{
        text = 'file',
    }
    :run()
end

function Controller.code_gen_pic_c_monolitic( data )
Selector.new({
        title = 'nadzoru',
         success_fn = function( results, numresult )
            local automaton   = results[1]
            local random_type = results[2] and results[2][1] or 1
            local choice      = results[3] and results[3][1] or 1
            local ds          = results[4] and results[4][1] or 1
            local file        = results[5] or './nofilename'
            if automaton and random_type then
                CodeGen.new{
                    automatons = List.new_from_table{ automaton } ,
                    random_fn  = random_type,
                    choice_fn  = choice,
                    delay_s_fn = ds,
                    file_name  = file,
                }
                :execute()
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
        text_fn  = function( a )
            return a:info_get( 'short_file_name' )
        end,
        text = 'Automaton:'
    }
    :add_combobox{
        list = List.new_from_table{
            { CodeGen.RANDOM_PSEUDOFIX , "Pseudo Random Seed Fixed"    },
            { CodeGen.RANDOM_PSEUDOAD  , "Pseudo Random Seed AD input" },
            { CodeGen.RANDOM_AD        , "AD input"                    },
        },
        text_fn  = function( a )
            return a[2]
        end,
        text = 'Random Type:',
    }
    :add_combobox{
        list = List.new_from_table{
            { CodeGen.CHOICE_RANDOM       , "Random"                       },
            { CodeGen.CHOICE_GLOBAL       , "Sequential Global Event List" },
            { CodeGen.CHOICE_GLOBALRANDOM , "Random Global Event List"     },
            { CodeGen.CHOICE_LOCAL        , "Sequential Local Event List"  },
            { CodeGen.CHOICE_LOCALRANDOM  , "Random Local Event List"      },
        },
        text_fn  = function( a )
            return a[2]
        end,
        text = 'Choice:',
    }
    :add_combobox{
        list = List.new_from_table{
            { CodeGen.DS_NONE        , "None"                              },
            { CodeGen.DS_TIMER       , "Timer Interruption"                },
            { CodeGen.DS_EXTERNAL    , "External Interruption"             },
            { CodeGen.DS_MULTIPLEXED , "Multiplexed External Interruption" },
        },
        text_fn  = function( a )
            return a[2]
        end,
        text = 'Delay Sensibility:',
    }
    :add_file{
        text = 'file',
    }
    :run()
end

--~ function Controller.close_automaton( data )
    --~ if data.param.active_automaton then
        --~ data.param:automaton_remove( data.param.active_automaton )
    --~ end
--~ end

-- ** Operations ** --
function Controller.operations_accessible( data )
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automaton = results[1]
            if automaton then
                local new_automaton = automaton:clone()
                new_automaton:accessible()
                new_automaton:info_set('short_file_name', 'accessible(' .. automaton:info_get('short_file_name') .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
        text_fn  = function( a )
            return a:info_get( 'short_file_name' )
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
                local new_automaton = automaton:clone()
                new_automaton:coaccessible()
                new_automaton:info_set('short_file_name', 'coaccessible(' .. automaton:info_get('short_file_name') .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
        text_fn  = function( a )
            return a:info_get( 'short_file_name' )
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
                local new_automaton = automaton:clone()
                new_automaton:join_no_coaccessible_states()
                new_automaton:info_set('short_file_name', 'join_no_coaccessible(' .. automaton:info_get('short_file_name') .. ')')
                data.param.elements:append( new_automaton )
            end
        end,
    })
    :add_combobox{
        list = data.param.elements,
        text_fn  = function( a )
            return a:info_get( 'short_file_name' )
        end,
        text = 'Automaton:'
    }
    :run()
end

function Controller.operations_sync( data )
    Selector.new({
        title = 'nadzoru',
        success_fn = function( results, numresult )
            local automatons = results[1]
            for k, v in ipairs( automatons ) do

            end
        end,
    })
    :add_multipler{
        list = data.param.elements,
        text_fn  = function( a )
            return a:info_get( 'short_file_name' )
        end,
        text = 'Automaton:'
    }
    :run()
end
------------------------------------------------------------------------
--                          Main Chuck                                --
------------------------------------------------------------------------

controller_instance = Controller.new()
controller_instance:exec()

