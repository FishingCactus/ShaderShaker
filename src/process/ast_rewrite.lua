local function is_not_( value )
    return function( node )
        assert( node.name == 'unary_!' )
        return node[ 1 ].name == 'literal' and node[1][1] == value
    end
end

local function replace_by_( value )
    return function( node, parent, index )    
        parent[ index ] = { name ='literal', [1] = value }
    end
end

local node_rewrite_table=
{
    ['unary_!'] = {
        [is_not_( "1" )] = replace_by_( "0" ),
        [is_not_( "0" )] = replace_by_( "1" )
    }
}

local function rewrite_node( node, parent, index )
    local rewrite_table = node_rewrite_table[ node.name ]
    
    if rewrite_table == nil then
        return
    end
    
    for predicate, action in pairs( rewrite_table ) do
        if predicate( node ) then
            action( node, parent, index )
        end
    end
end

function AST_Rewrite( parent_node )
    WalkTree( parent_node, rewrite_node )
end
