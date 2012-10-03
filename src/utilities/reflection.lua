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
    return function_node[ 4 ]
end

function Function_GetArgumentList( function_node )
    return function_node[ 3 ]
end

function Function_GetReturnType( function_node )
    return function_node[ 1 ][ 1 ]
end

function Function_GetArguments( function_node )
    local
        input_types = {}
        
    for index, type in ipairs( function_node[ 3 ] ) do --argument_list
        table.insert( input_types, type )
    end
    
    return input_types
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
    return field_node[ 2 ]
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

function ShaderCall_GetType( node )
    return node[ 1 ]
end