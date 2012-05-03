
function DefineInput()
    input = { __semantic = {} }
end

function InputAttribute( name, type, semantic )

    if input[ name ] ~= nil then
        error( "An entry named '" .. name .."' already exists in the input structure", 2 )
    end
    
    if input.__semantic[ semantic ] ~= nil then
        error( "An entry already have the semantic '" .. semantic .. "' in the input structure", 2 )
    end
    
    -- :TODO: Validate semantic and type value
    
    local input_variable = { type = type, value = name, node = "Input", semantic = semantic }
    input[ name ] = input_variable
    input.__semantic[ semantic ] = input_variable
    Language.AttachVectorMetatable( input_variable )
end

function EndInput()
    -- :TODO: Validate structure
end