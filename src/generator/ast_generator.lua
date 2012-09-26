AstGenerator = 
{
    ProcessAst = function( ast )
        ShaderPrint( table.tostring_ast( ast ) )
    end



}

RegisterPrinter( AstGenerator, "ast", "ast" )