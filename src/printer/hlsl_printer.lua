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
	
	return operation.variable .. " = " .. operation.arguments[ 1 ] .. " " .. HLSL.OperationTable[ operation.operation ] .. " " .. operation.arguments[ 2 ]; 
end

HLSL.GetAssignment = function( assignment )

	if type( assignment.value ) == "table" then
		return assignment.variable .. " = " .. assignment.variable_type .. "(" .. table.concat( assignment.value, "," ) .. ");\n"
	else
		return assignment.variable .. " = " .. assignment.value .. ";\n"
	end
end

HLSL.Print = function ( representation )
	local code = ""
	for i,v in ipairs( representation.code ) do
	
		if HLSL[ "Get" .. v.type ] == nil then
			error( "No printer for type " .. v.type .. " in HLSL printer", 1 )
		end
		
		code = code .. HLSL[ "Get" .. v.type ]( v )
	end
	
	print( code )
end