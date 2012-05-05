ScadaComponent.Conveyor2 = letk.Class( function( self )
    ScadaComponent.Base.__super( self )
end, ScadaComponent.Base )

ScadaComponent.Conveyor2:init_properties{
    ['track']           = { type = 'string'  , caption = "Track"          , default = 'sslssrrsssrsssrr', private = false },
    ['tile_len']        = { type = 'integer' , caption = "Tile Length"    , default = 64        , private = false, min = 24, max = 512 },
    ['conveyor_width']  = { type = 'integer' , caption = "Conveyor Width" , default = 32        , private = false, min = 16, max = 512 },
    ['orientation']     = { type = 'combobox', caption = "Orientation"    , default = 1         , private = false, values = {"East", "South", "West", "North"} },
    ['color']           = { type = 'color'   , caption = "Color"          , default = '#8CC'    , private = false, },
    ['movement']        = { type = 'integer' , caption = "Movement"       , default = 0         , private = false, min = 0, max = 3},
    ['state']           = { type = 'integer' , caption = "State"          , default = 0         , private = false, min = 0, max = 1},
    ['itens']           = { type = 'integer' , caption = "Itens"          , default = 0         , private = false, min = 0 },
    ['h']               = false,
    ['w']               = false,
}
ScadaComponent.Conveyor2.final_component = true
ScadaComponent.Conveyor2.caption         = "Conveyor"
ScadaComponent.Conveyor2.icon            = 'res/scada/images/conveyor2.png'

local function get_properties_table( self )
    local color  = self:translate_color( self:get_property( 'color' ) )
    
    local t = {
        px       = self:get_property( 'x' ),
        py       = self:get_property( 'y' ),
        tl       = self:get_property( 'tile_len' ),
        cw       = self:get_property( 'conveyor_width' ),
        o        = self:get_property( 'orientation' ),
        t        = self:get_property( 'track' ),
        color    = color,
        movement = self:get_property( 'movement' ),
        itens    = self:get_property( 'itens' ),
    }
    t.max_x = t.px
    t.max_y = t.py
    
    
    return t
end

local function update_properties_table( prop, cmd )
    if cmd == 's' then
        if     prop.o == 1 then prop.px = prop.px + prop.tl     -- East
        elseif prop.o == 2 then prop.py = prop.py + prop.tl     -- South
        elseif prop.o == 3 then prop.px = prop.px - prop.tl     -- West
        elseif prop.o == 4 then prop.py = prop.py - prop.tl end -- North
    elseif cmd == 'r' then
        if     prop.o == 1 then prop.o  = 2; prop.py = prop.py + prop.tl     -- East
        elseif prop.o == 2 then prop.o  = 3; prop.px = prop.px - prop.tl     -- South
        elseif prop.o == 3 then prop.o  = 4; prop.py = prop.py - prop.tl     -- West
        elseif prop.o == 4 then prop.o  = 1; prop.px = prop.px + prop.tl end -- North
    elseif cmd == 'l' then                          
        if     prop.o == 1 then prop.o  = 4; prop.py = prop.py - prop.tl     -- East
        elseif prop.o == 2 then prop.o  = 1; prop.px = prop.px + prop.tl     -- South
        elseif prop.o == 3 then prop.o  = 2; prop.py = prop.py + prop.tl     -- West
        elseif prop.o == 4 then prop.o  = 3; prop.px = prop.px - prop.tl end -- North
    end
    if prop.max_x < prop.px then
        prop.max_x = prop.px
    end
    if prop.max_y < prop.py then
        prop.max_y = prop.py
    end
end

local function draw_straight( cr, prop, cmd )
    local cw   = math.min( prop.cw, prop.tl - 4 )
    local diff = (prop.tl - cw)/2
    
    cr:set_source_rgba( prop.color[1], prop.color[2], prop.color[3], 1 )
    if prop.o == 1 or prop.o == 3 then
        cr:rectangle( prop.px, prop.py + diff, prop.tl, cw)
    else
        cr:rectangle( prop.px  + diff, prop.py, cw, prop.tl)
    end
    cr:fill()
    
    cr:set_source_rgba( 0, 0, 0, 1 )
    if prop.o == 1 or prop.o == 3 then
        cr:move_to( prop.px, prop.py + diff )
        cr:line_to( prop.px + prop.tl, prop.py + diff )
        cr:move_to( prop.px, prop.py + diff + cw )
        cr:line_to( prop.px + prop.tl, prop.py + diff + cw )
    else
        cr:move_to( prop.px + diff, prop.py )
        cr:line_to( prop.px + diff, prop.py + prop.tl )
        cr:move_to( prop.px + diff + cw, prop.py )
        cr:line_to( prop.px + diff + cw, prop.py + prop.tl )
    end
    cr:stroke()
    
    
    --ARROW
    local function draw_arrow( x, y, o, f )
        cr:move_to( x, y )
        if o == 1 then
            cr:line_to( x - f, y - f)
            cr:move_to( x, y )
            cr:line_to( x - f, y + f)
        elseif o == 2 then
            cr:line_to( x - f, y - f)
            cr:move_to( x, y )
            cr:line_to( x + f, y - f)
        elseif o == 3 then
            cr:line_to( x + f, y - f)
            cr:move_to( x, y )
            cr:line_to( x + f, y + f)
        elseif o == 4 then
            cr:line_to( x - f, y + f)
            cr:move_to( x, y )
            cr:line_to( x + f, y + f)
        end
        cr:stroke()
    end
    
    cr:set_source_rgba( 0, 0, 0, 0.25 )
    
    local f   = cw/3
    local mid = prop.tl/2
    for i = 0,1 do
        local inc = (prop.tl/2)*i + (prop.tl/11)*prop.movement
        if prop.o == 1 then
            draw_arrow( prop.px + f + inc, prop.py + mid,  prop.o, f)
        elseif prop.o == 3 then
            draw_arrow( prop.px + prop.tl - f - inc, prop.py  +mid,  prop.o, f)
        elseif prop.o == 2 then
            draw_arrow( prop.px+mid, prop.py + f + inc,  prop.o, f)
        elseif prop.o == 4 then
            draw_arrow( prop.px + mid, prop.py + prop.tl - f - inc,  prop.o, f)
        end
    end
    
    --Item
    if prop.itens > 0 then
        prop.itens = prop.itens - 1
        cr:set_source_rgba( 0.5, 0.5, 0.5, 1 )
        cr:rectangle( prop.px  + diff + 4, prop.py + diff + 4, cw - 8, cw - 8)
        cr:fill()
    end
    
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

local function draw_curve( cr, prop, cmd )
    local cw   = math.min( prop.cw, prop.tl - 4 )
    local r1 = (prop.tl - cw)/2
    local r2 = r1+cw
    local acx,acy      = prop.px, prop.py 
    local ang_s, ang_e
    if (prop.o == 1 and cmd == 'l') or (prop.o == 2 and cmd == 'r') then -- El/Sr
        ang_s, ang_e = 0, math.pi/2
    elseif (prop.o == 3 and cmd == 'r') or (prop.o == 2 and cmd == 'l') then --Wr/Sl
        acx = acx + prop.tl
        ang_s, ang_e = math.pi/2, math.pi
    elseif (prop.o == 3 and cmd == 'l') or (prop.o == 4 and cmd == 'r') then --Wl/Nr
        acy = acy + prop.tl
        acx = acx + prop.tl
        ang_s, ang_e = math.pi, 3*math.pi/2
    elseif (prop.o == 1 and cmd == 'r') or (prop.o == 4 and cmd == 'l') then --Er/Nl
        acy = acy + prop.tl
        ang_s, ang_e = 3*math.pi/2, 2*math.pi
    end
    cr:set_source_rgba(  prop.color[1], prop.color[2], prop.color[3], 1 )
    if (prop.o == 1 and cmd == 'l') or (prop.o == 2 and cmd == 'r') then -- El/Sr
        cr:move_to( acx+r2, acy ); cr:line_to( acx+r1, acy )
    elseif (prop.o == 3 and cmd == 'r') or (prop.o == 2 and cmd == 'l') then --Wr/Sl
        cr:move_to( acx, acy+r2 ); cr:line_to( acx, acy+r1 )
    elseif (prop.o == 3 and cmd == 'l') or (prop.o == 4 and cmd == 'r') then --Wl/Nr
        cr:move_to( acx-r2, acy ); cr:line_to( acx-r1, acy )
    elseif (prop.o == 1 and cmd == 'r') or (prop.o == 4 and cmd == 'l') then --Er/Nl
        cr:move_to( acx, acy-r2 ); cr:line_to( acx, acy-r1 )
    end
    cr:arc(acx,acy,r1,ang_s,ang_e)
    if (prop.o == 1 and cmd == 'l') or (prop.o == 2 and cmd == 'r') then -- El/Sr
        cr:line_to( acx, acy+r2 )
    elseif (prop.o == 3 and cmd == 'r') or (prop.o == 2 and cmd == 'l') then --Wr/Sl
        cr:line_to( acx-r2, acy )
    elseif (prop.o == 3 and cmd == 'l') or (prop.o == 4 and cmd == 'r') then --Wl/Nr
        cr:line_to( acx, acy-r2 )
    elseif (prop.o == 1 and cmd == 'r') or (prop.o == 4 and cmd == 'l') then --Er/Nl
        cr:line_to( acx+r2, acy )
    end   
    cr:arc(acx,acy,r2,ang_s,ang_e)
    cr:fill()
    cr:set_source_rgba( 0, 0, 0, 1 )
    cr:arc(acx,acy,r1,ang_s,ang_e)
    cr:stroke()
    cr:arc(acx,acy,r2,ang_s,ang_e)
    cr:stroke()
    
    --ARROW
    cr:set_source_rgba( 0, 0, 0, 0.25 )
    local r3       = r1+cw/2
    local f        = cw/2 --2.1 == 3*-0.7 where 0.7 is sin/cos of 45º
    
    local ang
    if cmd == 'l' then
        ang = (0.35  - prop.movement*0.115)*math.pi
    else
        ang = (0.15  + prop.movement*0.115)*math.pi
    end
    if (prop.o == 1 and cmd == 'l') or (prop.o == 2 and cmd == 'r') then -- El/Sr
        ang = ang
    elseif (prop.o == 3 and cmd == 'r') or (prop.o == 2 and cmd == 'l') then --Wr/Sl
        ang = ang + (0.5)*math.pi
    elseif (prop.o == 3 and cmd == 'l') or (prop.o == 4 and cmd == 'r') then --Wl/Nr
        ang = ang + (1)*math.pi
    elseif (prop.o == 1 and cmd == 'r') or (prop.o == 4 and cmd == 'l') then --Er/Nl
        ang = ang + (1.5)*math.pi
    end
    local ang_a1, ang_a2
    if cmd == 'r' then
        ang_a1  = ang - math.pi*0.25 -- -45º
        ang_a2  = ang - math.pi*0.75 -- -135º
    else
        ang_a1  = ang + math.pi*0.25 -- +45º
        ang_a2  = ang + math.pi*0.75 -- +135º
    end
    local as_x, as_y    = acx + math.cos( ang )*r3, acy + math.sin( ang )*r3
    local ae1_x, ae1_y  = as_x + math.cos( ang_a1 )*f, as_y + math.sin( ang_a1 )*f
    local ae2_x, ae2_y  = as_x + math.cos( ang_a2 )*f, as_y + math.sin( ang_a2 )*f
    cr:move_to( as_x, as_y ); cr:line_to( ae1_x, ae1_y )
    cr:move_to( as_x, as_y ); cr:line_to( ae2_x, ae2_y )
    cr:stroke()
end

function ScadaComponent.Conveyor2:render( cr )
    local prop = get_properties_table( self )
    
    for i = 1,#prop.t do
        local cmd = prop.t:sub(i,i)
        if cmd == 's' then
            draw_straight( cr, prop )
        elseif cmd == 'r' then
            draw_curve( cr, prop, cmd )
        elseif cmd == 'l' then
            draw_curve( cr, prop, cmd )
        end
        update_properties_table( prop, cmd )
    end
    
    return prop.max_x + prop.tl, prop.max_y + prop.tl
end

function ScadaComponent.Conveyor2:is_selected( x, y )
    local prop = get_properties_table( self )
    for i = 1,#prop.t do
        local cmd = prop.t:sub(i,i)
        local cw   = math.min( prop.cw, prop.tl - 4 )
        local diff = (prop.tl - cw)/2
        if cmd == 's' then
            if prop.o == 1 or prop.o == 3 then
                if  x >= prop.px and y >= (prop.py + diff) and x <= (prop.px + prop.tl) and y<= (prop.py + diff + cw) then
                    return true
                end
            else
                if  x >= prop.px + diff and y >= prop.py and x <= (prop.px + diff + cw) and y<= (prop.py + prop.tl) then
                    return true
                end
            end
        else
            if x >= prop.px and x <= (prop.px + prop.tl) and y >= prop.py and y<= (prop.py + prop.tl) then
                local acx,acy      = prop.px, prop.py -- El/Sr
                if (prop.o == 3 and cmd == 'r') or (prop.o == 2 and cmd == 'l') then --Wr/Sl
                    acx = acx + prop.tl
                elseif (prop.o == 3 and cmd == 'l') or (prop.o == 4 and cmd == 'r') then --Wl/Nr
                    acy = acy + prop.tl
                    acx = acx + prop.tl
                elseif (prop.o == 1 and cmd == 'r') or (prop.o == 4 and cmd == 'l') then --Er/Nl
                    acy = acy + prop.tl
                end
                local r = math.sqrt((x-acx)^2 + (y-acy)^2)
                if r >= diff and r <= diff+cw then
                    return true
                end
            end
        end
        update_properties_table( prop, cmd )
    end
    
    return false
end

function ScadaComponent.Base:tick()
    if self:get_property( 'state' ) == 1 then
        local m = self:get_property( 'movement' )
        m = m + 1
        if m > 3 then
            m = 0
        end
        self:set_property( 'movement', m )
    end
end
