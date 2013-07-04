FunctionInliner = {
    function_name_to_ast = {},
    structure_name_to_ast = {},
    variable_name_to_ast = { variable_declarations = {}, texture_declarations = {}, sampler_declarations = {}, function_declarations = {} },
    caller_callee_table = {}
}

function FunctionInliner:new ()
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    return instance
end

function FunctionInliner:Process( ast_node, replacement_file_names )
    for index, name in ipairs( replacement_file_names ) do
        local replace_ast = GenerateAstFromFileName( name )

        --[[
        Populate function_name_to_ast ( key : function_name, value : function_ast )
        The order in which the replacement files is given is important: functions defined in the latest replacement files will override the definitions found in the first files
        ]]--
        self.function_name_to_ast = GetFunctionNamesFromAst( replace_ast, self.function_name_to_ast )

        -- Populate structure_name_to_ast ( key : structure_name, value : structure_ast )
        self:SetStructureNamesFromAst( replace_ast )

        -- Populate variable_name_to_ast ( key : variable_name, value : structure_ast )
        self:SetVariableNamesFromAst( replace_ast )
    end

    local function_tree = self:GetFunctionTree( ast_node )
    function_tree = self:CleanFunctionTree( function_tree )
    self:PrintFunctionTree( function_tree )
    
    self.caller_callee_table = self:GetCallerCalleeTable( function_tree )
    local ponderated_function_table = self:GetPonderatedFunctionTable( function_tree )

    local max_deepness = #ponderated_function_table

    --[[
        Don't need to run InlineReplacementFunctions for the deepest functions of the hierarchy
        We know they don't call any other replaceable functions
    ]]--
    for deepness = max_deepness, 1, -1 do
        local function_table = ponderated_function_table[ deepness ]

        for i, function_name in ipairs( function_table ) do
            local function_ast = self.function_name_to_ast[ function_name ]

            if function_ast ~= nil then
                local function_body_ast = Function_GetBody( function_ast )

                if function_body_ast ~= nil then
                    self:InlineReplacementFunctions( function_name, function_body_ast )
                end
            end
        end
    end

    for function_ast in NodeOfType( ast_node, "function", true ) do
        local function_body_ast = Function_GetBody( function_ast )
        local function_name = Function_GetName( function_ast )

        self:InlineReplacementFunctions( function_name, function_body_ast, self.function_name_to_ast )
    end

    local used_structure_members_by_shader = self:GetUsedStructureMembersByShader( ast_node )

    -- Augment structure definitions with members found in the replacement files
    self:UpdateStructureDefinitions( ast_node, used_structure_members_by_shader )

    -- Augment variable declarations with members found in the replacement files
    self:UpdateVariableDeclaration( ast_node )
end

function FunctionInliner:PrintFunctionTree( table, deepness )
    deepness = deepness or 0

    local tab = ""
    for i = 0, deepness do
        tab = tab .. "    "
    end

    for i = 1, #table do
        local item = table[ i ]
        local caller = item.name
        local called_functions = item.children

        print( tab .. caller )

        self:PrintFunctionTree( called_functions, deepness + 1 )
    end
end

-- This function returns the hierarchy function call of the complete shader file

-- [
--     1 = { name = "VSMain", children = [ 1 = { name = "Function1" }, 2 = { name = "Function2", children = .... } ] }
--     2 = { name = "PSMain", children = [ 1 = { name = "Function3" } ] }
-- ]
function FunctionInliner:GetFunctionTree( ast_node )
    local shader_main_names = { "VSMain", "PSMain" }
    local function_tree = {}

    for i, shader_main_name in ipairs( shader_main_names ) do
        for shader_main_function_node, shader_body_index in NodeOfType( ast_node, "function", true ) do
            local shader_main_name_node = Function_GetName( shader_main_function_node )

            if shader_main_name_node == shader_main_name then
                local item = {}
                local shader_main_body_node = Function_GetBody( shader_main_function_node )

                item.name = shader_main_name
                item.children = self:GetCalledFunctionsTable( shader_main_body_node )

                table.insert( function_tree, item )
            end
        end
    end

    return function_tree
end

function FunctionInliner:GetCalledFunctionsTable( calling_function_node )
    local called_function_table = {}

    for called_function_node, called_function_index in NodeOfType( calling_function_node, "call", true ) do
        local called_function_name = called_function_node[ 1 ]

        if string.starts( called_function_name, "__" ) then
            local item = {}
            item.name = called_function_name

            if self.function_name_to_ast[ called_function_name ] ~= nil then
                item.children = self:GetCalledFunctionsTable( self.function_name_to_ast[ called_function_name ] )
            else
                item.children = {}
            end

            table.insert( called_function_table, item )
        end
    end

    return called_function_table
end

-- This function cleans the hierarchy call function tree. It will only keep the first occurence of each function
-- Ex:

-- PSMain
--     |-> Function1()
--             |-> Function2()
--     | -> Function3()
--     |       |-> Function1()
--     | -> Function2()

-- will become

-- PSMain
--     |-> Function1()
--             |-> Function2()
--     | -> Function3()
function FunctionInliner:CleanFunctionTree( function_tree, already_used_functions )
    already_used_functions = already_used_functions or {}
    local children_to_remove = {}

    for i = 1, #function_tree do

        local item = function_tree[ i ]
        local caller = item.name
        local called_functions = item.children

        if already_used_functions[ caller ] then
            table.insert( children_to_remove, i )
        else
            already_used_functions[ caller ] = true
            
            local j = 1
            
            while j <= #called_functions do
                if already_used_functions[ called_functions[ j ].name ] then
                    table.remove( called_functions, j )
                else
                    already_used_functions[ called_functions[ j ].name ] = true
                    self:CleanFunctionTree( called_functions[ j ].children, already_used_functions )
                    j = j + 1
                end
            end
        end
    end

    for i = #children_to_remove, 1, -1 do
        table.remove( function_tree, children_to_remove[ i ] )
    end

    return function_tree
end

-- This function will return an array of functions sorted by their deepness in the call hierarchy
-- Ex:

-- PSMain
--     |-> Function1()
--             |-> Function2()
--     | -> Function3()

-- will become

-- [ 1 ] = [ PSMain ]
-- [ 2 ] = [ Function1, Function3 ]
-- [ 3 ] = [ Function2 ]
function FunctionInliner:GetPonderatedFunctionTable( function_tree, ponderated_function_table, deepness )
    ponderated_function_table = ponderated_function_table or {}
    deepness = deepness or 1

    if ponderated_function_table[ deepness ] == nil then
        ponderated_function_table[ deepness ] = {}
    end

    for i = 1, #function_tree do
        local item = function_tree[ i ]
        local caller = item.name
        local called_functions = item.children

        for j = 1, #called_functions do
            table.insert( ponderated_function_table[ deepness ], called_functions[ j ].name )

            self:GetPonderatedFunctionTable( called_functions[ j ].children, ponderated_function_table, deepness + 1 )
        end

        if string.starts( caller, "__" ) then
            table.insert( ponderated_function_table[ deepness ], caller )
        end
    end

    return ponderated_function_table
end

-- This function takes the function hierarchy tree, and outputs a dictionary

-- Ex:

-- PSMain
--     |-> Function1()
--             |-> Function2()
--     | -> Function3()

-- will become

-- [ Function1 ] = PSMain
-- [ Function2 ] = Function1
-- [ Function3 ] = PSMain

-- It is used in InlineReplacementFunctions to replace a function call by its body only if we are in the correct calling function
-- Subsquent calls will be discarded
function FunctionInliner:GetCallerCalleeTable( function_tree, caller_callee_table )
    local result = caller_callee_table or {}

    for i = 1, #function_tree do
        local item = function_tree[ i ]
        local caller = item.name
        local called_functions = item.children

        for j = 1, #called_functions do
            local called_function_name = called_functions[ j ].name

            if result[ called_function_name ] == nil then
                result[ called_function_name ] = caller
            end
        end

        result = self:GetCallerCalleeTable( called_functions, result )
    end

    return result
end

function FunctionInliner:SetStructureNamesFromAst( replacement_file_ast )
    for ast_structure_node, ast_function_index in NodeOfType( replacement_file_ast, "struct_definition", false ) do
        local name = ast_structure_node[ 1 ]

        if self.structure_name_to_ast[ name ] == nil then
            self.structure_name_to_ast[ name ] = {}
        end

        for field_index, field_node in ipairs( ast_structure_node ) do
            if field_node.name ~= nil then
                table.insert( self.structure_name_to_ast[ name ], field_node )
            end
        end
    end
end

function FunctionInliner:SetVariableNamesFromAst( replacement_file_ast )
    for node, ast_function_index in NodeOfType( replacement_file_ast, "variable_declaration", false ) do
        local variable_name = Variable_GetName( node )

        self.variable_name_to_ast.variable_declarations[ variable_name ] = node
    end

    for node, ast_function_index in NodeOfType( replacement_file_ast, "texture_declaration", false ) do
        local variable_name = Texture_GetName( node )

        self.variable_name_to_ast.texture_declarations[ variable_name ] = node
    end

    for node, ast_function_index in NodeOfType( replacement_file_ast, "sampler_declaration", false ) do
        local variable_name = Sampler_GetName( node )

        self.variable_name_to_ast.sampler_declarations[ variable_name ] = node
    end

    for node, ast_function_index in NodeOfType( replacement_file_ast, "function", false ) do
        local variable_name = Function_GetName( node )

        if not string.starts( variable_name, "__" ) then
            self.variable_name_to_ast.function_declarations[ variable_name ] = node
        end
    end
end

function FunctionInliner:InlineReplacementFunctions( calling_function, function_ast )
    local node_index_offset = 0

    for node_index = 1, #function_ast do
        local new_index = node_index + node_index_offset
        local node = function_ast[ new_index ]

        if node and node.name then
            self:InlineReplacementFunctions( calling_function, node )

            local function_to_replace = self:CanFindFunctionToReplaceInAst( node )

            if function_to_replace ~= "" then

                local replacement_ast = self.function_name_to_ast[ function_to_replace ]

                if replacement_ast ~= nil and self.caller_callee_table[ function_to_replace ] == calling_function then
                    local replacement_body_ast = Function_GetBody( replacement_ast )

                    if #replacement_body_ast > 0 then
                        local inserted_node_index = new_index

                        table.remove( function_ast, new_index )

                        for i, n in ipairs( replacement_body_ast ) do
                            table.insert( function_ast, inserted_node_index, n )

                            inserted_node_index = inserted_node_index + 1
                        end
                        
                        node_index_offset = node_index_offset + #replacement_body_ast - 1
                    else
                        table.remove( function_ast, new_index )
                        node_index_offset = node_index_offset - 1
                    end
                else
                    table.remove( function_ast, new_index )
                    node_index_offset = node_index_offset - 1
                end
            end
        end
    end
end

function FunctionInliner:CanFindFunctionToReplaceInAst( ast )
    for ast_function_node, ast_function_index in NodeOfType( ast, "call", true ) do
        local function_name = ast_function_node[ 1 ]

        if string.starts( function_name, "__" ) then
            return function_name
        end
    end

    return ""
end

function FunctionInliner:UpdateStructureDefinitions( ast_node, used_structure_members_by_shader )
    local get_structure_member_name = function( ast ) return ast[ 2 ][ 1 ] end

    for ast_structure_node, index in NodeOfType( ast_node, "struct_definition", false ) do
        local structure_name  = ast_structure_node[ 1 ]
        local member_indexes_to_delete = {}
        local structure_members = Structure_GetMembers( ast_structure_node )

        for member_index, member_node in ipairs( structure_members ) do
            local member_id = get_structure_member_name( member_node )
            local is_member_redefined = false

            if self.structure_name_to_ast[ structure_name ] ~= nil then
                for _, redefined_member in ipairs( self.structure_name_to_ast[ structure_name ] ) do
                    if get_structure_member_name( redefined_member ) == member_id then
                        is_member_redefined = true
                        break
                    end
                end
            end

            if is_member_redefined or not used_structure_members_by_shader[ structure_name ][ member_id ] then
                table.insert( member_indexes_to_delete, member_index + 1 ) -- Add one because Structure_GetMembers doesn't return the first element of the members ( the name of the structure )
            end
        end

        for i = #member_indexes_to_delete, 1, -1 do
            local index_to_delete = member_indexes_to_delete[ i ]
            table.remove( ast_structure_node, index_to_delete )
        end

        if self.structure_name_to_ast[ structure_name ] ~= nil then
            --[[
            It may happen that the same structure member is redefined by different replacement files
            We then need to filter the members to add to the structure, to keep only the latest defined members
            ]]--
            local filtered_structure_members = {}

            for field_index, field_node in ipairs( self.structure_name_to_ast[ structure_name ] ) do
                local member_id = get_structure_member_name( field_node )
                filtered_structure_members[ member_id ] = field_node
            end

            for field_name, field_node in pairs( filtered_structure_members ) do
                if used_structure_members_by_shader[ structure_name ][ field_name ] then
                    table.insert( ast_structure_node, field_node )
                end
            end
        end
    end
end

function FunctionInliner:UpdateVariableDeclaration( ast_node )
    local insert_declarations = function ( declarations_table ) for variable_name, variable_ast in pairs( declarations_table ) do table.insert( ast_node, 1, variable_ast ) end end

    insert_declarations( self.variable_name_to_ast.function_declarations )
    insert_declarations( self.variable_name_to_ast.sampler_declarations )
    insert_declarations( self.variable_name_to_ast.texture_declarations )
    insert_declarations( self.variable_name_to_ast.variable_declarations )
end

function FunctionInliner:GetUsedStructureMembersByShader( ast_node )

    local return_value = { VS_INPUT = {}, VS_OUTPUT = {}, PS_INPUT = {}, PS_OUTPUT = {} }
    local vertex_shader_node = Function_GetNodeFromId( ast_node, "VSMain" )

    for child_node in NodeOfType( vertex_shader_node, 'postfix' ) do
        local postfix_left_member = child_node[ 1 ][ 1]
        local postfix_right_member = child_node[ 2 ][ 1]

        if postfix_left_member == "input" then
            return_value.VS_INPUT[ postfix_right_member ] = true
        else
            return_value.VS_OUTPUT[ postfix_right_member ] = true
        end
    end

    local pixel_shader_node = Function_GetNodeFromId( ast_node, "PSMain" )

    for child_node in NodeOfType( pixel_shader_node, 'postfix' ) do
        local postfix_left_member = child_node[ 1 ][ 1]
        local postfix_right_member = child_node[ 2 ][ 1]

        if postfix_left_member == "input" then
            return_value.PS_INPUT[ postfix_right_member ] = true
        else
            return_value.PS_OUTPUT[ postfix_right_member ] = true
        end
    end

    return return_value
end