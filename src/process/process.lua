function ProcessAst( ast_node )  
    CleanConstants( ast_node ) 
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