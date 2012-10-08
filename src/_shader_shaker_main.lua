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
        
        if options.replacement_file then
            replace_ast = GenerateAstFromFileName( options.replacement_file )
        end
        
        ProcessAst( ast, replace_ast )
    
        for i, output_file in ipairs( options.output_files ) do
            local ast_copy = DeepCopy( ast )
        
            SelectPrinter( output_file, options.force_language )
        
            if output_file ~= nil then
                InitializeOutputFile( output_file )
            else
                InitializeOutputPrint()
            end         
            
            GetSelectedPrinter().PreprocessAst( ast_copy )
            GetSelectedPrinter().ProcessAst( ast_copy, options.technique )
            
        end
    
    end
    
    return 0
end