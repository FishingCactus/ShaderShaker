
function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  if type(tbl) ~= "table" then error( "table expected", 2 ) end
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

function table.val_to_str_ast( v, indentation )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return string.rep( "    ", indentation ).. "'" .. v .. "'"
    end
    return string.rep( "    ", indentation ).. '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring_ast( v, indentation ) or
      tostring( v )
  end
end

function table.tostring_ast( ast, indentation )
  local result, done = {}, {}
  indentation = indentation or 0

  if type(ast) ~= "table" then error( "table expected", 2 ) end
  for k, v in ipairs( ast ) do
    table.insert( result, table.val_to_str_ast( v, indentation + 1 ) )
    done[ k ] = true
  end
  for k, v in pairs( ast ) do
    if not done[ k ] and k ~= "name" then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str_ast( v, indentation + 1 ) )
    end
  end
  local prefix = string.rep( "    ", indentation )
  
  if #result == 0 then
    return prefix .. ( ast.name or "" ) .. "{}"
  elseif #result == 1 and string.find(result[1], '\n') == nil then
    return prefix .. ( ast.name or "" ) .. "{" .. string.sub(result[1], (indentation+1)
     * 4 + 1) .. "}"
  else
    return prefix .. ( ast.name or "" ) .. "\n"
        .. prefix .. "{\n" 
        .. table.concat( result, ",\n" ) .. "\n" 
        .. prefix .. "}"  
  end
end