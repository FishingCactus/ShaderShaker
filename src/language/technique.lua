
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


function technique( technique_definition )

	local language_printer = HLSL;
	local representation = AstToIR( technique_definition.vs );

	language_printer.PrintFunctionPrologue( representation, technique_definition.name .. "_vs" )
	language_printer.PrintCode( representation )
	language_printer.PrintFunctionEpilogue( representation )
	
	representation = AstToIR( technique_definition.ps );
		
	language_printer.PrintFunctionPrologue( representation, technique_definition.name .. "_ps" )
	language_printer.PrintCode( representation )
	language_printer.PrintFunctionEpilogue( representation )
	
	language_printer.PrintTechnique( technique_definition.name, technique_definition.name .. "_vs", technique_definition.name .. "_ps" )
	
end