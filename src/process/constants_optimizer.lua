ConstantsOptimizer = {
    ast_node = {},
    constants = {},
    constants_replacement = {}
}

function ConstantsOptimizer:new( ast_node, constants_replacement )
    local instance = {}
    setmetatable( instance, self )

    self.__index = self
    self.ast_node = ast_node
    self.constants_replacement = constants_replacement

    self:Initialize()

    return instance
end

function ConstantsOptimizer:Initialize()

    for variable_declaration_node, variable_declaration_node_index in InverseNodeOfType( self.ast_node, "variable_declaration", false ) do
        local variable_type = Variable_GetType( variable_declaration_node )
        for variable_node, variable_index in InverseNodeOfType( variable_declaration_node, "variable", false ) do
            local index = 1
            local name = variable_node[ index ]

            self.constants[ name ] = { type = variable_type }

            while variable_node[ index ] ~= nil do
                local node_name = variable_node[ index ].name

                if node_name == "initial_value_table" then
                    local value = variable_node[ index ]
                    self.constants[ name ].value = value
                    break
                elseif node_name == "literal" then
                    local value = variable_node[ index ]
                    self.constants[ name ].value = value[ 1 ]
                    break
                end

                index = index + 1
            end
        end
    end

end

function ConstantsOptimizer:Process()
    if self.constants_replacement ~= nil then
        self:UpdateConstantsWithReplacements()
        self:ReplaceConstants( self.ast_node, self.constants )
    end

    local ast_rewriter = AstRewriter:new()
    ast_rewriter:Process( self.ast_node )

    self:CleanConstants()
end

function ConstantsOptimizer:ReplaceConstants( node, constants )
    if type( node ) ~= "table" then
        return
    end

    if node.name == "variable_declaration" then
        for child_index, child_node in pairs( node ) do
            if child_node.name == "variable" and self.constants_replacement[ child_node[ 1 ] ] then
                node[ child_index ] = nil
            end
        end
    else
        for _, child_node in pairs( node ) do
            if child_node.name == "variable" and self.constants_replacement[ child_node[ 1 ] ] then
                child_node[ 1 ] = constants[ child_node[ 1 ] ].value
                child_node.name = "literal"
            else
                self:ReplaceConstants( child_node, constants )
            end
        end
    end
end

function ConstantsOptimizer:CleanConstants()
    local find_redeclared_variable_in_function = function ( function_node, variable_node )
        local function_body_node

        for function_argument_node in NodeOfType( function_node, "argument", true ) do
            if GetDataByName( function_argument_node, "ID" ) == variable_node[ 1 ] then
                return true;
            end
        end

        for function_body_node in NodeOfType( function_node, "function_body", false ) do
            -- get every variable_declaration RECURSIVE inside the function body
            for function_variable_declaration_node in NodeOfType( function_body_node, "variable_declaration", true ) do
                for function_variable_node in NodeOfType( function_variable_declaration_node, "variable", false ) do
                    if function_variable_node[ 1 ] == variable_node[ 1 ] then
                        return true
                    end
                end
            end
        end
        return false
    end

    for variable_declaration_node, variable_declaration_node_index in InverseNodeOfType( self.ast_node, "variable_declaration", false ) do
        local declaration_is_empty = true

        for variable_node, variable_index in InverseNodeOfType( variable_declaration_node, "variable", false ) do
            local variable_is_valid = false

            for function_node in NodeOfType( self.ast_node, "function", false ) do
                if find_redeclared_variable_in_function( function_node, variable_node ) == false then
                    if BruteForceFindValue( function_node, variable_node[ 1 ] ) then
                        variable_is_valid = true
                        break
                    end
                end
            end

            if variable_is_valid then
                declaration_is_empty = false
            else
                table.remove( variable_declaration_node, variable_index )
            end
        end

        if declaration_is_empty then
            table.remove( self.ast_node, variable_declaration_node_index )
        end
    end
end

function ConstantsOptimizer:UpdateConstantsWithReplacements()
    for constant_replacement_name, constant_replacement_value in pairs( self.constants_replacement ) do
        if not self.constants[ constant_replacement_name ] then
            error( "The constant replacement " .. constant_replacement_name .. " does not match a constant declaration in the shader", 1 )
        end

        self.constants[ constant_replacement_name ].value = constant_replacement_value
    end
end