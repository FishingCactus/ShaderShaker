HLSL = HLSL or {}


HLSL.GetDeclaration = function( declaration )
	return declaration.variable_type .. " " .. declaration.name .. ";\n"
end

HLSL.GetCallFunction = function( call_function )
	local code
	
	code = call_function.variable .. " = " .. call_function.name .. "( "
	
	for i,v in ipairs( call_function.arguments ) do
	
		if i ~= 1 then
			code = code .. ", "
		end
		
		code = code .. v
	end
	
	code = code .. " );\n" 
	
	return code	
end

HLSL.GetSwizzle = function( swizzle )
	
	return swizzle.variable .. " = " .. swizzle.arguments[ 1 ] .. "." .. swizzle.arguments[ 2 ] .. ";\n"

end

HLSL.OperationTable = {
	mul = "*",
	add = "+",
	sub = "-",
	div = "/"
}

HLSL.GetOperation = function( operation )
	
	assert( #( operation.arguments ) == 2 )
	
	return operation.variable .. " = " .. operation.arguments[ 1 ] .. " " .. HLSL.OperationTable[ operation.operation ] .. " " .. operation.arguments[ 2 ] .. ";\n"; 
end

HLSL.GetAssignment = function( assignment )

	if type( assignment.value ) == "table" then
		return assignment.variable .. " = " .. assignment.variable_type .. "(" .. table.concat( assignment.value, "," ) .. ");\n"
	else
		return assignment.variable .. " = " .. assignment.value .. ";\n"
	end
end

HLSL.GenerateStructure = function( prefix, input_definition, function_name )

	ShaderPrint( "struct " .. prefix .. "_" .. function_name .. "\n{\n" )
	
	for name, description in pairs( input_definition ) do
		ShaderPrint( 1, description.type .. " " .. name .. " : " .. description.semantic .. ";\n" )
	end
	
	ShaderPrint( "\n};\n" )
end

HLSL.GenerateConstants = function( constants )

	for constant, value in pairs( constants ) do
		ShaderPrint( value.type .. " " .. constant ..";\n" );
	end
end

HLSL.GetConstructor = function( constructor )

	local code = constructor.variable .. " = " .. constructor.constructor_type .. " ( "
	
	for _, value in ipairs( constructor.arguments ) do
	
		if _ ~= 1 then
			code = code .. ", "
		end
		
		code = code .. value	
	end
	
	code = code .. " );\n" 
	
	return code;
end

HLSL.PrintFunctionPrologue = function( representation, function_name )
	
	HLSL.GenerateConstants( representation.constant )
	HLSL.GenerateStructure( "INPUT", representation.input, function_name )
	HLSL.GenerateStructure( "OUTPUT", representation.output, function_name )
	
	ShaderPrint( "OUTPUT_" .. function_name .. " " .. function_name .. " ( INPUT_" .. function_name .. " input )\n{\n" )
	ShaderPrint( 1, "OUTPUT_" .. function_name .. " output;\n" )

end

HLSL.PrintFunctionEpilogue = function( representation, function_name )
	ShaderPrint( 1, "return output;\n}\n\n" )
end

HLSL.PrintCode = function ( representation )
	for i,v in ipairs( representation.code ) do
	
		if HLSL[ "Get" .. v.type ] == nil then
			error( "No printer for type " .. v.type .. " in HLSL printer", 1 )
		end
		
		ShaderPrint( 1, HLSL[ "Get" .. v.type ]( v ) )
	end
end

HLSL.PrintTechnique = function( technique_name, vertex_shader_name, pixel_shader_name )
	
	ShaderPrint( "technique " .. technique_name .. "\n{" )
	ShaderPrint( 1, "pass P0\n" )
	ShaderPrint( 1, "{\n" )
	ShaderPrint( 2, "VertexShader = compile vs_3_0 " .. vertex_shader_name .. "();\n" )
	ShaderPrint( 2, "PixelShader = compile ps_3_0 " .. pixel_shader_name .. "();\n" )
	ShaderPrint( 1, "}" )
	ShaderPrint( "\n}" )

end