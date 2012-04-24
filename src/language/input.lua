input = { __semantic = {} }

function DefineInput( name, type, semantic )

	assert( input[ name ] == nil ) 
	assert( input.__semantic[ semantic ] == nil )
	local input_variable = { type = type, value = "input." .. name, semantic = semantic }
	input[ name ] = input_variable
	input.__semantic[ semantic ] = input_variable
	Language.AttachVectorMetatable( input_variable )
end