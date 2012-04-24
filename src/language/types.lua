Language = Language or {}

Language.VectorMetatable = {
	__add = function( a, b ) 
		assert( a.type == b.type );
 		local result = { type = a.type, node="add", arguments={a,b} }
 		setmetatable( result, getmetatable( a ) )
 		return result
	end,
	
	__mul = function( a, b ) 
		assert( type(a) == "number" or type(b) == "number" or  a.type == b.type );
 		local result = { type = ( type(a) == "number" and b.type ) or a.type, node="mul", arguments={a,b} }
 		setmetatable( result, getmetatable( ( type(a) == "number" and b ) or a ) )
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