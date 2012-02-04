ScadaComponent.Conveyor2 = letk.Class( function( self )
    ScadaComponent.Base.__super( self )
end, ScadaComponent.Base )

ScadaComponent.Conveyor2:init_properties{
    ['track']           = { type = 'string'  , caption = "Track"          , default = 'sslssrrsssrsssrr', private = false },
    ['tile_len']        = { type = 'integer' , caption = "Tile Length"    , default = 64        , private = false, min = 8, max = 512 },
    ['conveyor_width']  = { type = 'integer' , caption = "Conveyor Width" , default = 32        , private = false, min = 8, max = 512 },
    ['orientation']     = { type = 'combobox', caption = "Orientation"    , default = 1         , private = false, values = {"East", "South", "West", "North"} },
    ['color']           = { type = 'color'   , caption = "Color"          , default = '#8CC'    , private = false, values = {"East", "South", "West", "North"} },
    ['h']               = false,
    ['w']               = false,
}
ScadaComponent.Conveyor2.final_component = true
ScadaComponent.Conveyor2.caption         = "Conveyor"
ScadaComponent.Conveyor2.icon            = 'res/scada/images/conveyor2.png'

local function get_properties_table( self )
    local color  = {0,0,0}
    local scolor = self:get_property( 'color' )
    local cdigits = (#scolor - 1)/3
    for i = 1,3 do
        color[i] = tonumber( '0x' .. scolor:sub(2 + (i-1)*cdigits, 1+i*cdigits) ) / ( 16^cdigits )
    end
    --~ print( color[1], color[2], color[3] )
    
    local t = {
        px       = self:get_property( 'x' ),
        py       = self:get_property( 'y' ),
        tl       = self:get_property( 'tile_len' ),
        cw       = self:get_property( 'conveyor_width' ),
        o        = self:get_property( 'orientation' ),
        t        = self:get_property( 'track' ),
        color    = color
    }
    
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
end

local function draw_straight( cr, prop, cmd )
    local cw   = math.min( prop.cw, prop.tl - 4 )
    local diff = (prop.tl - cw)/2
    
    cr:set_source_rgba( prop.color[1], prop.color[2], prop.color[3], 0.95 )
    if prop.o == 1 or prop.o == 3 then
        cr:rectangle( prop.px, prop.py + diff, prop.tl, cw)
    else
        cr:rectangle( prop.px  + diff, prop.py, cw, prop.tl)
    end
    cr:fill()
    
    cr:set_source_rgba( 0, 0, 0, 0.95 )
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
    cr:set_source_rgba(  prop.color[1], prop.color[2], prop.color[3], 0.95 )
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
    cr:set_source_rgba( 0, 0, 0, 0.95 )
    cr:arc(acx,acy,r1,ang_s,ang_e)
    cr:stroke()
    cr:arc(acx,acy,r2,ang_s,ang_e)
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
