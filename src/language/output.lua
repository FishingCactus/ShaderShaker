Language = Language or {}

-- :TRICKY: output must be assigned, so this needs a metatable
Language.OutputMetaType = {
	__newindex = function( table, key, value )
	
		assert( rawget( table, key ) == nil )
		assert( table.__definition[ key ] ~= nil )
		assert( table.__definition[ key ].type == value.type )
		
		rawset( table, key, value );
	
	end
}

output = { __definition={}, __semantic = {} }
setmetatable( output, Language.OutputMetaType );


function DefineOutput( name, type, semantic )

	assert( output.__definition[ name ] == nil ) 
	assert( output.__semantic[ semantic ] == nil )
	
	-- :TODO: Validate semantic and type value
	
	local output_variable = { type = type, value = "output." .. name, semantic = semantic }
	output.__definition[ name ] = output_variable
	output.__semantic[ semantic ] = output_variable
end