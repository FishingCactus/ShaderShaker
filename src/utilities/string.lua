function isboolean( string )
    return string == "true" or string == "false"
end

function toboolean( string )
    if isboolean( string ) then
        return string == "true"
    end

    return nil
end

function string.starts( String,Start )
   return string.sub( String, 1, string.len( Start ) ) ==Start
end

function string.ends( String, End )
   return End == '' or string.sub( String,-string.len( End ) ) == End
end

function string.explode( str, delimiter )
    if ( delimiter == '' ) then
        return false
    end

    local pos,arr = 0,{}

    for st,sp in function() return string.find( str, delimiter, pos, true) end do
        table.insert( arr,string.sub( str,pos,st-1 ) )
        pos = sp + 1
    end

    table.insert( arr,string.sub( str,pos ) )

    return arr
end