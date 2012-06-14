-- This function transform an abstract syntax tree into an linear intermediate representation

Ir = Ir or {}

function Ir.CreateVariable( representation, variable_type )
    local variable_name = "temp" .. representation.variable_index
    representation.variable_index = representation.variable_index + 1
    
    representation.code[ #(representation.code) + 1 ] = { type = "Declaration", variable_type = variable_type, name = variable_name }
    
    return variable_name

end

function Ir.HandleStructure( node, representation )

    for k,v in pairs( node.__variable ) do
        local variable = Ir.HandleNode( v, representation )
        local definition = node.__definition[ k ]
        representation.code[ #(representation.code) + 1 ]  = { type = "Assignment", variable = node.name .. "." .. k, value = variable }
        representation.output[ k ] = { semantic = definition.semantic, type = definition.type }
    end

end

function Ir.HandleInput( node, representation )

    representation.input[ node.value ] = { semantic = node.semantic, type = node.type }
    return "input." .. node.value
end

function Ir.HandleConstructor( node, representation )

    local variable_table = {}
    for i,v in ipairs( node.value ) do
        if type( v ) == "number" then
            variable_table[i] = v
        else
            variable_table[i] = Ir.HandleNode( v, representation )
        end
    end
    local output_variable_name = Ir.CreateVariable( representation, node.type )
    
    representation.code[ #(representation.code) + 1 ] = { type = "Constructor", constructor_type = node.type, arguments = variable_table, variable = output_variable_name }

    return output_variable_name
end

function Ir.HandleConstant( node, representation )
    representation.constant[ node.name ] = { type = node.type }
    return node.name
end

function Ir.HandleSwizzle( node, representation )
    local variable_name = Ir.CreateVariable( representation, node.type )
    local source_variable_name = Ir.HandleNode( node.arguments[ 1 ], representation )
    
    representation.variable[ node ] = variable_name
    representation.code[ #(representation.code) + 1 ]  
        = { type = "Swizzle", variable_type = node.type, variable = variable_name, arguments = { source_variable_name, node.arguments[2] } }
    
    return variable_name
end

function Ir.HandleVariable( node, representation )
    
    local value = rawget( node, "value" )
    local variable_name
    variable_name = Ir.CreateVariable( representation, node.type )
    
    if type( value ) == "number" or value.type == nil then
        representation.code[ #(representation.code) + 1 ]  = { type = "Assignment", variable_type = node.type, variable = variable_name, value = value }
    else
        output_variable_name = Ir.HandleNode( value )
        representation.code[ #(representation.code) + 1 ]  = { type = "Assignment", variable_type = node.type, variable = variable_name, value = output_variable_name }
    end
    
    representation.variable[ node ] = variable_name
    
    return variable_name
end

function Ir.HandleTexture( node, representation )

    representation.texture[ node.name ] = { type = node.type }
    return { type = "Texture", name = node.name }
end

function Ir.HandleFunction( node, representation )
    local variable_name_table = {}
    for i,v in ipairs( node.arguments ) do
        variable_name_table[i] = Ir.HandleNode( v, representation )
    end
    local output_variable_name = Ir.CreateVariable( representation, node.type )
    representation.code[ #(representation.code) + 1 ] = { type = "CallFunction", name = node.name, arguments = variable_name_table, variable = output_variable_name }

    return output_variable_name
end

function Ir.HandleOperation( node, representation )
    local variable_name_table = {}
    for i,v in ipairs( node.arguments ) do
        variable_name_table[i] = Ir.HandleNode( v, representation )
    end
    
    local output_variable_name = Ir.CreateVariable( representation, node.type )
    representation.code[ #(representation.code) + 1 ] = { type = "Operation", operation = node.operation, arguments = variable_name_table, variable = output_variable_name }

    return output_variable_name
end

function Ir.HandleNode( ast_node, representation )

    if type( ast_node ) == "number" then
        local varname = Ir.CreateVariable( representation, "float" )
        representation.code[ #(representation.code) + 1 ]  = { type = "Assignment", variable_type = "float", variable = varname, value = ast_node }
    
        return varname
    end
    
    if ast_node.node == nil then
        print( ast_node )
        print ( "ast_node : " .. table.tostring( ast_node ) )
        error( "No node field found in ast_node", 2 )
    end
    
    local handle_function = Ir["Handle" .. ast_node.node];
    
    if handle_function == nil then
        error( "No handle function found for " .. ast_node.node, 2 )
    end
    
    return handle_function( ast_node, representation )
end

function AstToIR( ast )

    local representation = { code={}, input={}, output={}, constant={}, texture={}, variable={}, variable_index = 0 }

    Ir.HandleNode( ast, representation )
    
    return representation
end