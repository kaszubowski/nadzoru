PlantSimulator         = {}
PlantSimulator.__index = PlantSimulator

setmetatable( PlantSimulator, Object )

function PlantSimulator.new( gui, simulator )
    local self = Object.new()
    setmetatable( self, PlantSimulator )

    self.simulator = simulator
    self.automaton = self.simulator.automaton
    self.gui       = gui

    self.vbox         = gtk.VBox.new(false, 0)
        self.hbox         = gtk.HBox.new(false, 0)
            self.scrolled     = gtk.ScrolledWindow.new( )
                self.drawing_area = gtk.DrawingArea.new( )

    self.vbox:pack_start(self.hbox, true, true, 0)
        self.hbox:pack_start(self.scrolled, true, true, 0)
            self.scrolled:add_with_viewport(self.drawing_area)

    gui:add_tab( self.vbox, 'PS ' .. (self.automaton:info_get('short_file_name') or '-x-' ) )

    self.glrender = GLRender.new( self.drawing_area )
    --Jogar para o :run()
    self:set_render_callback()

    return self
end

function PlantSimulator:load_plant( filename )

end

function PlantSimulator:set_render_callback()

    local function render_callback( glrender_self )

    end
    self.glrender:set_render_callback(  render_callback )
end
