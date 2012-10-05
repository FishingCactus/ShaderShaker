function ParseArgumentTable( arguments )

    local result = {}
    local arg_item = { output_files = {} }
    local previous_argument = ""
    
    for i, argument in ipairs( arguments ) do

        if string.sub( argument, 1, 1 ) == '-' then
        
            local arg_option = string.sub( argument, 2 )
            
            if arg_option == 'o' then
                previous_argument = "o"
            elseif arg_option == 'f' then
                if arg_item.force_language then
                    error( "You cannot force another language before you give an input file", 1 )
                end
                
                previous_argument = "f"
            elseif arg_option == 'r' then
                if arg_item.replacement_file then
                    error( "You cannot specify another replacement file before you give an input file", 1 )
                end
                
                previous_argument = "r"
            elseif arg_option == 't' then
                if arg_item.technique then
                    error( "You can specify only one technique for each input file", 1 )
                end
                
                previous_argument = "t"
                
            else
                error( "Invalid option", 1 );
            end
        
        else
        
            if previous_argument == "o" then
                table.insert( arg_item.output_files, argument )
            elseif previous_argument == "f" then
                arg_item.force_language = argument
            elseif previous_argument == "r" then
                arg_item.replacement_file = argument
            elseif previous_argument == "t" then
                arg_item.technique = argument
            elseif arg_item.input_file then
                error( "You can only specify another input file if you give an -o, -f or/and -r option before", 1 )
            else
                arg_item.input_file = argument
                table.insert( result, arg_item )            
                arg_item = {}
            end
            
            previous_argument = ""
            
        end
    end

    return result
    
end