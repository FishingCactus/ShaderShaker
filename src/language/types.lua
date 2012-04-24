Language = Language or {}

Language.IsValidSwizzle = function( swizzle, type )
	local position_swizzle = "xyzw"
	local color_swizzle = "rgba"
	local parameter_count = tonumber( string.sub( string.reverse( type ), 1, 1 ) );
	
	parameter_count = parameter_count or 1;
	
	return
		( string.match( swizzle, "[" ..string.sub( position_swizzle, 1, parameter_count ) .. "]*" ) == swizzle )
		or ( string.match( swizzle, "[" .. string.sub( color_swizzle, 1, parameter_count ) .. "]*" )  == swizzle )
end

Language.VectorMetatable = {
	__add = function( a, b ) 
		assert( a.type == b.type );
 		local result = { type = a.type, node="add", arguments={a,b} }
 		setmetatable( result, Language.VectorMetatable )
 		return result
	end,
	
	__mul = function( a, b ) 
		assert( type(a) == "number" or type(b) == "number" or  a.type == b.type );
 		local result = { type = ( type(a) == "number" and b.type ) or a.type, node="mul", arguments={a,b} }
 		setmetatable( result, Language.VectorMetatable )
 		return result
	end,
	
	__newindex = function( table, key, value )
		error( "No support for swizzled assignment yet", 2 )
	end,
	
	__index = function( vector, key )
	
		if not Language.IsValidSwizzle( key, vector.type ) then
			error( "Invalid swizzle", 2 );
		end
		
		local result = { type = "float"..tonumber( string.len(key) ), node="swizzle", arguments={ vector, key } }
		setmetatable( result, Language.VectorMetatable )
		return result
	end
	
}

Language.DefineVectorType = function( type, count )

	local name

	if count == 1 then 
		name = type
	else
		name = type .. count
	end

	_G[ name .. "_new" ] = 
		function( ... )
			assert( #{...} == count );
			local var = { type = name, node="variable", value={...} }
			Language.AttachVectorMetatable( var )
			
			return var;
		end
		
	return var;

end


Language.DefineVectorType( "float", 1 )
Language.DefineVectorType( "float", 2 )
Language.DefineVectorType( "float", 3 )
Language.DefineVectorType( "float", 4 )

Language.AttachVectorMetatable = function( variable )
	
	assert( variable.type == "float" or variable.type == "float2" or variable.type == "float3" or variable.type == "float4" );
	
	setmetatable( variable, Language.VectorMetatable );

end