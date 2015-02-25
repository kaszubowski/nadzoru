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
module "Chooser"
--]]
Chooser = letk.Class( function( self, options, nowindow )
    options = table.update( {
        title      = 'nadzoru chooser',
        message    = '',
        choices    = {},
        callbacks   = {},
    }, options or {})
    self             = {}
    self.options     = options
    self.btn         = {}
    self.label       = gtk.Label.new(options.message)
    setmetatable( self, Chooser )

	if not nowindow then
        self.window                   = gtk.Window.new( gtk.TOP_LEVEL )
    end
        self.vbox_main            = gtk.Box.new(gtk.ORIENTATION_VERTICAL, 0)
            self.hbox_main        = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
				self.hbox_label   = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
				self.hbox_footer  = gtk.Box.new(gtk.ORIENTATION_HORIZONTAL, 0)
					for i,name in ipairs(options.choices) do
						self.btn[i] = gtk.Button.new_with_label(name)
					end

	if not nowindow then
        self.window:add(self.vbox_main)
    end
        self.vbox_main:pack_start( self.hbox_main, true, true, 0 )
                self.vbox_main:pack_start( self.hbox_label, false, false, 0 )
					self.hbox_label:pack_start( self.label, true, true, 0 )
                self.vbox_main:pack_start( self.hbox_footer, false, false, 0 )
					for i,button in ipairs(self.btn) do
                    	self.hbox_footer:pack_start( button, true, true, 0 )
                    end

	if not nowindow then
        self.window:connect("delete-event", self.window.destroy, self.window)
        self.window:set_modal( true )
    end
	
	for i,button in ipairs(self.btn) do
		self.btn[i]:connect("clicked", function()
			self.window:destroy()
			if type(options.callbacks[i]) == 'function' then
				options.callbacks[i]()
			end
		end)
	end
	
    return self, self.vbox_main
end, Object )

---Runs the chooser.
--TODO
--@param self Chooser to be run.
function Chooser:run()
    if not nowindow then
	    self.window:set("title", self.options.title, "width-request", 0,
		    "height-request", 0, "window-position", gtk.WIN_POS_CENTER,
		    "icon-name", "gtk-about")

	    self.window:show_all()
    end
    
    return self
end
