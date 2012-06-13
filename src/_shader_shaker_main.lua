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
    
    ShaderPrint( filename .. " " .. extension .. "\n" )
    
    if extension == "lua" or extension == "ssl" then
        dofile( filename )
    elseif extension == "fx" then
        converted_ssl = ConvertHLSLToSSL( filename )
        local text_as_function = load( converted_ssl )
        
        if text_as_function == nil then
            return "Fail to load converted code from " .. filename;
        end
    else
        return "Unsupported file extension while trying to load " .. filename
    end
        
    return 0

end