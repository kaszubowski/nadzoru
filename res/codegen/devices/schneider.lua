Devices['schneider'] = letk.Class( Devices['base'] ):init_options()

Devices['schneider'].template_file  = 'PLC.XST'
Devices['schneider'].file_extension = 'xst'
Devices['schneider'].company        = 'Schneider Automation'
Devices['schneider'].product        = 'Unity Pro M V4.1 - 90415E'
Devices['schneider'].datetime       = os.date("%Y-%m-%d-%H:%M:%S")
Devices['schneider'].content        = 'Structured source file'
Devices['schneider'].project        = 'Project' -- encontrar funçao que copie o nome do projeto .nza
Devices['schneider'].ns             = '' --number suffix
Devices['schneider'].rack           = '64576'

Devices['schneider'].models = {
    ['Supervisor'] = true,
}

Devices['schneider'].channel        = {1, 2, 3}
--Devices['schneider'].

Devices['schneider']:set_option('generate_list', {
    caption = "Associar eventos",
    type    = 'choice',
    { {1} , "Não associar"},
    { {2} , "à Entradas/Saídas"},
    { {3} , "à Memórias"},
})


Devices['schneider']:set_option('input_module', {
    caption = "Slot do módulo de entrada",
    type    = 'choice',
    {{1}, "1"},
    {{2}, "2"},
    {{3}, "3"},
})



Devices['schneider']:set_option('output_module', {
    caption = "Slot do módulo de saída",
    type    = 'choice',
    { {1} , "1"},
    { {2} , "2"},
    { {3} , "3"},
})

Devices['schneider']:set_option('mem_address', {
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
Devices['m340'] = letk.Class( Devices['schneider'] ):init_options()
Devices['m340'].display      = true
Devices['m340'].name         = 'Schneider - M340'
