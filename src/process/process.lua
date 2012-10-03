function ProcessAst( ast_node, replace_node )  
    CleanConstants( ast_node )
    
    if replace_node then
        ReplaceFunctions( ast_node, replace_node )
    end
end

function ReplaceFunctions( ast_node, replace_node )
    for ast_function_node, ast_function_index in NodeOfType( ast_node, "function", false ) do
        local
            id,
            type
        local
            arguments = {}
        
        id = GetDataByName( ast_function_node, "ID" )
        type = GetDataByName( ast_function_node, "type" )
        
        for ast_function_argument_node in NodeOfType( ast_function_node, "argument", true ) do
            table.insert( arguments, GetDataByName( ast_function_argument_node, "type" ) )
            -- just add more info here like the const or uniform
        end
        
        for replace_function_node in NodeOfType( replace_node, "function", false ) do
            local
                is_valid = true
                                              
            if id == GetDataByName( replace_function_node, "ID" ) and type == GetDataByName( replace_function_node, "type" ) then
                local    
                    replace_arguments = {} 
                local                                                                                                                                                              
                    valid_arguments = true                                    
                    
                for replace_function_argument_node in NodeOfType( replace_function_node, "argument", true ) do
                    table.insert( replace_arguments, GetDataByName( replace_function_argument_node, "type" ) )
                    -- just add more info here like the const or uniform
                end
                
                if #replace_arguments == #arguments then
                    for index = 1, #arguments, 1 do        
                        if replace_arguments[ index ] ~= arguments[ index ] then
                                 is_valid = false
                            break;
                        end
                    end
                else
                    is_valid = false
                end
            else
                is_valid = false
            end
            
            if is_valid then
                ast_node[ ast_function_index ] = replace_function_node
                break;
            end
        end
    end
end

function CleanConstants( ast_node ) 
    for variable_declaration_node, variable_declaration_node_index in InverseNodeOfType( ast_node, "variable_declaration", false ) do
        local
            declaration_is_empty = true;
            
        for variable_node, variable_index in InverseNodeOfType( variable_declaration_node, "variable", false ) do
            local
                variable_is_valid;
                
            variable_is_valid = false;
            
            for function_node in NodeOfType( ast_node, "function", false ) do
                if FindRedeclaredVariableInFunction( function_node, variable_node ) == false then
                    if BruteForceFindValue( function_node, variable_node[ 1 ] ) then
                        variable_is_valid = true;
                        break;
                    end
                end
            end
            
            if variable_is_valid then
                declaration_is_empty = false;
            else
                table.remove( variable_declaration_node, variable_index );
            end
        end
        
        if declaration_is_empty then
            table.remove( ast_node, variable_declaration_node_index );
        end
    end
end

function FindRedeclaredVariableInFunction( function_node, variable_node )
    local
        function_body_node;
        
    for function_argument_node in NodeOfType( function_node, "argument", true ) do
        if GetDataByName( function_argument_node, "ID" ) == variable_node[ 1 ] then
            return true;
        end
    end
    
    for function_body_node in NodeOfType( function_node, "function_body", false ) do
        -- get every variable_declaration RECURSIVE inside the function body 
        for function_variable_declaration_node in NodeOfType( function_body_node, "variable_declaration", true ) do
            for function_variable_node in NodeOfType( function_variable_declaration_node, "variable", false ) do
                if function_variable_node[ 1 ] == variable_node[ 1 ] then
                    return true;
                end
            end
        end 
    end
    return false;
end