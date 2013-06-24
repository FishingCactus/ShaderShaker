ShaderParameterInliner = {
    ast_node = {},
    constants_optimizer = {}
}

function ShaderParameterInliner:new( ast_node, constants_optimizer )
    local instance = {}
    setmetatable( instance, self )

    self.__index = self
    self.ast_node = ast_node
    self.constants_optimizer = constants_optimizer

    return instance
end

function ShaderParameterInliner:Process()

    local reimplemented_functions_table = {}

    for node_index, node in pairs( self.ast_node ) do
        if node.name == "technique" then
            local technique_name

            for index, technique_child in pairs( node ) do
                if index == 1 then
                    technique_name = technique_child
                elseif technique_child.name == "pass" then
                    for pass_child_node_index, pass_child_node in ipairs( technique_child ) do
                        if pass_child_node.name == "shader_call" then
                            local shader_function_to_call = pass_child_node[ 3 ]
                            local parameters_table = pass_child_node[ 4 ]

                            if parameters_table ~= nil then
                                local function_to_call = self:DuplicateAndReturnFunction( shader_function_to_call )
                                local constants_table = self:CreateConstantsTableFromParametersTable( parameters_table, function_to_call )
                                local function_name = function_to_call[ 2 ][ 1 ] .. self:HashArgumentList( parameters_table )

                                if reimplemented_functions_table[ function_name ] == nil then
                                    constants_optimizer:ReplaceConstants( function_to_call, constants_table )

                                    function_to_call[ 2 ][ 1 ] = function_name

                                    replace_functions_call_inside_function( Function_GetBody( function_to_call ), constants_table )

                                    reimplemented_functions_table[ function_name ] = function_to_call
                                end

                                remove_shader_inlined_parameters( function_to_call, parameters_table )

                                pass_child_node[ 3 ] = function_name
                                table.remove( pass_child_node, 4 )
                            end
                        end
                    end
                end
            end
        end
    end
end

function ShaderParameterInliner:HashArgumentList( arguments )
    concatArguments = function( args )
        local output = ""

        for i, j in pairs( args ) do
            if type( j ) == "table" then
                output = output .. concatArguments( j )
            else
                output = output .. string.sub( j, 1, 1 )
            end
        end

        return output
    end

    return concatArguments( arguments )
end

function ShaderParameterInliner:CreateConstantsTableFromParametersTable( parameters_table, function_to_call )
    local constants_table = {}
    local parameters_table = function_to_call[ 3 ]
    local parameters_starting_index = #parameters_table - #parameters_value_table

    for index = 1, #parameters_value_table do
        local ID = GetNodeNameValue( parameters_table[ parameters_starting_index + index ], "ID" )

        constants_table[ ID ] = { value = parameters_value_table[ index ][ 1 ], type = parameters_value_table[ index ].name }
    end

    return constants_table
end

function ShaderParameterInliner:RemoveFunctionInlinedParameters( function_parameters, parameters_table )
    for parameter_to_remove_name, parameter_to_remove in pairs( parameters_table ) do
        for parameter_index = 1, #function_parameters do
            local ID = ""
            if function_parameters.name == "argument_expression_list" then
                ID = function_parameters[ parameter_index ][ 1 ]
            else
                ID = GetNodeNameValue( function_parameters[ parameter_index ], "ID" )
            end

            if ID == parameter_to_remove_name then
                table.remove( function_parameters, parameter_index  )
                break
            end
        end
    end
end

function ShaderParameterInliner:DuplicateAndReturnFunction( shader_function_to_call )
    for node_index, node in pairs( self.ast_node ) do
        if node.name == "function" and node[ 2 ][ 1 ] == shader_function_to_call then
            local copied_function = DeepCopy( node )
            table.insert( self.ast_node, node_index + 1, copied_function )

            return copied_function
        end
    end
end

function ShaderParameterInliner:CreateConstantsSubTableFromInputConstants( input_constants_table, function_to_call )
    local constants_table = {}
    local parameters_table = function_to_call[ 3 ]

    for index, value in ipairs( parameters_table ) do
        local ID = GetNodeNameValue( value, "ID" )

        for input_constant_name, input_constant_value in pairs( input_constants_table ) do
            if ID == input_constant_name then
                constants_table[ ID ] = input_constant_value
            end
        end
    end

    return constants_table
end

function ShaderParameterInliner:ReplaceFunctionsCallInsideFunction( body, constants_table )
    local reimplemented_functions_table = {}

    local find_function = function( shader_function_to_call )
        for node_index, node in pairs( self.ast_node ) do
            if node.name == "function" and node[ 2 ][ 1 ] == shader_function_to_call then
                return node
            end
        end
    end

    for i, node in pairs( body ) do
        if node.name == "call" and not Function_IsIntrinsic( node[ 1 ] ) then
            local base_function = find_function( node[ 1 ] )
            local function_constants_table = create_constants_sub_table_from_input_constants( constants_table, base_function )
            local function_to_replace_name = base_function[ 2 ][ 1 ] .. self:HashArgumentList( function_constants_table )

            if function_to_replace_name ~= base_function[ 2 ][ 1 ] then
                if reimplemented_functions_table[ function_to_replace_name ] == nil then
                    local function_to_replace = duplicate_and_return_function( node[ 1 ] )

                    self:ReplaceFunctionsCallInsideFunction( function_to_replace, function_constants_table )

                    constants_optimizer:ReplaceConstants( function_to_replace, constants_table )

                    function_to_replace[ 2 ][ 1 ] = function_to_replace_name

                    reimplemented_functions_table[ function_to_replace_name ] = function_to_replace_name

                    self:RemoveFunctionInlinedParameters( function_to_replace[ 3 ], function_constants_table )
                end

                node[ 1 ] = function_to_replace_name

                self:RemoveFunctionInlinedParameters( node[ 2 ], function_constants_table )
            end
        elseif type( node ) == "table" then
            self:ReplaceFunctionsCallInsideFunction( node, constants_table )
        end
    end
end

function ShaderParameterInliner:RemoveShaderInlinedParameters( function_to_call, parameters_table )
    local function_parameters = function_to_call[ 3 ]

    for parameter_to_remove_index = 1, #parameters_table do
        table.remove( function_parameters, #function_parameters - #parameters_table + parameter_to_remove_index )
    end
end