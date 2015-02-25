Devices['schneider_distinguisher'] = letk.Class( Devices['base'] ):init_options()

Devices['schneider_distinguisher'].template_file    = 'PLC_distinguisher.XST'
Devices['schneider_distinguisher'].file_extension   = 'xst'
Devices['schneider_distinguisher'].company      = 'Schneider Automation'
Devices['schneider_distinguisher'].product      = 'Unity Pro M V4.1 - 90415E'
Devices['schneider_distinguisher'].datetime         = os.date("%Y-%m-%d-%H:%M:%S")
Devices['schneider_distinguisher'].content      = 'Structured source file'
Devices['schneider_distinguisher'].project      = 'Project' -- encontrar funçao que copie o nome do projeto .nza
Devices['schneider_distinguisher'].rack             = '64576'

Devices['schneider_distinguisher'].models = {
    ['Plant']           = true,
    ['Supervisor']      = true,
    ['Distinguisher']   = true,
    ['Ref. Supervisor'] = true,
}

Devices['schneider_distinguisher'].channel      = {1, 2, 3}
--Devices['schneider_distinguisher'].

Devices['schneider_distinguisher']:set_option('generate_list', {
    caption = "Associar eventos",
    type    = 'choice',
    { {1} , "Não associar"},
    { {2} , "à Entradas/Saídas"},
    { {3} , "à Memórias"},
})


Devices['schneider_distinguisher']:set_option('input_module', {
    caption = "Slot do módulo de entrada",
    type    = 'choice',
    {{1}, "1"},
    {{2}, "2"},
    {{3}, "3"},
})



Devices['schneider_distinguisher']:set_option('output_module', {
    caption = "Slot do módulo de saída",
    type    = 'choice',
    { {1} , "1"},
    { {2} , "2"},
    { {3} , "3"},
})

Devices['schneider_distinguisher']:set_option('mem_address', {
    caption = "Início do endereçamento de memória",
    type    = 'choice',
    { {1} , "%M1"},
    { {100} , "%M100"},
    { {500} , "%M500"},
    { {750} , "%M750"},
    { {1000} , "%M1000"},
})

------------------------------------------------------------------------

--
Devices['m340dist'] = letk.Class( Devices['schneider_distinguisher'] ):init_options()
Devices['m340dist'].display      = true
Devices['m340dist'].name         = 'Schneider - M340 - Distinguisher'
