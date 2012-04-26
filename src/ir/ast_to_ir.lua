-- This function transform an abstract syntax tree into an linear intermediate representation

Ir = Ir or {}

Ir.CreateVariable = function( representation, variable_type )
	local variable_name = "temp" .. representation.variable_index
	representation.variable_index = representation.variable_index + 1
	
	print( "Next variable " .. variable_name );
	representation.code[ #(representation.code) + 1 ] = { type = "declaration", variable_type = variable_type, name = variable_name }
	
	return variable_name

end

Ir.HandleOutput = function( node, representation )

	for k,v in pairs( node.__variable ) do
		local variable = Ir.HandleNode( v, representation )
		representation.code[ #(representation.code) + 1 ]  = { type = "assignment", variable = "output." .. k, value = variable }
	end

end

Ir.HandleInput = function( node, representation )
	return "input." .. node.value
end

Ir.HandleSwizzle = function( node, representation )
	local variable_name = Ir.CreateVariable( representation, node.type )
	
	if rawget( node, "value" ) ~= nil then
		representation.variable[ node ] = variable_name
		representation.code[ #(representation.code) + 1 ]  = { type = "swizzle", variable_type = node.type, variable = varname, arguments = node.arguments }
	end
	
	return variable_name
end

Ir.HandleVariable = function( node, representation )
	
	local variable_name = Ir.CreateVariable( representation, node.type )
		
	print( "Variable node : " .. table.tostring( node ) )

	representation.variable[ node ] = variable_name
	
	local value = rawget( node, "value" )
	
	if type( value ) == "number" then
		representation.code[ #(representation.code) + 1 ]  = { type = "assignment", variable_type = node.type, variable = varname, value = value }
	elseif type( value ) == "string" then
		print( "Text " .. value )
	else
		local variable_name = Ir.HandleNode( value )
		representation.code[ #(representation.code) + 1 ]  = { type = "assignment", variable_type = node.type, variable = varname, value = variable_name }
	end
	
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
	representation.code[ #(representation.code) + 1 ] = { type = "call_function", name = node.name, arguments = variable_name_table, variable = output_variable_name }

	return output_variable_name
end

Ir.HandleOperation = function( node, representation )
	local variable_name_table = {}
	for i,v in ipairs( node.arguments ) do
		variable_name_table[i] = Ir.HandleNode( v, representation )
	end
	local output_variable_name = Ir.CreateVariable( representation, node.type )
	representation.code[ #(representation.code) + 1 ] = { type = "operation", operation = node.operation, arguments = variable_name_table, variable = output_variable_name }

	return output_variable_name
end

Ir.HandleNode = function( ast_node, representation )

	if type( ast_node ) == "number" then
		local varname = Ir.CreateVariable( representation, "float" )
		representation.code[ #(representation.code) + 1 ]  = { type = "assignment", variable_type = "float", variable = varname, value = ast_node }
	
		return
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