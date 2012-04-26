-- This function transform an abstract syntax tree into an linear intermediate representation

Ir = Ir or {}

Ir.CreateVariable = function( representation, variable_type )
	local variable_name = "temp" .. representation.variable_index
	representation.variable_index = representation.variable_index + 1
	
	representation.code[ #(representation.code) + 1 ] = { type = "Declaration", variable_type = variable_type, name = variable_name }
	
	return variable_name

end

Ir.HandleOutput = function( node, representation )

	for k,v in pairs( node.__variable ) do
		local variable = Ir.HandleNode( v, representation )
		representation.code[ #(representation.code) + 1 ]  = { type = "Assignment", variable = "output." .. k, value = variable }
	end

end

Ir.HandleInput = function( node, representation )
	return "input." .. node.value
end

Ir.HandleSwizzle = function( node, representation )
	local variable_name = Ir.CreateVariable( representation, node.type )
	local source_variable_name = Ir.HandleNode( node.arguments[ 1 ], representation )
	
	representation.variable[ node ] = variable_name
	representation.code[ #(representation.code) + 1 ]  
		= { type = "Swizzle", variable_type = node.type, variable = variable_name, arguments = { source_variable_name, node.arguments[2] } }
	
	return variable_name
end

Ir.HandleVariable = function( node, representation )
	
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

Ir.HandleTexture = function( node, representation )
	return node.name
end

Ir.HandleFunction = function( node, representation )
	local variable_name_table = {}
	for i,v in ipairs( node.arguments ) do
		variable_name_table[i] = Ir.HandleNode( v, representation )
	end
	local output_variable_name = Ir.CreateVariable( representation, node.type )
	representation.code[ #(representation.code) + 1 ] = { type = "CallFunction", name = node.name, arguments = variable_name_table, variable = output_variable_name }

	return output_variable_name
end

Ir.HandleOperation = function( node, representation )
	local variable_name_table = {}
	for i,v in ipairs( node.arguments ) do
		variable_name_table[i] = Ir.HandleNode( v, representation )
	end
	
	local output_variable_name = Ir.CreateVariable( representation, node.type )
	representation.code[ #(representation.code) + 1 ] = { type = "Operation", operation = node.operation, arguments = variable_name_table, variable = output_variable_name }

	return output_variable_name
end

Ir.HandleNode = function( ast_node, representation )

	if type( ast_node ) == "number" then
		local varname = Ir.CreateVariable( representation, "float" )
		representation.code[ #(representation.code) + 1 ]  = { type = "Assignment", variable_type = "float", variable = varname, value = ast_node }
	
		return varname
	end
	
	if ast_node.node == nil then
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

	local representation = { code={}, input={}, output={}, variable={}, variable_index = 0 }

	Ir.HandleNode( ast, representation )
	
	print( "\n\nFinal IR \n\n" .. table.tostring( representation.code ) )
	return representation
end