i = 0
options = {}

local HLSLGenerator_mt = {
    __index = function( t, name )
        if options.hlsl_version == "11" and HLSLGenerator11[ name ] ~= nil then
            return HLSLGenerator11[ name ]
        else
            return HLSLGenerator9[ name ]
        end
    end
}

HLSLGenerator = {
    ["ProcessAst"] = function( ast, o )
        options = o or {}

        for _, value in ipairs( ast ) do
            if HLSLGenerator[ "process_" .. value.name ] == nil then
                error( "No printer for ast node '" .. value.name .. "' in HLSL printer", 1 )
            end
            
            i = 0

            ShaderPrint( HLSLGenerator[ "process_" .. value.name ]( value ) .. '\n' )
        end
    end,
    
    ["ProcessNode"] = function( node )
        if HLSLGenerator[ "process_" .. node.name ] == nil then
            error( "No printer for ast node '" .. node.name .. "' in HLSL printer", 1 )
        end

        return HLSLGenerator[ "process_" .. node.name ]( node )
    end,
}

setmetatable( HLSLGenerator, HLSLGenerator_mt )

RegisterPrinter( HLSLGenerator, "hlsl", "fx" )