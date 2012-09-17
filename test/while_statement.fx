int test( float a, bool b, int c )
{
    int
        index;
    bool
        result;
        
    do
    {
        a -= 1.0;
        
        result = a < 0.0;
    }
    while( result );
    
    while( index < c )
    {
        ++index;
    }

    return 0;
}