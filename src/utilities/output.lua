
local stream
local old_print = print

print = function( ... )
    error( "Don't use print", 2 );
end

function ShaderPrint( ... )
    local argument = {...}
    
    if type( argument[ 1 ] ) == "number" then
        stream:write( string.rep( "\t", argument[1] ) )
        stream:write( argument[ 2 ] )
    else
        stream:write( argument[ 1 ] )
    end

end

function InitializeOutputPrint()
    stream = io.stdout
end

function InitializeOutputFile( file )

    stream, error_message = io.open( file, "w" )
    
    if stream == nil then
        error( "Error while opening file : " .. error_message, 2 )
    end
end