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
require('lgob.gdk')
require('lgob.gtk')
require('lgob.cairo')
require('lgob.gtkglext')
require('luagl')
require('lxp')


--Utils
require('class.object')

require('class.list')
require('class.treeview')
require('class.gl_render')

require('class.automaton')
require('class.code_gen')
require('class.gui')
require('class.simulator')
require('class.graphviz_simulator')
require('class.plant_simulator')

Controller    = {}
Controller_MT = { __index = Controller }

setmetatable( Controller, Object_MT )

function Controller.new()
    local self = Object.new()
    setmetatable( self, Controller_MT )

    self.gui              = Gui.new()
    self.automatons       = List.new()
    self.active_automaton = nil
    self.simulators       = {}

    self.gui:run()
    self:build()

    return self
end

function Controller:build()
    -----------------------------------
    --            ACTIONS            --
    -----------------------------------
    --Build open IDES:
    self.gui:add_action('import_ides', "_Import IDES", "Import a IDES (.xmd) automaton file", nil, self.import_ides, self)

    self.gui:add_action('remove_automaton', "_Close Automaton", "Close Activate Automaton", nil, self.close_automaton, self)

    self.gui:add_action('simulategraphviz', "Simulate _Graphviz", "Simulate Automata in a Graphviz render", nil, self.simulate_graphviz, self)
    self.gui:add_action('simulateplant', "Simulate _Plant", "Simulate the Plant in a OpenGL render", nil, self.simulate_plant, self)

    self.gui:add_action('codegen_pic_c', "PIC C - extreme memory safe (monolitic)", "Generate C code for PIC - Monolitic", nil, self.code_gen_pic_c, self)


    --Menu Itens
    self.gui:append_menu('automatonlist', "_Automatons")
    self.gui:append_menu('code', "_Code")
    self.gui:append_menu('simulate', "_Simulate")
    self.gui:append_menu('operations', "_Operations")

    --File
    self.gui:prepend_menu_item('file','import_ides')

    --Automaton
    self.gui:prepend_menu_item('automatonlist','remove_automaton')

    --Code
    self.gui:prepend_menu_item('code','codegen_pic_c')

    --Simulate
    self.gui:append_menu_item('simulate', 'simulategraphviz')
    self.gui:append_menu_item('simulate', 'simulateplant')

    --Operations

end

function Controller:exec()
    gtk.main()
end

function Controller:automaton_add( new_automaton )
    local position = self.automatons:append( new_automaton )
    new_automaton:set_info( 'position', position )

    local menu_item = self.gui:append_menu_item(
        'automatonlist',
        {
            caption = new_automaton:get_info( 'short_file_name' ) or new_automaton:get_info( 'file_name' ),
            fn      = function( data )
                data.param.controller.active_automaton = data.param.position
            end,
            param   = { controller = self, position = position },
            type    = 'radio',
        }
    )

    new_automaton:set_info( 'menu_item', menu_item )
end

function Controller:automaton_remove( automaton_pos )
    local r_automaton = self.automatons:remove( automaton_pos )
    if self.active_automaton == automaton_pos then
        self.active_automaton = nil
    end
    local menu_item = r_automaton:get_info( 'menu_item' )
    self.gui:remove_menu_item( 'automatonlist', menu_item )
end



------------------------------------------------------------------------
--                           CALLBACKS                                --
------------------------------------------------------------------------

function Controller.import_ides( data )
    local dialog = gtk.FileChooserDialog.new(
        "Select the file", window, gtk.FILE_CHOOSER_ACTION_OPEN,
        "gtk-cancel", gtk.RESPONSE_CANCEL,
        "gtk-ok", gtk.RESPONSE_OK
    )
    local filter = gtk.FileFilter.new()
    filter:add_pattern("*.xmd")
    filter:set_name("IDES3 automaton")
    dialog:add_filter(filter)
    dialog:set("select-multiple", false)
    local response = dialog:run()
    dialog:hide()
    local names = dialog:get_filenames()
    if response == gtk.RESPONSE_OK and names and names[1] then
        local new_automaton = Automaton.new()
        new_automaton:read_IDES( names[1] )
        new_automaton:set_info('file_name', names[1])
        new_automaton:set_info('short_file_name', select( 3, names[1]:find( '.-([^/^\\]*)$' ) ) )
        data.param:automaton_add( new_automaton )

    end
end

function Controller.simulate_graphviz( data )
    if data.param.active_automaton then
        local automaton = data.param.automatons:get( data.param.active_automaton )
        if automaton then
            local graphvizsimulator = GraphvizSimulator.new( data.gui, automaton )
            data.param.simulators[ graphvizsimulator ] = true
            graphvizsimulator:bind('destroy', function( graphvizsimulator, controller)
                controller.simulators[ graphvizsimulator ] = nil
            end, data.param )
        end
    end
end

function Controller.simulate_plant( data )
    if type(data.param.simulators) == 'table' then
        --abrir uma janela mostrando as simulações para escolher uma
        for sim, _ in pairs( data.param.simulators ) do
            PlantSimulator.new( data.gui, sim )
        end
    end
end

function Controller.code_gen_pic_c( data )
    if data.param.active_automaton then
        local automaton = data.param.automatons:get( data.param.active_automaton )
        if automaton then
            local dialog = gtk.FileChooserDialog.new(
                "Create the file", window,gtk.FILE_CHOOSER_ACTION_SAVE,
                "gtk-cancel", gtk.RESPONSE_CANCEL,
                "gtk-ok", gtk.RESPONSE_OK
            )
            local response = dialog:run()
            dialog:hide()
            local names = dialog:get_filenames()
            if response == gtk.RESPONSE_OK and names and names[1] then
                local gen = CodeGen.new ( automaton )
                gen:pic_c( names[1] )
            end
        end
    end
end

function Controller.close_automaton( data )
    if data.param.active_automaton then
        data.param:automaton_remove( data.param.active_automaton )
    end
end
------------------------------------------------------------------------
--                          Main Chuck                                --
------------------------------------------------------------------------

controller_instance = Controller.new()
controller_instance:exec()

