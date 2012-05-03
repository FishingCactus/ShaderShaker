function Constant( type, name )

    _G[ name ] = { node = "Constant", type = type, name = name }
    
    if Language.IsMatrix( type ) then
        Language.AttachMatrixMetatable( _G[ name ] )
    else
        Language.AttachVectorMetatable( _G[ name ] )
    end
end