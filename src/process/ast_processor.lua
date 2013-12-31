AstProcessor = {}

function AstProcessor.Process( options )

    local ast_node

    if options.semantic then

        local argument_table

        if #options.SEMANTIC_CHUNK > 0 and options.SEMANTIC_CHUNK[ 1 ] ~= "" then

            argument_table = ShallowCopy( options.SEMANTIC_CHUNK )
        end

        argument_table = argument_table or {}

        table.insert( argument_table, 1, options.INPUT )

        local map_data = { }

        for _, file in ipairs( argument_table ) do
            local file_ast_node = GenerateAstFromFileName( file )
            local input_map, output_map, function_map = CreateSemanticTableFromAst( file_ast_node )

            data = { file = options.input_file, ast = file_ast_node, map = { input = input_map, output = output_map, func = function_map } }
            table.insert( map_data, data )
        end

        ast_node = GenerateShader( { "DiffuseColor" }, map_data )

    else

        ast_node = GenerateAstFromFileName( options.INPUT )
    end

    --[[ Old code, should not be used anymore
    if #options.REPLACEMENT_FILES > 0 and options.REPLACEMENT_FILES[ 1 ] ~= "" then
        local function_replacer

        if options.ri then
            function_replacer = FunctionInliner:new()
        else
            function_replacer = FunctionReplacer:new()
        end

        function_replacer:Process( ast_node, options.REPLACEMENT_FILES )
    end
    ]]

    if options.optimize then
        Optimizer.Process( ast_node, options )
    end

    return ast_node
end