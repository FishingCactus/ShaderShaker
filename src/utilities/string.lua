function isboolean( string )
    return string == "true" or string == "false"
end

function toboolean( string )
    if isboolean( string ) then
        return string == "true"
    end
    
    return nil
end