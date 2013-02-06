
local node_rewrite_table =
{
    ['unary_!'] = ast_rewrite_unary_not_rules,
    ['if_block'] = ast_rewrite_if_block_rules,
    ['else_if_block'] = ast_rewrite_else_if_block_rules,
    [ '*' ] = ast_rewrite_multiplication_rules,
    [ '+' ] = ast_rewrite_addition_rules,
    [ '&&' ] = ast_rewrite_boolean_and_rules,
    [ '||' ] = ast_rewrite_boolean_or_rules,
}

local function rewrite_node( node, parent, index )
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

function AST_Rewrite( parent_node )
    WalkTree( parent_node, rewrite_node )
end
