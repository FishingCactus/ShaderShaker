Language = Language or {}

-- :TRICKY: output must be assigned, so this needs a metatable
Language.OutputMetaType = {
	__newindex = function( table, key, value )
	
		if rawget( table, key ) ~= nil then
			error( "Entry " .. key .. " of output structure has already been assigned", 2 )
		end
		
		if table.__definition[ key ] == nil then
			error( "Unknown entry in output structure : " .. key, 2 )
		end
		
		if table.__definition[ key ].type ~= value.type then
			error( "Invalid type for " .. ", expect " .. table.__definition[ key ].type .. " got " .. value.type, 2 )
		end
		
		rawset( table, key, value );
	
	end
}

output = { __definition={}, __semantic = {} }
setmetatable( output, Language.OutputMetaType );


function DefineOutput( name, type, semantic )

	if output.__definition[ name ] ~= nil then
		error( "An entry named '" .. name .."' already exists in the output structure", 2 )
	end
	
	if output.__semantic[ semantic ] ~= nil then
		error( "An entry already have the semantic '" .. semantic .. "' in the output structure", 2 )
	end
	
	-- :TODO: Validate semantic and type value
	
	local output_variable = { type = type, value = "output." .. name, semantic = semantic }
	output.__definition[ name ] = output_variable
	output.__semantic[ semantic ] = output_variable
end