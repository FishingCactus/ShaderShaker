function ProcessFunctionReplacement( ast_node, replacement_file_names, inline_replacement_functions, optimize )

    local function_name_to_ast = {}
    local structure_name_to_ast = {}
    local replaced_functions = {}
    
    --[[
        Populate function_name_to_ast ( key : function_name, value : function_ast )
        The order in which the replacement files is given is important: functions defined in the latest replacement files will override the definitions found in the first files
    ]]--    
    for index, name in ipairs( replacement_file_names ) do
        local replace_ast = GenerateAstFromFileName( name )
        function_name_to_ast = GetFunctionNamesFromAst( replace_ast, function_name_to_ast )
    end

    -- Populate structure_name_to_ast ( key : structure_name, value : structure_ast )
    for index, name in ipairs( replacement_file_names ) do
        local replace_ast = GenerateAstFromFileName( name )
        structure_name_to_ast = GetStructureNamesFromAst( replace_ast, structure_name_to_ast )
    end
    
    if not inline_replacement_functions then
        replaced_functions = ReplaceFunctions( ast_node, function_name_to_ast )
        
        -- Some replaced functions may need additional functions. Add them to the AST
        for function_name, function_ast in pairs( function_name_to_ast ) do
            if not replaced_functions[ function_name ] then
                table.insert( ast_node, 1, function_ast )
            end
        end 
    else
        local sorted_functions = GetSortedFunctions( function_name_to_ast )
        
        if next( sorted_functions ) ~= nil then
            local sorted_functions2 = {}
            local inversed_sorted_functions = {}
            local function_count = 0
            
            for function_name, index in pairs( sorted_functions ) do
                if sorted_functions2[ index ] == nil then
                    sorted_functions2[ index ] = {}
                end
                
                table.insert( sorted_functions2[ index ], function_name )
            end
            
            for index, called_function_name_table in IterateTableByKeyOrder( sorted_functions2, function ( left, right ) return left > right end ) do
                for _, called_function_name in ipairs( called_function_name_table ) do       
                    if not Function_IsIntrinsic( called_function_name ) then
                        table.insert( inversed_sorted_functions, called_function_name )
                        function_count = function_count + 1
                    end
                end
            end
            
            --[[ 
            First inline functions overriden by latest replacement files
            eg: file1 has a function Foo() which itself calls a function Bar(), overriden by file2, we need to replace the call to Bar() by the function body of Bar() in file2
            ]]--
            for index = 1, function_count - 1 do
                local function_name = inversed_sorted_functions[ index ]
                local function_body_ast = function_name_to_ast[ function_name ]
                
                for index2 = index + 1, function_count do
                    local other_function_name = inversed_sorted_functions[ index2 ]
                    InlineReplacementFunctions( function_name_to_ast[ other_function_name ], function_name, function_body_ast )
                end
            end
            
            --[[
            Next, replace the functions in the original ast
            ]]--
            for index = 1, function_count do
                local function_name = inversed_sorted_functions[ index ]
                
                InlineReplacementFunctions( ast_node, function_name, function_name_to_ast[ function_name ] )
            end
        end
        
        -- Augment structure definitions with members found in the replacement files
        UpdateStructureDefinitions( ast_node, structure_name_to_ast )
    end
end

function GetSortedFunctions( function_name_to_ast )
    local sorted_functions = {}
    local called_functions = {}
    
    for name, ast in pairs( function_name_to_ast ) do
        sorted_functions[ name ] = 0
    end
    
    for name, ast in pairs( function_name_to_ast ) do
        for ast_function_node, ast_function_index in NodeOfType( ast, "call", true ) do
            local function_name = ast_function_node[ 1 ]
            
            sorted_functions[ name ] = sorted_functions[ name ] + 1
            sorted_functions[ function_name ] = sorted_functions[ name ] + 1
        end
    end
    
    return sorted_functions
end

function GetFunctionNamesFromAst( replacement_file_ast, function_name_to_ast )
    for ast_function_node, ast_function_index in NodeOfType( replacement_file_ast, "function", false ) do
        local id = GetDataByName( ast_function_node, "ID" )
        function_name_to_ast[ id ] = ast_function_node
    end
    
    return function_name_to_ast
end

function GetStructureNamesFromAst( replacement_file_ast, structure_name_to_ast )
    for ast_structure_node, ast_function_index in NodeOfType( replacement_file_ast, "struct_definition", false ) do
        local name = ast_structure_node[ 1 ]
        
        if structure_name_to_ast[ name ] == nil then
            structure_name_to_ast[ name ] = {}
        end
        
        for field_index, field_node in ipairs( ast_structure_node ) do
            if field_node.name ~= nil then
                table.insert( structure_name_to_ast[ name ], field_node ) 
            end
        end
    end
    
    return structure_name_to_ast
end

function InlineReplacementFunctions( ast_node, function_name, function_ast_node )
    if Function_IsIntrinsic( function_name ) then
        return 0
    end
    
    for child_index, child_node in ipairs( ast_node ) do
        if child_node.name then
            if child_node.name == "call" then
                if child_node[ 1 ] == function_name then
                    return child_index
                end
            end
            
            local found_index = InlineReplacementFunctions( child_node, function_name, function_ast_node )
            
            if found_index > 0 then
                local function_body_ast = Function_GetBody( function_ast_node )
                local block_node = { name = "block" }
                
                for i, n in ipairs( function_body_ast ) do
                    table.insert( block_node, DeepCopy( n ) )
                end
               
                ast_node[ child_index ] = block_node
                local t = ""
            end
         end
    end
    
    return 0
end

function ReplaceFunctions( ast_node, function_name_to_ast )
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
        
        local replace_function_ast = function_name_to_ast[ id ] or nil
        
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

function UpdateStructureDefinitions( ast_node, structure_name_to_ast )
    for ast_structure_node, index in NodeOfType( ast_node, "struct_definition", false ) do
        local structure_name  = ast_structure_node[ 1 ]
        
        if structure_name_to_ast[ structure_name ] ~= nil then
            for field_index, field_node in ipairs( structure_name_to_ast[ structure_name ] ) do
                table.insert( ast_structure_node, field_node )
            end
        end    
    end
end