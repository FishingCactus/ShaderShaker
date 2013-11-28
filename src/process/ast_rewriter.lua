AstRewriter = {
}

function AstRewriter:new()
    local instance = {}
    setmetatable( instance, self )
    self.__index = self
    return instance
end

function AstRewriter:Process( parent_node )
    local node_rewrite_table =
    {
        ['unary_!'] = ast_rewrite_unary_not_rules,
        ['if_block'] = ast_rewrite_if_block_rules,
        ['else_if_block'] = ast_rewrite_else_if_block_rules,
        [ '*' ] = ast_rewrite_multiplication_rules,
        [ '+' ] = ast_rewrite_addition_rules,
        [ '&&' ] = ast_rewrite_boolean_and_rules,
        [ '||' ] = ast_rewrite_boolean_or_rules,
        [ '<' ] = ast_rewrite_less_rules,
        [ '<=' ] = ast_rewrite_less_than_rules,
        [ '>' ] = ast_rewrite_greater_rules,
        [ '>=' ] = ast_rewrite_greater_than_rules,
    }

    local rewrite_node = function( node, parent, index )
        local it_has_changed = false

        if node == nil then
            -- Tricky: Rewrite might delete next node and for does not reevaluate
            return
        end

        repeat
            local rewrite_table = node_rewrite_table[ node.name ]

            if rewrite_table == nil then
                return
            end

            local function evaluate()
                for _, predicate_action in pairs( rewrite_table ) do
                    if ( predicate_action[1] )( node ) == true then
                        ( predicate_action[2] )( node, parent, index )
                        return true
                    end
                end
                return false
            end

            it_has_changed = evaluate()

        until it_has_changed == false or node ~= parent[ index ]
    end

    WalkTree( parent_node, rewrite_node )
end
