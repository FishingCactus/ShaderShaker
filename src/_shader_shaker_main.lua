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


function _shaker_shaker_load_shader_file( filename )

    local extension = string.match( filename, "%w+%.(%w+)" )
    
    if extension == "lua" or extension == "ssl" then
        ast = dofile( filename )
    elseif extension == "fx" then
        local ast = ParseHLSL( filename )
        
        if ast == nil then
            return "Fail to load hlsl code from " .. filename;
        end
        
        -- TODO Process ast
    else
        return "Unsupported file extension while trying to load " .. filename
    end
    
    
        
    return 0

end