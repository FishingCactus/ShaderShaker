
local function if_argument_literal( node )
    return node[ 1 ].name == "literal" and node[ 2 ].name == "literal"
        and tonumber( node[ 1 ][ 1 ] ) ~= nil and tonumber( node[ 2 ][ 1 ] ) ~= nil
end

local function replace_by_result( operator )

    local ls = loadstring or load

    return function( node, parent, index )

        local value = assert( ls( 'return ' .. node[ 1 ][ 1 ] .. operator .. node[ 2 ][ 1 ] ) )()

        parent[ index ] = { name = 'literal', [ 1 ] = tostring( value ) }
    end
end

ast_rewrite_less_rules =
{
    {if_argument_literal, replace_by_result( '<') },
}

ast_rewrite_less_than_rules =
{
    {if_argument_literal, replace_by_result( '<=' )},
}

ast_rewrite_greater_rules =
{
    {if_argument_literal, replace_by_result( '>' ) },
}

ast_rewrite_greater_than_rules =
{
    {if_argument_literal, replace_by_result( '>=')},
}


