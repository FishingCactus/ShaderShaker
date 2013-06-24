AstProcessor = {}

function AstProcessor.Process( options )

    local ast_node = GenerateAstFromFileName( options.input_file )

    if #options.replacement_files > 0 then
        local function_replacer

        if options.inline_replacement_functions then
            function_replacer = FunctionInliner:new()
        else
            function_replacer = FunctionReplacer:new()
        end

        function_replacer:Process( ast_node, options.replacement_files )
    end

    if options.optimize then
        Optimizer.Process( ast_node )
    end

    return ast_node
end