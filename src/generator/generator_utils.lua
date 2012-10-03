local OperatorPrecedence = {
    
    ['/'] = 1,
    ['%'] = 1,
    ['*'] = 2,
    ['+'] = 3,
    ['-'] = 3,
    ['>>'] = 4,
    ['<<'] = 4,
    ['>'] = 5,
    ['<'] = 5,
    ['>='] = 5,
    ['<='] = 5,
    ['=='] = 6,
    ['!='] = 6,
    ['&'] = 7,
    ['^'] = 8,
    ['|'] = 9,
    ['&&'] = 11,
    ['||'] = 12,
}


function GetOperatorPrecedence( operator )

    return OperatorPrecedence[ operator ] or 0
end

function GetDataByName( node, name, recursive )
    if node.name and node.name == name then
        return node[ 1 ];
    else
        if type( node ) == "table" then
            for _, child_node in ipairs( node ) do
                if child_node.name and child_node.name == name then
                    return child_node[ 1 ];
                end
                
                if recursive then
                    local
                        result;
                 
                    result = GetDataByName( child_node, name, recursive );
                        
                    if result then
                        return result;
                    end
                end
            end
        end
    end
    
    return nil;
end

function GetCountOfType( node, type_name, recursive )
    local
        count;
        
    count = 0;
    
    if type( node ) == "table" then
        for _, child_node in ipairs( node ) do
            if child_node.name and child_node.name == type_name then
                count = count + 1;
            end
            
            if recursive then
                count = count + GetCountOfType( child_node, type_name, resursive );
            end
        end
    end
    
    return count;
end

function BruteForceFindValue( node, value )
    if type( node ) == "table" then
        for k, child_node in pairs( node ) do
            if child_node == value then
                return true;
            else
                if child_node then
                    if BruteForceFindValue( child_node, value ) then
                        return true;
                    end
                end
            end
        end
    else
        return node == value;
    end
    
    return false;
end

local function _GetNodeOfType( node, type_name, recursive )
    local yield = coroutine.yield
    
    for index, child_node in ipairs( node ) do
        local
            child_node = node[ index ]
            
        if type( child_node ) == 'table' then        
            if child_node.name == type_name then
                yield( child_node, index, node )
            end
            
            if recursive then
                _GetNodeOfType( child_node, type_name, recursive )
            end
        end
    end
end
 
function NodeOfType( node, type_name, recursive )
    if recursive == nil then
        recursive = true
    end
    
    return coroutine.wrap(function() _GetNodeOfType( node, type_name, recursive ) end)
end

local function _GetInverseNodeOfType( node, type_name, recursive )
    local yield = coroutine.yield
    
    for index=#node, 1, -1 do
        local
            child_node = node[ index ]
            
        if type( child_node ) == 'table' then        
            if child_node.name == type_name then
                yield( child_node, index, node )
            end
            
            if recursive then
                _GetInverseNodeOfType( child_node, type_name, recursive )
            end
        end
        
    end
    
    
end
 
function InverseNodeOfType( node, type_name, recursive )
    if recursive == nil then
        recursive = true;
    end
    
    return coroutine.wrap(function() _GetInverseNodeOfType( node, type_name, recursive ) end)
end

function GenerateAstFromFileName( file_name )
    local
        ast;
    local
        extension = string.match( file_name, "%w+%.(%w+)" )
    
    if extension == "lua" or extension == "ssl" then
        ast = dofile( file_name )
    elseif extension == "fx" then
            
        ast = ParseHLSL( file_name )
        
        if ast == nil then
            error( "Fail to load hlsl code from " .. file_name );
        end
    else
        error( "Unsupported file extension while trying to load " .. file_name );
    end
    
    return ast;
end
