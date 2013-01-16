local
    files_to_process = {}
    
function _shader_shaker_main( script_path, argument_table )

    -- if running off the disk (in debug mode), load everything 
    -- listed in _manifest.lua; the list divisions make sure
    -- everything gets initialized in the proper order.
        
    if script_path then
        local scripts  = dofile(script_path .. "/_manifest.lua")
        for _,v in ipairs(scripts) do
            dofile( script_path .. "/" .. v )
        end
    end
    
    files_to_process = ParseArgumentTable( argument_table )
end


function _shaker_shaker_process_files()

    for i, options in ipairs( files_to_process ) do
    
        local
            ast,
            replace_ast

        ast = GenerateAstFromFileName( options.input_file )
        
        ProcessAst( ast, options )

        if options.check_file then 

            SelectPrinter( options.check_file );
            InitializeOutputPrint()

            GetSelectedPrinter().ProcessAst( ast )

            local generated_file = tokenizer( _G.CodeOutput[ 1 ].text );

            local file = assert(io.open(options.check_file, "r"))
            local ground_truth = tokenizer( file:read("*all") )
            file:close()

            repeat
                token_a, value_a = generated_file()
                token_b, value_b = ground_truth()

                if token_a ~= token_b or value_a ~= value_b then
                    error( "expected " .. value_b .. ", got " .. value_a )
                    return 1
                end

            until token_a == nil and token_b == nil

            return 0

        else

            for i, output_file in ipairs( options.output_files ) do
                local ast_copy = DeepCopy( ast )
            
                SelectPrinter( output_file, options.force_language )
            
                if output_file ~= "console_output" then
                    InitializeOutputFile( output_file )
                else
                    InitializeOutputPrint()
                end         
                
                GetSelectedPrinter().ProcessAst( ast_copy, options )
                
            end
        end

        if _G.CodeOutput and #_G.CodeOutput then
            for _, code in ipairs( _G.CodeOutput ) do
                print( code.text )
            end

        end
    
    end
    
    return 0
end