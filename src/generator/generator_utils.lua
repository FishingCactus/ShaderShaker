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