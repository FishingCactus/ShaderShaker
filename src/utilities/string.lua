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