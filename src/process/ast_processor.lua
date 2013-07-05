AstProcessor = {}

function AstProcessor.Process( options )

    local ast_node = GenerateAstFromFileName( options.INPUT )

    if #options.REPLACEMENT_FILES > 0 then
        local function_replacer

        if options.ri then
            function_replacer = FunctionInliner:new()
        else
            function_replacer = FunctionReplacer:new()
        end

        function_replacer:Process( ast_node, options.REPLACEMENT_FILES )
    end

    if not options.dno then
        Optimizer.Process( ast_node, options )
    end

    return ast_node
end