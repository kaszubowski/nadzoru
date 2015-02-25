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
module "PlantSimulator"
--]]
PlantSimulator = letk.Class( function( self, gui, simulator )
    self.simulator = simulator
    self.automaton = self.simulator.automaton
    self.gui       = gui

    self.vbox         = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
        self.hbox         = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
            self.scrolled     = gtk.ScrolledWindow.new( )
                self.drawing_area = gtk.DrawingArea.new( )

    self.vbox:pack_start(self.hbox, true, true, 0)
        self.hbox:pack_start(self.scrolled, true, true, 0)
            self.scrolled:add(self.drawing_area)

    gui:add_tab( self.vbox, 'PS ' .. (self.automaton:get('file_name') or '-x-' ) )

    self.glrender = GLRender.new( self.drawing_area )
    --Jogar para o :run()
    self:set_render_callback()
end, Object )

---Loads a plant.
--Unfinished. TODO
--@param self Plant simulator in which the plant will be loaded.
--@param filename Filename of the plant.
function PlantSimulator:load_plant( filename )

end

---TODO
--Unfinished. TODO
--@param self TODO
function PlantSimulator:set_render_callback()

    local function render_callback( glrender_self )

    end
    self.glrender:set_render_callback(  render_callback )
end
