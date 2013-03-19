function ParseArgumentTable( arguments )

    local result = {}
    local arg_item = { output_files = {}, constants_replacement = {}, optimize = true, default_precision = "", replacement_files = {}, inline_replacement_functions = false }
    local previous_argument = ""
    
    for i, argument in ipairs( arguments ) do

        if string.sub( argument, 1, 1 ) == '-' then
        
            local arg_option = string.sub( argument, 2 )
            
            if arg_option == 'o' or arg_option == 'c' then
                previous_argument = arg_option
            elseif arg_option == 'f' then
                if arg_item.force_language then
                    error( "You cannot force another language before you give an input file", 1 )
                end
                
                previous_argument = 'f'
            elseif arg_option == 'r' then
                if arg_item.replacement_file then
                    error( "You cannot specify another replacement file before you give an input file", 1 )
                end
                
                previous_argument = 'r'
            elseif arg_option == 'ri' then
                previous_argument = 'ri'
                arg_item.inline_replacement_functions = true
            elseif arg_option == 't' then
                if arg_item.technique then
                    error( "You can specify only one technique for each input file", 1 )
                end
                
                previous_argument = 't'
            elseif arg_option == 'optimization' then
                previous_argument = 'optimization'
            elseif arg_option == 'check' then
                previous_argument = 'check'
            elseif arg_option == 'default_precision' then
                previous_argument = 'default_precision'
            else
                previous_argument = 'UNSUPPORTED_ARGUMENT'
            end
        
        else
        
            if previous_argument == 'o' then
                table.insert( arg_item.output_files, argument )
            elseif previous_argument == 'f' then
                arg_item.force_language = argument
            elseif previous_argument == 'r' then
                table.insert( arg_item.replacement_files, argument )
            elseif previous_argument == 't' then
                arg_item.technique = argument
            elseif arg_item.input_file then
                error( "You can only specify another input file if you give an -o, -f or/and -r option before", 1 )
            elseif previous_argument == 'c' then
                local constants_table = explode( '=', argument )

                arg_item.constants_replacement[ constants_table[ 1 ] ] = constants_table[ 2 ]
            elseif previous_argument == 'optimization' then
                arg_item.optimize = toboolean( argument )
            elseif previous_argument == 'default_precision' then
                arg_item.default_precision = argument
            elseif previous_argument == 'check' then
                arg_item.check_file = argument
            elseif previous_argument ~= "UNSUPPORTED_ARGUMENT" then
                arg_item.input_file = argument
                if #arg_item.output_files == 0 then
                    table.insert( arg_item.output_files, 'console_output' )
                end
                table.insert( result, arg_item )            
                arg_item = {}
            end
            
            previous_argument = ""
            
        end
    end

    return result
    
end

function explode( div, str ) 
    if ( div == '' ) then 
        return false 
    end

    local pos,arr = 0,{}

    for st,sp in function() return string.find( str, div, pos, true) end do
        table.insert( arr,string.sub( str,pos,st-1 ) ) 
        pos = sp + 1 
    end

    table.insert( arr,string.sub( str,pos ) )
    
    return arr
end