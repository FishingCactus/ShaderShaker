function _shader_shaker_main(script_path, output_file, override_language)

    -- if running off the disk (in debug mode), load everything 
    -- listed in _manifest.lua; the list divisions make sure
    -- everything gets initialized in the proper order.
        
    if script_path then
        local scripts  = dofile(script_path .. "/_manifest.lua")
        for _,v in ipairs(scripts) do
            dofile(script_path .. "/" .. v)
        end
    end
    
    SelectPrinter( output_file, override_language )
    
    if output_file ~= nil then
        InitializeOutputFile( output_file )
    else
        InitializeOutputPrint()
    end
end


function _shaker_shaker_load_shader_file( file_name, replace_file_name )
    local
        ast,
        replace_ast;

    ast = GenerateAstFromFileName( file_name );
    
    if replace_file_name then
        replace_ast = GenerateAstFromFileName( replace_file_name );
    end
    
    ProcessAst( ast )
    
    GetSelectedPrinter().ProcessAst( ast )
    
    return 0
end