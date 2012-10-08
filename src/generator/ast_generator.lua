AstGenerator = 
{
    PreprocessAst = function( ast )
        GLSL_Helper_ConvertIntrinsicFunctions( ast )
    end,

    ProcessAst = function( ast )
        ShaderPrint( table.tostring_ast( ast ) )
    end
}

RegisterPrinter( AstGenerator, "ast", "ast" )