AutomatonRender = letk.Class( function( self, automaton )
    self.automaton = automaton
    self.color_states      = {}
    self.color_transitions = {}
    self.last_size         = {}

    self.scrolled          = gtk.ScrolledWindow.new()
        self.drawing_area  = gtk.DrawingArea.new( )

    self.scrolled:add_with_viewport(self.drawing_area)

    self.drawing_area:connect('draw', self.drawing_area_expose, self )

    return self, self.scrolled, self.drawing_area
end, Object )

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
    return math.pi * ((a%360)/180)
end

local function todeg( r )
    return 180*(r%(2*math.pi))/math.pi
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

local function arc_calc( xs, ys, rs, xt, yt, rt, factor )
    local result
    factor       = factor or 2

    if not xt or not yt or not rt or not factor then
        result = {
            xe = xs - math.cos(5*math.pi/6)*rs,
            ye = ys - math.sin(5*math.pi/6)*rs,
            xc = xs,
            yc = ys - rs,
            as = 5*math.pi/6,
            ae = math.pi/6,
            ar = rs,
        }
    else
        local xp,yp     = (xs - xt)/2 + xt, (ys - yt)/2 + yt --P
        local xv1, yv1  = xp-xs, yp-ys                       -- V1
        local xv2, yv2  = -yv1 * factor, xv1 * factor      -- V2
        local xc, yc    = xv2 + xp, yv2 + yp
        local r         = math.sqrt(  (xs-xc)^2 + (ys-yc)^2  )
        local h         = r - math.sqrt( (xp-xc)^2 + (yp-yc)^2 )
        local s         = math.sqrt( (xp-xs)^2 + (yp-ys)^2 )
        local xv3, yv3  = yv1/s, -xv1/s                      --V3 (-V2 no factor)

        local as_, qs   = math.acos((xs - xc)/r),(ys - yc)/r
        local as        = qs >= 0 and as_ or (2*math.pi) - as_
        local at_, qt   = math.acos((xt - xc)/r),(yt - yc)/r
        local at        = qt >= 0 and at_ or (2*math.pi) - at_

        --formula da corda c = 2*r*sin(ang/2)
        local ass, ast = math.asin( rs/(2*r) )*2, math.asin( rt/(2*r) )*2

        if (as <= at and (at-as)<=math.pi) then
            if (as+ass) < (at-ast) then
                result = {
                    xe = xc + math.cos(at-ast)*r,
                    ye = yc + math.sin(at-ast)*r,
                    xc = xc,
                    yc = yc,
                    as = as+ass,
                    ae = at-ast,
                    ar = r,
                    xp = xp,
                    yp = yp,
                    xv3 = xv3,
                    yv3 = yv3,
                    h   = h,
                }
            end
        elseif (as > at and (as-at)<=math.pi) then
            if (as-ass) > (at+ast) then
                result = {
                    xe = xc + math.cos(at+ast)*r,
                    ye = yc + math.sin(at-ast)*r,
                    xc = xc,
                    yc = yc,
                    as = at+ast,
                    ae = as-ass,
                    ar = r,
                    xp = xp,
                    yp = yp,
                    xv3 = xv3,
                    yv3 = yv3,
                    h   = h,
                }
            end
        elseif as <= at then
            if (as-ass) < (at+ast) then
                result = {
                    xe = xc + math.cos(at+ast)*r,
                    ye = yc + math.sin(at-ast)*r,
                    xc = xc,
                    yc = yc,
                    as = at+ast,
                    ae = as-ass,
                    ar = r,
                    xp = xp,
                    yp = yp,
                    xv3 = xv3,
                    yv3 = yv3,
                    h   = h,
                }
            end
        elseif as > at then
            if (as+ass) > (at-ast) then
                result = {
                    xe = xc + math.cos(at-ast)*r,
                    ye = yc + math.sin(at-ast)*r,
                    xc = xc,
                    yc = yc,
                    as = as+ass,
                    ae = at-ast ,
                    ar = r,
                    xp = xp,
                    yp = yp,
                    xv3 = xv3,
                    yv3 = yv3,
                    h   = h,
                }
            end
        end
    end
    return result
end

local function write_text(cr,x,y,text,font,color)
    color = color or { 0,0,0 }
    cr:select_font_face("sans", cairo.FONT_SLANT_OBLIQUE)
    cr:set_font_size(font)
    local txt_ext = cairo.TextExtents.create( )
    cr:text_extents( text or "", txt_ext )
    local x_bearing, y_bearing, txt_width, txt_height, x_advance, y_advance = txt_ext:get()
    txt_ext:destroy()
    cr:move_to( x -(txt_width/2), y + (txt_height/2) )
    --~ cr:rotate()
    cr:set_source_rgb(color[1], color[2], color[3])
    cr:show_text( text or "" )
    cr:stroke()
    return (txt_width/2), (txt_height/2), x -(txt_width/2), y + (txt_height/2)
end

function AutomatonRender:draw( color_states, color_transitions)
    self.color_states      = color_states or self.color_states
    self.color_transitions = color_transitions or self.color_transitions
    self.drawing_area:queue_draw()
end

function AutomatonRender:drawing_area_expose( cr )
    cr = cairo.Context.wrap(cr)
    local size = self:draw_context( cr )
    self.drawing_area:set_size_request( size.x+128, size.y+128 )
    cr:destroy()
    self.last_size = size
end

function AutomatonRender:draw_context( cr )
    local size               = {x=0,y=0}
    local states_position    = {}
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
        local r = write_text(cr,x,y,state.name or tostring(id),20) + 15
        state.r = r

        states_position[#states_position +1] = {x=x,y=y,r=r}
        size.x = math.max(x+r,size.x)
        size.y = math.max(y+r,size.y)
        states_position[state]               = #states_position --state is a <table>

        cr:set_line_width(2)
        if self.color_states and self.color_states[id] then
            local color = self.color_states[id]
            cr:set_source_rgb(color[1], color[2], color[3])
        else
            cr:set_source_rgb(0, 0, 0)
        end
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
            local index                = source_id .. '_' .. target_id
            transitions_self[index] = transitions_self[index] or {
                x = states_position[source_id].x,
                y = states_position[source_id].y,
                r = states_position[source_id].r
            }
            table.insert( transitions_self[index], trans.event.name )
        end
    end

    for c,v in pairs( transitions_out ) do
        local result = arc_calc( v.xs, v.ys, v.rs, v.xt, v.yt, v.rt, v.factor )
        if result then
            if self.color_transitions and self.color_transitions[c] then
                local color = self.color_transitions[c]
                cr:set_source_rgb(color[1], color[2], color[3])
                cr:arc( result.xc, result.yc, result.ar, result.as, result.ae )
                cr:stroke()
                arrow(cr, result.xe, result.ye, v.xt, v.yt, v.rt, {color[1], color[2], color[3]})
            else
                cr:set_source_rgb(0, 0, 0)
                cr:arc( result.xc, result.yc, result.ar, result.as, result.ae )
                cr:stroke()
                arrow(cr, result.xe, result.ye, v.xt, v.yt, v.rt, {0, 0, 0})
            end
            --write even's name
            write_text(cr, result.xp + result.xv3*(result.h+10), result.yp + result.yv3*(result.h+10), table.concat(v,","), 14)
        end
    end

    for c,v in pairs(transitions_self) do
        local result = arc_calc( v.x, v.y, v.r, nil, nil, nil, nil )

        if result then
            if self.color_transitions and self.color_transitions[c] then
                local color = self.color_transitions[c]
                cr:set_source_rgb(color[1], color[2], color[3])
                cr:arc( result.xc, result.yc, result.ar, result.as, result.ae )
                cr:stroke()
                arrow(cr, result.xe, result.ye, result.xe, result.ye + v.r, v.r, {color[1], color[2], color[3]})
            else
                cr:set_source_rgb(0, 0, 0)
                cr:arc( result.xc, result.yc, result.ar, result.as, result.ae )
                cr:stroke()
                arrow(cr, result.xe, result.ye, result.xe, result.ye + v.r, v.r, {0, 0, 0})
            end

            --write even's name
            write_text(cr, v.x, v.y - 2*v.r - 8, table.concat(v,","), 14)
        end
    end

    return size
end

local function two_point_angle(x1,y1,x2,y2)
    local hip    = math.sqrt( (x1-x2)^2 + (y1-y2)^2 )
    local xn, yn = (x2 - x1)/hip, (y2 - y1)/hip
    local _x = math.acos( xn )
    if yn >= 0 then
        return _x, hip
    else
        return 2*math.pi - _x, hip
    end
end

function AutomatonRender:select_element(x,y)
    local state_index = {}
    for id, state in self.automaton.states:ipairs() do
        state_index[ state ] = id
        local r = state.r or 20
        if ( (x-state.x)^2 + (y-state.y)^2 ) <= (r^2) then
            return { object = state, id = id, type = 'state' }
        end
    end

    local tran_select = {}

    for id, transitions in self.automaton.transitions:ipairs() do
        local s, t, e = transitions.source, transitions.target, transitions.event
        if not tran_select.type then
            local r
            if s ~= t then
                r = arc_calc( s.x, s.y, s.r or 10, t.x, t.y, t.r or 10, 2 )
            else
                r = arc_calc( s.x, s.y, s.r or 10 )
            end
            if r then
                local a, hip = two_point_angle( r.xc, r.yc, x, y)
                if r.ae < r.as then
                     if ( (a >= r.as and a <= 2*math.pi) or a <= r.ae ) and hip <= r.ar + 3 and hip >= r.ar - 3 then
                        tran_select.type   = 'transition'
                        tran_select.source = state_index[s]
                        tran_select.target = state_index[t]
                        tran_select.index  = state_index[s] .. '_' .. state_index[t]
                        tran_select[#tran_select +1] = {
                            object = transitions,
                        }
                        tran_select.source_obj = s
                        tran_select.target_obj = t
                    end
                else
                    if a >= r.as and a <= r.ae and hip <= r.ar + 3 and hip >= r.ar - 3 then
                        tran_select.type   = 'transition'
                        tran_select.source = state_index[s]
                        tran_select.target = state_index[t]
                        tran_select.index  = state_index[s] .. '_' .. state_index[t]
                        tran_select[#tran_select +1] = {
                            object = transitions,
                        }
                        tran_select.source_obj = s
                        tran_select.target_obj = t
                    end
                end
            end
        else
            if state_index[s] ==  tran_select.source and state_index[t] == tran_select.target then
                tran_select[#tran_select +1] = {
                        object = transitions,
                    }
            end
        end
    end
    if tran_select.type then
        return tran_select
    end

    return false
end


