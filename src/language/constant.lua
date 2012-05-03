function Constant( type, name )

    _G[ name ] = { node = "Constant", type = type, name = name }
    
    Language.AttachVectorMetatable( _G[ name ] )
end