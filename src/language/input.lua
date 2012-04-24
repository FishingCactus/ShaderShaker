input = { __semantic = {} }

function DefineInput( name, type, semantic )

	if input[ name ] ~= nil then
		error( "An entry named '" .. name .."' already exists in the input structure", 2 )
	end
	
	if input.__semantic[ semantic ] ~= nil then
		error( "An entry already have the semantic '" .. semantic .. "' in the input structure", 2 )
	end
	
	-- :TODO: Validate semantic and type value
	
	local input_variable = { type = type, value = "input." .. name, semantic = semantic }
	input[ name ] = input_variable
	input.__semantic[ semantic ] = input_variable
	Language.AttachVectorMetatable( input_variable )
end