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
        
        table.__variable[ key ] = value
    
    end
}


function DefineStructure( name )
    
	__defined_structure = { __definition={}, __semantic = {}, __variable = {}, name = name, node = "Structure" }
    setmetatable( __defined_structure, Language.OutputMetaType );

	return __defined_structure
end

function StructureAttribute( name, type, semantic )

    if __defined_structure.__definition[ name ] ~= nil then
        error( "An entry named '" .. name .."' already exists in " .. __defined_structure.name, 2 )
    end
    
    if semantic and __defined_structure.__semantic[ semantic ] ~= nil then
        error( "An entry already have the semantic '" .. semantic .. "' in " .. __defined_structure.name, 2 )
    end
    
    -- :TODO: Validate semantic and type value
    
    local output_variable = { type = type, value = "output." .. name, semantic = semantic }
    __defined_structure.__definition[ name ] = output_variable
    
	if semantic then 
		__defined_structure.__semantic[ semantic ] = output_variable
	end
end

function EndStructure()

    -- :TODO: Validate structure
	__defined_structure = nil
    
end