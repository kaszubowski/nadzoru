--[[
    TODO:
        renderizar self-loop
        cor seecionado
--]]

AutomatonRender    = {}
AutomatonRender_MT = { __index = AutomatonRender }

setmetatable( AutomatonRender, Object_MT )


function AutomatonRender.new( automaton )
    local self = {}
    setmetatable( self, AutomatonRender_MT)

    self.automaton = automaton
    self.color_states      = {}
    self.color_transitions = {}

    self.scrolled          = gtk.ScrolledWindow.new()
        self.drawing_area  = gtk.DrawingArea.new( )

    self.scrolled:add_with_viewport(self.drawing_area)

    self.drawing_area:connect("expose-event", self.drawing_area_expose, self )

    return self, self.scrolled, self.drawing_area
end

local function dot(cr, x, y, c)
    c = c or {0,0,0}
    cr:set_source_rgb(c[1], c[2], c[3])
    cr:move_to(x-5,y)
    cr:line_to(x+5, y)
    cr:stroke()
    cr:set_source_rgb(c[1], c[2], c[3])
    cr:move_to(x,y-5)
    cr:line_to(x, y+5)
    cr:stroke()
end

local function torad( a )
    return math.pi * (a/180)
end

local function todeg( r )
    return 180*r/math.pi
end

local function arrow(cr, xe, ye, xr, yr, r, c)
    c = c or {0,0,0}
    local xv, yv = xr - xe, yr - ye
    local m = r -- math.sqrt( xv^2 + yv^2 )
    local xv2, yv2 = xv/m, yv/m
    local xf, yf   = xe-(15*xv2), ye-(15*yv2)
    local xo1, yo1 = -(6*yv2)+xf, (6*xv2)+yf
    local xo2, yo2 = (6*yv2)+xf, -(6*xv2)+yf

    cr:set_source_rgb(c[1], c[2], c[3])
    cr:move_to(xe, ye)
    cr:line_to(xo1, yo1)
    cr:line_to(xo2, yo2)
    cr:line_to(xe, ye)
    cr:fill()
end

function AutomatonRender:draw( color_states, color_transitions)
    self.color_states      = color_states or self.color_states
    self.color_transitions = color_transitions or self.color_transitions
    self.drawing_area:queue_draw()
end

function AutomatonRender:drawing_area_expose()
    local cr   = gdk.cairo_create( self.drawing_area:get_window() )
    local size = {x=0,y=0}

    local states_position = {}
    local create_X, create_Y = 128, 128

    for id, state in self.automaton.states:ipairs() do
        local x,y = self.automaton:state_get_position( id )
        if not x or not y then
            x,y = create_X, create_Y
            create_X = create_X + 128
            if create_X > 1024 then
                create_X = 128
                create_Y = create_Y + 128
            end
            self.automaton:state_set_position( id,x,y )
        end

        --write name and set r based in name len
        cr:select_font_face("sans", cairo.FONT_SLANT_OBLIQUE)
        cr:set_font_size(20)
        local txt_ext = cairo.TextExtents.create( )
        cr:text_extents( state.name or "", txt_ext )
        local x_bearing, y_bearing, txt_width, txt_height, x_advance, y_advance = txt_ext:get()
        txt_ext:destroy()
        local r   = (txt_width/2) + 15
        state.r   = r
        cr:move_to( x-(txt_width/2), y+(txt_height/2) )
        cr:show_text(state.name or tostring(id))
        cr:stroke()

        states_position[#states_position +1] = {x=x,y=y,r=r}
        size.x = math.max(x+r,size.x)
        size.y = math.max(y+r,size.y)
        states_position[state]               = #states_position --state is a <table>

        cr:set_line_width(2)
        cr:arc( x, y, r, 0, 2 * math.pi )
        cr:stroke()

        if state.marked then
            cr:arc( x, y, r-5, 0, 2 * math.pi )
            cr:stroke()
        end

        if state.initial then
            cr:move_to(x-(r+30),y)
            cr:line_to(x-r, y)
            cr:stroke()

            cr:move_to(x-(r+15), y+6)
            cr:line_to(x-r, y)
            cr:line_to(x-(r+15), y-6)
            cr:line_to(x-(r+15), y+6)
            cr:fill()
        end
    end

    local transitions_out  = {}
    local transitions_self = {}

    for id, trans in self.automaton.transitions:ipairs() do
        --trans.source and trans.target are <table>
        local source_id, target_id = states_position[trans.source], states_position[trans.target]
        if source_id ~= target_id then
            local index                = source_id .. '_' .. target_id
            local xs, ys, rs           = states_position[source_id].x, states_position[source_id].y, states_position[source_id].r
            local xt, yt, rt           = states_position[target_id].x, states_position[target_id].y, states_position[target_id].r

            transitions_out[index] = transitions_out[index] or {xs=xs, ys=ys, rs=rs, xt=xt, yt=yt, rt=rt, factor = 2 }
            table.insert( transitions_out[index], trans.event.name )
        else
            transitions_self[source_id] = transitions_self[source_id] or {
                x = states_position[source_id].x,
                y = states_position[source_id].y,
                r = states_position[source_id].r
            }
            table.insert( transitions_self[source_id], trans.event.name )
        end
    end


    for c,v in pairs( transitions_out ) do
        local xp,yp     = (v.xs - v.xt)/2 + v.xt, (v.ys - v.yt)/2 + v.yt --P
        local xv1, yv1  = xp-v.xs, yp-v.ys -- V1
        local xv2, yv2  = -yv1*v.factor, xv1*v.factor --V2
        local xc, yc    = xv2+xp, yv2+yp
        local r         = math.sqrt(  (v.xs-xc)^2 + (v.ys-yc)^2  )
        local h         = r - math.sqrt( (xp-xc)^2 + (yp-yc)^2 )
        local s         = math.sqrt( (xp-v.xs)^2 + (yp-v.ys)^2 )
        local xv3, yv3  = yv1/s, -xv1/s --V3 (-V2 no factor)

        local as_, qs   = math.acos((v.xs - xc)/r),(v.ys - yc)/r
        local as        = qs >= 0 and as_ or (2*math.pi) - as_
        local at_, qt   = math.acos((v.xt - xc)/r),(v.yt - yc)/r
        local at        = qt >= 0 and at_ or (2*math.pi) - at_

        --formula da corda c = 2*r*sin(ang/2)
        local ass, ast = math.asin( v.rs/(2*r) )*2, math.asin( v.rt/(2*r) )*2

        if (as <= at and (at-as)<=math.pi) then
            if (as+ass) < (at-ast) then
                local xe, ye = xc + math.cos(at-ast)*r, yc + math.sin(at-ast)*r
                arrow(cr, xe, ye, v.xt, v.yt, v.rt, {0.15, 0.15, 0.15})
                cr:set_source_rgb(0.15, 0.15, 0.15)
                cr:arc( xc, yc, r, as+ass, at-ast )
                cr:stroke()
            end
        elseif (as > at and (as-at)<=math.pi) then
            if (as-ass) > (at+ast) then
                local xe, ye = xc + math.cos(at+ast)*r, yc + math.sin(at-ast)*r
                arrow(cr, xe, ye, v.xt, v.yt, v.rt, {0.15, 0.15, 0.15})
                cr:set_source_rgb(0.15, 0.15, 0.15)
                cr:arc( xc, yc, r, at+ast, as-ass )
                cr:stroke()
            end
        elseif as <= at then
            if (as-ass) < (at+ast) then
                local xe, ye = xc + math.cos(at+ast)*r, yc + math.sin(at-ast)*r
                arrow(cr, xe, ye, v.xt, v.yt, v.rt, {0.15, 0.15, 0.15})
                cr:set_source_rgb(0.15, 0.15, 0.15)
                cr:arc( xc, yc, r, at+ast, as-ass )
                cr:stroke()
            end
        elseif as > at then
            if (as+ass) > (at-ast) then
                local xe, ye = xc + math.cos(at-ast)*r, yc + math.sin(at-ast)*r
                arrow(cr, xe, ye, v.xt, v.yt, v.rt, {0.15, 0.15, 0.15})
                cr:set_source_rgb(0.15, 0.15, 0.15)
                cr:arc( xc, yc, r, as+ass, at-ast )
                cr:stroke()
            end
        end

        --write even's name
        cr:select_font_face("sans", cairo.FONT_SLANT_OBLIQUE)
        cr:set_font_size(14)
        local txt_ext = cairo.TextExtents.create( )
        cr:text_extents( table.concat(v,",") or "", txt_ext )
        local x_bearing, y_bearing, txt_width, txt_height, x_advance, y_advance = txt_ext:get()
        txt_ext:destroy()
        local ttx, tty = xp + xv3*(h+10) -(txt_width/2), yp + yv3*(h+10) + (txt_height/2)
        cr:move_to( ttx, tty )
        --~ cr:rotate()
        cr:show_text( table.concat(v,",") or "" )
        cr:stroke()
    end

    for c,v in pairs(transitions_self) do
        cr:set_source_rgb(0.15, 0.15, 0.15)
        cr:arc( v.x, v.y - v.r, v.r, 10*math.pi/12, math.pi/6 )
        cr:stroke()
        local xle, yle = v.x - math.cos(10*math.pi/12)*v.r, v.y - math.sin(10*math.pi/12)*v.r
        arrow(cr, xle, yle, xle, yle+v.r, v.r, {0.15, 0.15, 0.15})

        cr:select_font_face("sans", cairo.FONT_SLANT_OBLIQUE)
        cr:set_font_size(14)
        local txt_ext = cairo.TextExtents.create( )
        cr:text_extents( table.concat(v,",") or "", txt_ext )
        local x_bearing, y_bearing, txt_width, txt_height, x_advance, y_advance = txt_ext:get()
        txt_ext:destroy()
        local ttx, tty = v.x -(txt_width/2), v.y - 2*v.r -(txt_height/2)
        cr:move_to( ttx, tty )
        cr:show_text( table.concat(v,",") or "" )
        cr:stroke()
    end

    self.drawing_area:set_size_request( size.x+100, size.y+100 )
    cr:destroy()
end

function AutomatonRender:convert_point(x,y)

end

function AutomatonRender:select_element(x,y)
    for id, state in self.automaton.states:ipairs() do
        local r = state.r or 20
        if ( (x-state.x)^2 + (y-state.y)^2 ) <= (r^2) then
            return { object = state, id = id, type = 'state' }
        end
    end

    return false
end


