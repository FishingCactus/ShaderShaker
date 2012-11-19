function predicate_and( ... )
    local function_table = {...}
    return function( node )
        for _, func in ipairs( function_table ) do 
            if func( node ) == false then return false end
        end
        return true;
    end
end

local function if_block_( type, value )
	return function( node )
		assert( node.name == 'if' )
		
		return node[ 1 ][ 1 ].name == type and node[ 1 ][ 1 ][ 1 ] == value
	end
end

local function remove_if_block( node, parent, index )  
    parent[index].name = "nop"
    parent[index][1] =  nil
end

local function validate_if_block( node, parent, index )
    parent[index] = node[ 1 ][ 2 ]
end

local function keep_else_block( node, parent, index )
    parent[index] = node[ 2 ][ 1 ]
end

local function replace_else_if_block( node, parent, index )
    table.remove( node, 1 );
    node[ 1 ].name = "if_block"
end

local function if_has_no_else( node )
    assert( node.name == 'if' )
    return node[ 2 ] == nil or node[ 2 ].name ~= "else_block"
end

local function if_has_else( node )
    assert( node.name == 'if' )
    return node[ 2 ] ~= nil and node[ 2 ].name == "else_block"
end

local function if_has_else_if( node )
    assert( node.name == 'if' )
	return node[ 2 ] ~= nil and node[ 2 ].name == "else_if_block"
end


ast_rewrite_if_rules =
{
    {if_block_( "variable" , "true" ), validate_if_block},
    {predicate_and( if_block_( "variable" , "false" ), if_has_else_if ), replace_else_if_block },
    {predicate_and( if_block_( "variable" , "false" ), if_has_else ), keep_else_block },
    {predicate_and( if_block_( "variable" , "false" ), if_has_no_else ), remove_if_block },

    {if_block_( "literal" , "1" ),   validate_if_block },
    
    {predicate_and( if_block_( "literal" , "0" ), if_has_else_if ), replace_if_block },
    {predicate_and( if_block_( "literal" , "0" ), if_has_else ), keep_else_block },
    {predicate_and( if_block_( "literal" , "0" ), if_has_no_else ), remove_if_block },
    
    {predicate_and( if_block_( "literal" , "false" ), if_has_else_if ), replace_else_if_block },
    {predicate_and( if_block_( "literal" , "false" ), if_has_no_else ), remove_if_block },
    {predicate_and( if_block_( "literal" , "false" ), if_has_else ), keep_else_block },
    
    {if_block_( "literal" , "true" ),  validate_if_block},
}