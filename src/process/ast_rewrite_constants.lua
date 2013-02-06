
local function if_literal_zero( index )
	return function( node )
        local node_value = node[ index ][ 1 ];

        return node[ index ].name == "literal" and 
            ( node_value == "0" or node_value == "0.0" or node_value == "0.0f" )
	end
end

local function if_literal_one( index )
    return function( node )
        local node_value = node[ index ][ 1 ];

        return node[ index ].name == "literal" and 
            ( node_value == "1" or node_value == "1.0" or node_value == "1.0f" )
    end
end

local function replace_by_right_block( node, parent, index ) 
    parent[ index ] = node[ 2 ]
end

local function replace_by_left_block( node, parent, index ) 
    parent[ index ] = node[ 1 ]
end


ast_rewrite_multiplication_rules =
{
    {if_literal_zero( 1 ), replace_by_left_block},
    {if_literal_zero( 2 ), replace_by_right_block},
    {if_literal_one( 1 ), replace_by_right_block},
    {if_literal_one( 2 ), replace_by_left_block}
}