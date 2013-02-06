
local function if_block_( value )
	return function( node )
        return node[ 1 ].name == "literal" and node[ 1 ][ 1 ] == value
	end
end

local function keep_if_block( node, parent, index )
    assert( index == 1 )
    assert( node[ 2 ].name == "block" )

    while table.remove( parent ) ~= nil do end
    parent.name = "block"
    parent[ 1 ] = node[ 2 ][ 1 ];
end

local function transform_to_else_and_discard_following( node, parent, index )

    while #parent > index do
        table.remove( parent )
    end

    node.name = "else_block"
    table.remove( node, 1 )
end

local function discard_if( node, parent, index )
    assert( index == 1 )

    if #parent == 1 then
        table.remove( parent )
        parent.name = "nop"
    elseif parent[ 2 ].name == "else_block" then
        table.remove( parent )
        parent.name = "block"
        parent[ 1 ] = node[ 2 ][ 1 ];
    else 
        assert( parent[ 2 ].name == "else_if_block" )

        table.remove( parent, 1 )
        parent[ 1 ].name = "if_block"
    end
end

local function discard_block( node, parent, index )
    table.remove( parent, index )
end


ast_rewrite_if_block_rules =
{
    {if_block_( "true" ), keep_if_block},
    {if_block_( "false" ), discard_if},
}

ast_rewrite_else_if_block_rules =
{
    {if_block_( "true" ), transform_to_else_and_discard_following },
    {if_block_( "false" ), discard_block},
}
