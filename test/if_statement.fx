bool test(
    float a,
    float x
    )
{
    if( a == x )
        return false;
        
    if( a < x || a > x )
    {
        return true;
    }
    
    if( a + x > 10.0f )
    {
        return x + a <= 23.35f;
    }
    else if( a - x < 5.0f )
    {
        return a >= x;
    }
    else
    {
        return a != x;
    }
}