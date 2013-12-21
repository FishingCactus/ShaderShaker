
local function if_literal_zero( index )
	return function( node )
        local node_value = node[ index ][ 1 ];

        return ( node[ index ].name == "int_literal" or node[ index ].name == "float_literal" )
            and ( node_value == "0" or node_value == "0.0" or node_value == "0.0f" )
	end
end

local function if_literal_one( index )
    return function( node )
        local node_value = node[ index ][ 1 ];

        return ( node[ index ].name == "int_literal" or node[ index ].name == "float_literal" )
            and ( node_value == "1" or node_value == "1.0" or node_value == "1.0f" )
    end
end

local function if_literal_true( index )
    return function( node )
        local node_value = node[ index ][ 1 ];

        return node[ index ].name == "bool_literal" and node_value == "true"
    end
end

local function if_literal_false( index )
    return function( node )
        local node_value = node[ index ][ 1 ];

        return node[ index ].name == "bool_literal" and node_value == "false"
    end
end

local function replace_by_right_block( node, parent, index )
    parent[ index ] = node[ 2 ]
end

local function replace_by_left_block( node, parent, index )
    parent[ index ] = node[ 1 ]
end

local function replace_by_( value )
    return function( node, parent, index )
        parent[ index ] = { name ='literal', [1] = value }
    end
end



ast_rewrite_multiplication_rules =
{
    {if_literal_zero( 1 ), replace_by_left_block},
    {if_literal_zero( 2 ), replace_by_right_block},
    {if_literal_one( 1 ), replace_by_right_block},
    {if_literal_one( 2 ), replace_by_left_block}
}

ast_rewrite_addition_rules =
{
    {if_literal_zero( 1 ), replace_by_right_block},
    {if_literal_zero( 2 ), replace_by_left_block},
}

ast_rewrite_boolean_and_rules =
{
    {if_literal_false( 1 ), replace_by_left_block},
    {if_literal_false( 2 ), replace_by_right_block},
    {if_literal_true( 1 ), replace_by_right_block},
    {if_literal_true( 2 ), replace_by_left_block},
}

ast_rewrite_boolean_or_rules =
{
    {if_literal_false( 1 ), replace_by_right_block},
    {if_literal_false( 2 ), replace_by_left_block},
    {if_literal_true( 1 ), replace_by_left_block},
    {if_literal_true( 2 ), replace_by_right_block},
}

ast_rewrite_unary_not_rules =
{
    {if_literal_zero( 1 ), replace_by_( "true" ) },
    {if_literal_false( 1 ), replace_by_( "true" ) },
    {if_literal_one( 1 ), replace_by_( "false" ) },
    {if_literal_true( 1 ), replace_by_( "false" ) }
}
