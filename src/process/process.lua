function ProcessAst( ast_node, options )
    if #options.replacement_files > 0 then
        ProcessFunctionReplacement( ast_node, options.replacement_files, options.inline_replacement_functions, options.optimize )
    end
    
    if options.optimize then
        local constants = GetConstants( ast_node )
        
        InlineShaderParameters( ast_node )
        
        if options.constants_replacement ~= nil then
            UpdateConstantsWithReplacements( constants, options.constants_replacement )        
            ReplaceConstants( ast_node, constants )
        end
        
		AST_Rewrite( ast_node )

        CleanConstants( ast_node )
    end
end

function InlineShaderParameters( ast_node )
    local reimplemented_functions_table = {}
    
    for node_index, node in pairs( ast_node ) do
        if node.name == "technique" then
            local technique_name
            
            for index, technique_child in pairs( node ) do
                if index == 1 then
                    technique_name = technique_child
                elseif technique_child.name == "pass" then
                    for pass_child_node_index, pass_child_node in ipairs( technique_child ) do
                        if pass_child_node.name == "shader_call" then
                            local shader_function_to_call = pass_child_node[ 3 ]
                            local parameters_table = pass_child_node[ 4 ]
                            
                            if parameters_table ~= nil then
                                local function_to_call = DuplicateAndReturnFunction( shader_function_to_call, ast_node )
                                local constants_table = CreateConstantsTableFromParametersTable( parameters_table, function_to_call )
                                local function_name = function_to_call[ 2 ][ 1 ] .. HashArgumentList( parameters_table )
                                
                                if reimplemented_functions_table[ function_name ] == nil then
                                    ReplaceConstants( function_to_call, constants_table )
                                    
                                    function_to_call[ 2 ][ 1 ] = function_name

                                    ReplaceFunctionsCallInsideFunction( ast_node, Function_GetBody( function_to_call ), constants_table )
                                    
                                    reimplemented_functions_table[ function_name ] = function_to_call
                                end
                                
                                RemoveShaderInlinedParameters( function_to_call, parameters_table )
                                
                                pass_child_node[ 3 ] = function_name
                                table.remove( pass_child_node, 4 )
                            end
                        end
                    end
                end
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
                        variable_node.name = "literal"
                    end
                    
                    ReplaceConstants( child_node, constants  )
                end
            end
        else
            ReplaceConstants( child_node, constants  )
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
            local index = 1
            local name = variable_node[ index ]
                        
            constants[ name ] = { type = type }
            
            while variable_node[ index ] ~= nil do
                local node_name = variable_node[ index ].name;
                
                if node_name == "initial_value_table" then
                    local value = variable_node[ index ]
                    constants[ name ].value = value
                    
                    break
                elseif node_name == "literal" then
                    local value = variable_node[ index ]
                    constants[ name ].value = value[ 1 ]
                    
                    break
                end
            
                index = index + 1
            end
            
            local t = ""
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

function CreateConstantsTableFromParametersTable( parameters_value_table, function_to_call )
    local constants_table = {}
    local parameters_table = function_to_call[ 3 ]
    local parameters_starting_index = #parameters_table - #parameters_value_table
    
    for index = 1, #parameters_value_table do
        local ID = GetNodeNameValue( parameters_table[ parameters_starting_index + index ], "ID" )
        
        constants_table[ ID ] = { value = parameters_value_table[ index ][ 1 ], type = parameters_value_table[ index ].name }
    end
    
    return constants_table
end

function CreateConstantsSubTableFromInputConstants( input_constants_table, function_to_call )
    local constants_table = {}
    local parameters_table = function_to_call[ 3 ]
    
    for index, value in ipairs( parameters_table ) do
        local ID = GetNodeNameValue( value, "ID" )
        
        for input_constant_name, input_constant_value in pairs( input_constants_table ) do
            if ID == input_constant_name then
                constants_table[ ID ] = input_constant_value
            end
        end
    end
    
    return constants_table
end

function DuplicateAndReturnFunction( shader_function_to_call, ast_node )
    for node_index, node in pairs( ast_node ) do
        if node.name == "function" and node[ 2 ][ 1 ] == shader_function_to_call then
            local copied_function = DeepCopy( node )
            table.insert( ast_node, node_index + 1, copied_function )
            
            return copied_function
        end
    end
end

function FindFunction( shader_function_to_call, ast_node )
    for node_index, node in pairs( ast_node ) do
        if node.name == "function" and node[ 2 ][ 1 ] == shader_function_to_call then
            return node
        end
    end
end

function RemoveShaderInlinedParameters( function_to_call, parameters_table )
    local function_parameters = function_to_call[ 3 ]
    
    for parameter_to_remove_index = 1, #parameters_table do
        table.remove( function_parameters, #function_parameters - #parameters_table + parameter_to_remove_index )
    end
end

function RemoveFunctionInlinedParameters( function_parameters, parameters_table )
    for parameter_to_remove_name, parameter_to_remove in pairs( parameters_table ) do
        for parameter_index = 1, #function_parameters do
            local ID = ""
            if function_parameters.name == "argument_expression_list" then
                ID = function_parameters[ parameter_index ][ 1 ]                
            else
                ID = GetNodeNameValue( function_parameters[ parameter_index ], "ID" )
            end
            
            if ID == parameter_to_remove_name then
                table.remove( function_parameters, parameter_index  )
                break
            end
        end
    end
end

function ReplaceFunctionsCallInsideFunction( ast_node, body, constants_table )
    local reimplemented_functions_table = {}

    for i, node in pairs( body ) do
        if node.name == "call" and not Function_IsIntrinsic( node[ 1 ] ) then
            local base_function = FindFunction( node[ 1 ], ast_node )
            local function_constants_table = CreateConstantsSubTableFromInputConstants( constants_table, base_function )
            local function_to_replace_name = base_function[ 2 ][ 1 ] .. HashArgumentList( function_constants_table )
            
            if function_to_replace_name ~= base_function[ 2 ][ 1 ] then
                if reimplemented_functions_table[ function_to_replace_name ] == nil then
                    local function_to_replace = DuplicateAndReturnFunction( node[ 1 ], ast_node )
                    
                    ReplaceFunctionsCallInsideFunction( ast_node, function_to_replace, function_constants_table )
                    
                    ReplaceConstants( function_to_replace, constants_table )
                    
                    function_to_replace[ 2 ][ 1 ] = function_to_replace_name
                    
                    reimplemented_functions_table[ function_to_replace_name ] = function_to_replace_name
                    
                    RemoveFunctionInlinedParameters( function_to_replace[ 3 ], function_constants_table )
                end
                
                node[ 1 ] = function_to_replace_name
                
                RemoveFunctionInlinedParameters( node[ 2 ], function_constants_table )
            end
        elseif type( node ) == "table" then
            ReplaceFunctionsCallInsideFunction( ast_node, node, constants_table )
        end
    end
end

function HashArgumentList( arguments )
    concatArguments = function( args )
        local output = ""

        for i, j in pairs( args ) do
            if type( j ) == "table" then
                output = output .. concatArguments( j )
            else
                output = output .. string.sub( j, 1, 1 )
            end
        end

        return output
    end
    
    return concatArguments( arguments )
end