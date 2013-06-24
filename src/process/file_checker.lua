FileChecker = {}

function FileChecker.Process( input_file, ast )
    SelectPrinter( input_file );
    InitializeOutputPrint()

    GetSelectedPrinter().ProcessAst( ast )

    local generated_file = tokenizer( _G.CodeOutput[ 1 ].text );

    local file = assert( io.open( input_file, "r" ) )
    local ground_truth = tokenizer( file:read("*all") )
    file:close()

    repeat
        token_a, value_a = generated_file()
        token_b, value_b = ground_truth()

        if token_a ~= token_b or value_a ~= value_b then
            error( "expected " .. value_b .. ", got " .. value_a )
            return 1
        end

    until token_a == nil and token_b == nil
end