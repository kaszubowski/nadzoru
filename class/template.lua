local template = {}

template.ad_rand = [[
unsigned char ad_rand(){

}
]]

template.pic_rand = [[
unsigned char pic_rand(){
    seed = seed * ( -35 ) + 53;
    return seed;
}
]]

template.rand = function( args )
    args = args or {}
    if args.ad_rand then
        return [[
${ad_rand}

unsigned char rand(){
    return ad_rand();
}
        ]]
    elseif args.pic_rand then
        return [[
${ad_rand}

unsigned char seed = ad_rand();

${pic_rand}

unsigned char rand(){
    return pic_rand();
}
        ]]
    elseif args.pic_rand_seed_ad then
            return [[
unsigned char seed = ad_rand();

${pic_rand}

unsigned char rand(){
    return pic_rand();
}
        ]]
    end
end


template.next_event_rand = [[

]]

template.next_event_local = [[

]]

template.main = [[
${pic_header}
${pic_config}

long long int sup_states[${sup_number}];

${pic_next_event}
${player}

void main(){


}
]]
