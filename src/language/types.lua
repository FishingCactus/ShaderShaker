Language = Language or {}

function Language.IsNumber( variable )
    return type( variable ) == "number"
end
local IsNumber = Language.IsNumber

function Language.IsVector( variable )
    if type( variable ) ~= "string" then error( "Type string expected", 2 ) end
    
    return string.match( variable, "float[2-4]*" ) == variable
end
local IsVector = Language.IsVector

function Language.IsMatrix( variable )
    if type( variable ) ~= "string" then error( "Type string expected", 2 ) end
    
    return string.match( variable, "float[2-4]x[2-4]" ) == variable
end
local IsMatrix = Language.IsMatrix

function Language.GetMatrixSize( matrix )

    assert( IsMatrix( matrix ) )
    local row, column = string.match( matrix, "(%d)x(%d)" )

    return tonumber( row ), tonumber( column )
end
local GetMatrixSize = Language.GetMatrixSize


function Language.GetVectorSize( vector )
    return tonumber( string.sub( string.reverse( vector ), 1, 1 ) ) or 1;
end
local GetVectorSize = Language.GetVectorSize

function Language.IsValidMultiplication( a, b )
    if a == b then 
        return true
    end
    
    if IsMatrix( a ) then
        local row, column = GetMatrixSize( a )
        local vector_size = GetVectorSize( b )
        
        return row == vector_size;
    else
        assert( IsMatrix( b ) )
        
        local row, column = GetMatrixSize( b )
        local vector_size = GetVectorSize( a )
        
        return column == vector_size;
        
    end
end

local IsValidMultiplication = Language.IsValidMultiplication

function Language.MultiplyVectorMatrix( a, b )

    assert( IsMatrix( a.type ) ~= IsMatrix( b.type ) )
    
    local result = { node="Operation", operation="mul", arguments={a,b}  }
    
    if IsMatrix( a.type ) then
        local row, column = GetMatrixSize( a.type )
        local vector_size = GetVectorSize( b.type ) 
        
        result.type = "float" .. column
    else
        local row, column = GetMatrixSize( b.type )
        local vector_size = GetVectorSize( a.type ) 
        
         result.type = "float" .. row
    end
    
    Language.AttachVectorMetatable( result )
    return result;
end

function Language.IsValidSwizzle( swizzle, type )
    local position_swizzle = "xyzw"
    local color_swizzle = "rgba"
    local parameter_count = Language.GetVectorSize( type );
    
    parameter_count = parameter_count or 1;
    
    return
        ( string.match( swizzle, "[" ..string.sub( position_swizzle, 1, parameter_count ) .. "]*" ) == swizzle )
        or ( string.match( swizzle, "[" .. string.sub( color_swizzle, 1, parameter_count ) .. "]*" )  == swizzle )
end

Language.VectorMetatable = {

    __add = function( a, b ) 
        if a.type ~= b.type then
            error( "Can't add two vector of different size", 2 )
        end
        local result = { type = a.type, node=="Operation", operation="add", arguments={a,b} }
        setmetatable( result, Language.VectorMetatable )
        return result
    end,
    
    __mul = function( a, b )
        
        if not( IsNumber(a) or IsNumber(b) or IsValidMultiplication( a.type, b.type ) ) then
            error( "Mismatch in size, multiplication parameters don't match", 2 );
        end
        
        local result
        
        if not IsNumber( a ) and not IsNumber( b ) and ( IsMatrix( a.type ) or IsMatrix( b.type ) ) then
            result = Language.MultiplyVectorMatrix( a, b )
        else
            result = { type = ( IsNumber(a) and b.type ) or a.type, node="Operation", operation="mul", arguments={a,b} }
        end
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
        
        local result = { type = "float"..tonumber( string.len(key) ), node="Swizzle", arguments={ vector, key } }
        setmetatable( result, Language.VectorMetatable )
        return result
    end
    
}

Language.MatrixMetatable = {

    __add = function( a, b ) 
        if a.type ~= b.type then
            error( "Can't add two matrix of different size", 2 )
        end
        local result = { type = a.type, node=="Operation", operation="add", arguments={a,b} }
        setmetatable( result, Language.MatrixMetatable )
        return result
    end,
    
    __mul = function( a, b )
        
        if not( IsNumber(a) or IsNumber(b) or IsValidMultiplication( a.type, b.type ) ) then
            error( "Mismatch in size, multiplication parameters don't match", 2 );
        end
        
        local result
        
        if not IsNumber( a ) and not IsNumber( b ) and ( IsVector( a.type ) or IsVector( b.type ) ) then
            result = Language.MultiplyVectorMatrix( a, b )
        else
            result = { type = ( IsNumber(a) and b.type ) or a.type, node="Operation", operation="mul", arguments={a,b} }
            setmetatable( result, Language.MatrixMetatable )
        end
        return result
    end,
    
    __newindex = function( table, key, value )
        error( "No support for swizzled assignment yet", 2 )
    end,
    
    __index = function( vector, key )
    
        if not IsNumber( key ) or key < 0 or key > 3  then
            error( "Invalid array index", 2 );
        end
        
        local row, column = GetMatrixSize( vector )
        local result = { type = "float".. row, node="ArrayIndex", arguments={ vector, key } }
        setmetatable( result, Language.VectorMetatable )
        return result
    end
    
}

function Language.DefineVectorType( type, count )

    local name

    if count == 1 then 
        name = type
    else
        name = type .. count
    end

    _G[ name ] = 
        function( ... )
            local arguments = {...}
            local parameter_count = 0
            
            for _,arg in ipairs( arguments ) do
                if IsNumber( arg ) then
                    parameter_count = parameter_count + 1
                elseif IsVector( arg.type ) then
                    parameter_count = parameter_count + GetVectorSize( arg.type )
                else
                    error( "Wrong argument to constructor " .. name .. ": only vector and number are supported" , 2 )
                end
            end
            
            if parameter_count ~= count then
                error( "Wrong argument count, expect " .. count .. " got " .. parameter_count, 2 )
            end
            
            local var = { type = name, node = "Constructor", value={...} }

            Language.AttachVectorMetatable( var )
            
            return var;
        end
        
    return var;

end

function Language.DefineMatrixType( type, row, column )

    local name

    assert( row ~= 1 and column ~= 1 )
        
    name = type .. row .. "x" ..column
    
    _G[ name ] = 
        function( ... )
            if #{...} ~= count and #{...} ~= 0 then
                error( "Wrong argument count, expect " .. ( row * column ) .. " got " .. #{...}, 2 )
            end
            
            local var = { type = name, node = "Constructor", value={...} }

            Language.AttachMatrixMetatable( var )
            
            return var;
        end
        
    return var;

end


Language.DefineVectorType( "float", 1 )
Language.DefineVectorType( "float", 2 )
Language.DefineVectorType( "float", 3 )
Language.DefineVectorType( "float", 4 )

Language.DefineMatrixType( "float", 2, 2 )
Language.DefineMatrixType( "float", 2, 3 )
Language.DefineMatrixType( "float", 2, 4 )
Language.DefineMatrixType( "float", 3, 2 )
Language.DefineMatrixType( "float", 3, 3 )
Language.DefineMatrixType( "float", 3, 4 )
Language.DefineMatrixType( "float", 4, 2 )
Language.DefineMatrixType( "float", 4, 3 )
Language.DefineMatrixType( "float", 4, 4 )

function Language.AttachVectorMetatable( variable )
    
    assert( variable.type == "float" or variable.type == "float2" or variable.type == "float3" or variable.type == "float4" );
    
    variable.node = variable.node or "Variable"
    setmetatable( variable, Language.VectorMetatable );

end

function Language.AttachMatrixMetatable( variable )
    
    assert( IsMatrix( variable.type ) );
    
    variable.node = variable.node or "Variable"
    setmetatable( variable, Language.MatrixMetatable );

end