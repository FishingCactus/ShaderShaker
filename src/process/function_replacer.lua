FunctionReplacer = {
    function_name_to_ast = {}
}

function FunctionReplacer:new ()
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    return instance
end

function FunctionReplacer:Process( ast_node, replacement_file_names )
    for index, name in ipairs( replacement_file_names ) do
        local replace_ast = GenerateAstFromFileName( name )

        self.function_name_to_ast = GetFunctionNamesFromAst( replace_ast )
    end

    local replaced_functions = self:ReplaceFunctions( ast_node )

    -- Some replaced functions may need additional functions. Add them to the AST
    for function_name, function_ast in pairs( self.function_name_to_ast ) do
        if not replaced_functions[ function_name ] then
            table.insert( ast_node, 1, function_ast )
        end
    end
end

function FunctionReplacer:ReplaceFunctions( ast_node )
    local replaced_functions = {}

    for ast_function_node, ast_function_index in NodeOfType( ast_node, "function", false ) do
        local
            id,
            type
        local
            arguments = {}

        id = GetDataByName( ast_function_node, "ID" )
        type = GetDataByName( ast_function_node, "type" )

        for ast_function_argument_node in NodeOfType( ast_function_node, "argument", true ) do
            table.insert( arguments, GetDataByName( ast_function_argument_node, "type" ) )
            -- just add more info here like the const or uniform
        end

        local replace_function_ast = self.function_name_to_ast[ id ] or nil

        if replace_function_ast ~= nil then
            local
                is_valid = true

            if id == GetDataByName( replace_function_ast, "ID" ) and type == GetDataByName( replace_function_ast, "type" ) then
                local
                    replace_arguments = {}
                local
                    valid_arguments = true

                for replace_function_argument_node in NodeOfType( replace_function_ast, "argument", true ) do
                    table.insert( replace_arguments, GetDataByName( replace_function_argument_node, "type" ) )
                    -- just add more info here like the const or uniform
                end

                if #replace_arguments == #arguments then
                    for index = 1, #arguments, 1 do
                        if replace_arguments[ index ] ~= arguments[ index ] then
                                 is_valid = false
                            break;
                        end
                    end
                else
                    is_valid = false
                end
            else
                is_valid = false
            end

            if is_valid then
                ast_node[ ast_function_index ] = replace_function_ast
                replaced_functions[ id ] = true
                break;
            end
        end
    end

    return replaced_functions
end