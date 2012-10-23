
local stream

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
    stream = {
		text = "",
		write = function( self, data ) self.text = self.text .. data end,
		}

	_G.CodeOutput = _G.CodeOutput or {}
	table.insert( _G.CodeOutput, stream )
end

function InitializeOutputFile( file )

    stream, error_message = io.open( file, "w" )
    
    if stream == nil then
        error( "Error while opening file : " .. error_message, 2 )
    end
end