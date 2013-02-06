float test_function(
    float a,
    int b, 
    float c
    )
{
    const float d = 1.0;
    const float e = 2.0;
    const float f = 3.0;
    return ( a * b + c - ( d + e ) / f * 0.5 ) / ( 2.0 * e );
}