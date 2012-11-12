local intrinsic_functions = {
    "dot", "normalize", "tex2D", "saturate", "reflect", "sin", "cos", "tan", "mul", "length", "exp", "pow", "texCUBE", "fmod"
}

function Function_GetNodeFromId( ast_node, function_id )
    for child_node in NodeOfType( ast_node, 'function' ) do    
        if child_node[ 2 ][ 1 ] == function_id then
            return child_node
        end    
    end
end

function Function_GetName( function_node )
    return function_node[ 2 ][ 1 ]
end

function Function_GetBody( function_node )
    if function_node[ 4 ].name == "function_body" then
        return function_node[ 4 ]
    end
    
    return function_node[ 5 ]
end

function Function_GetArgumentList( function_node )
    for i, child_node in ipairs( function_node ) do
        if child_node.name == "argument_list" then
            return child_node
        end
    end

    return {}    
end

function Function_GetReturnType( function_node )
    return function_node[ 1 ][ 1 ]
end

function Function_GetSemantic( function_node )
    for i, child_node in ipairs( function_node ) do
        if child_node.name == "semantic" then
            return child_node[ 1 ]
        end
    end
    
    return ""
end

function Function_GetArguments( function_node )
    local
        input_types = {}
        
    for i, child_node in ipairs( function_node ) do
        if child_node.name == "argument_list" then
            for j, type in ipairs( child_node ) do --argument_list
                table.insert( input_types, type )
            end
        end
    end
    
    return input_types
end

function Function_GetProperties( function_node )    
    local result = {}
    
    result[ "name" ] = Function_GetName( function_node )
    result[ "return_type" ] = Function_GetReturnType( function_node )
    result[ "arguments" ] = Function_GetArguments( function_node )
    result[ "semantic" ] = Function_GetSemantic( function_node )
    
    return result    
end

function Function_GetCalledFunctions( ast_node, function_name, include_intrinsics )

    local called_functions = {}
    local function_node = Function_GetNodeFromId( ast_node, function_name )

    for node in NodeOfType( function_node, "call", true ) do
        local called_function_name = node[ 1 ]
        local is_intrinsic = false
        local can_add = true
        
        for i, intrinsic in ipairs( intrinsic_functions ) do
            if intrinsic == called_function_name then
                is_intrinsic = true
                break
            end
        end
        
        if is_intrinsic and not include_intrinsic then
            can_add = false
        end
        
        if can_add then
            table.insert( called_functions, 1, called_function_name )
            
            if not is_intrinsic then
                local other_called_functions = Function_GetCalledFunctions( ast_node, called_function_name, include_intrinsics )
                
                for i, f in ipairs( other_called_functions ) do
                
                    local can_add_other = true
                    
                    for j, v in ipairs( called_functions ) do
                        if v == f then
                            can_add_other = false
                            break
                        end
                    end
                    
                    if can_add_other then
                        table.insert( called_functions, 1,  f )
                    end
                end
            end
        end
    
    end
    
    return called_functions

end

function Type_IsAStructure( ast_node, type_name )
    for child_node in NodeOfType( ast_node, 'struct_definition' ) do    
        if Structure_GetName( child_node ) == type_name then
            return true
        end    
    end
    
    return false
end

function Structure_GetMembers( struct_node )
    
    local types = {}

    for index, node in ipairs( struct_node ) do
        if index > 1 then
            table.insert( types, node )
        end
    end
    
    return types
end

function Structure_GetName( struct_node )
    return struct_node[ 1 ]
end

function Field_GetSemantic( field_node )
    return field_node[ 3 ][ 1 ]
end

function Field_GetName( field_node )
    return field_node[ 2 ][ 1 ]
end

function Field_GetType( field_node )
    return field_node[ 1 ][ 1 ]
end

function Argument_GetType( argument_node )
    return argument_node[ 1 ][ 1 ]
end

function Argument_GetName( argument_node )
    return argument_node[ 2 ][ 1 ]
end

function Argument_GetSemantic( argument_node )
    if argument_node[ 3 ] then
        return argument_node[ 3 ][ 1 ]
    end
    
    return ""
end

function Variable_GetStorage( variable_node )
    return variable_node[ 1 ][ 1 ]
end

function Variable_GetModifier( variable_node )
    return variable_node[ 2 ][ 1 ]
end

function Variable_GetType( variable_node )
    return variable_node[ 3 ][ 1 ]
end

function Variable_GetName( variable_node )
    return variable_node[ 4 ][ 1 ]
end

function Technique_GetName( technique_node )
    return technique_node[ 1 ]
end

function ShaderCall_GetName( node )
    return node[ 3 ]
end

function ShaderCall_GetArgumentExpressionList( node )
    return node[ 4 ]
end

function ShaderCall_GetType( node )
    return node[ 1 ]
end

function Texture_GetType( node )
    return node[ 1 ][ 1 ]
end

function Texture_GetName( node )
    return node[ 2 ]
end

function Sampler_GetType( node )
    return node[ 1 ][ 1 ]
end

function Sampler_GetName( node )
    return node[ 2 ]
end

function Sampler_GetTexture( node )
    return node[ 3 ][ 1 ]
end

function Call_GetName( node )
    return node[ 1 ]
end