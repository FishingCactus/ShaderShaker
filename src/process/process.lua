function ProcessAst( ast_node, options )
    
    if options.optimization then
        local constants = GetConstants( ast_node )
        
        if options.constants_replacement ~= nil then
            UpdateConstantsWithReplacements( constants, options.constants_replacement )        
            ReplaceConstants( ast_node, constants )
        end
        
        CleanAST( ast_node )

        CleanConstants( ast_node )
    end

    if options.replacement_file then
        replace_ast = GenerateAstFromFileName( options.replacement_file )
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

function ReplaceConstants( ast_node, constants )
    if type( ast_node ) ~= "table" then
        return
    end

    for node_index, child_node in ipairs( ast_node ) do
        if child_node.name == "if" then
            for if_node_index, if_child_node in ipairs( child_node ) do
                if if_child_node.name == "if_block" or if_child_node.name == "else_if_block" then
                    local variable_node = if_child_node[ 1 ]
                    
                    if variable_node.name == "unary_!" then
                        variable_node  = variable_node[ 1 ]
                    end
                    
                    if constants[ variable_node[ 1 ] ] then
                        variable_node[ 1 ] = constants[ variable_node[ 1 ] ].value
                    end
                end
            end
        else
            ReplaceConstants( child_node, constants  )
        end
    end
end

function CleanAST( ast_node )
    CleanIfs( ast_node )
end

function CleanIfs( ast_node )
    if ast_node == nil or type( ast_node ) ~= "table" then
        return
    end
    
    for child_node_index=#ast_node, 1, -1 do
        local child_node = ast_node[ child_node_index ]--for child_node_index, child_node in ipairs( ast_node ) do
        if child_node.name == "if" then
            local if_child_node_index = 1
            
            while child_node[ if_child_node_index ] ~= nil do
                local if_child_node = child_node[ if_child_node_index ]
                local increment_child_node_index = true
                
                if if_child_node.name == "if_block" or if_child_node.name == "else_if_block" then
                    local test_condition = TestCondition( if_child_node )
                    
                    if test_condition ~= nil then
                        if test_condition then
                            local block_node = if_child_node[ 2 ]
                            ast_node[ child_node_index ] = block_node[ 1 ]
                            break
                        else
                            child_node[ if_child_node_index ] = nil
                            increment_child_node_index = false
                            
                            local update_node_index = if_child_node_index + 1
                            
                            while child_node[ update_node_index ] ~= nil do
                                child_node[ update_node_index - 1 ] = child_node[ update_node_index ]
                                update_node_index = update_node_index + 1
                            end
                            
                            child_node[ update_node_index - 1 ] = nil
                        end
                    end
                else -- if_child_node.name == "else_block"
                    if if_child_node_index == 1 then
                        local block_node = if_child_node[ 1 ]
                        ast_node[ child_node_index ] = block_node[ 1 ]
                    end
                end
                
                if increment_child_node_index then
                    if_child_node_index = if_child_node_index + 1
                end
            end
            
            if_child_node_index = 1
            local can_remove_if = true
            
            while child_node[ if_child_node_index ] ~= nil do
                can_remove_if = false
                break
            end
            
            if can_remove_if then
                table.remove( ast_node, child_node_index )
            end            
        else
            CleanIfs( child_node )
        end
    end
end

function TestCondition( condition_node )
    local variable_node = condition_node[ 1 ]
    local inverse_condition = false
    local variable_value = ""
        
    if variable_node.name == "unary_!" then
        variable_node  = variable_node[ 1 ]
        inverse_condition = true
    end
    
    variable_value = variable_node[ 1 ]
    
    if isboolean( variable_value ) then
        if inverse_condition then
            return not toboolean( variable_value )
        else
            return toboolean( variable_value )
        end
    end
    
    return nil
end

function GetConstants( ast_node )
    local constants = {}

    for variable_declaration_node, variable_declaration_node_index in InverseNodeOfType( ast_node, "variable_declaration", false ) do
        local type = Variable_GetType( variable_declaration_node )
        for variable_node, variable_index in InverseNodeOfType( variable_declaration_node, "variable", false ) do
            local name = variable_node[ 1 ]
            local value = variable_node[ 2 ][ 1 ]
            
            constants[ name ] = { value = value, type = type }
        end
    end
    
    return constants
end

function UpdateConstantsWithReplacements( constants, constants_replacement )
    for constant_replacement_name, constant_replacement_value in pairs( constants_replacement ) do
        if not constants[ constant_replacement_name ] then
            error( "The constant replacement " .. constant_replacement_name .. " does not match a constant declaration in the shader", 1 )
        end
        
        constants[ constant_replacement_name ].value = constant_replacement_value
    end
end