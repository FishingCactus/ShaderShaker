bool ItUsesVertexSkinning = false;
bool ItUsesDiffuseColor = false;

bool test(
    float a,
    float x
    )
{
    if( ItUsesVertexSkinning )
    {
        int i = 0;
    }
    
    if( !ItUsesVertexSkinning )
    {
        int i = 9;
    }
    
    if( ItUsesVertexSkinning )
    {
        int i = 1;
    }
    else
    {
        int i = 2;
    }

    if( !ItUsesVertexSkinning )
    {
        int i = 3;
    }
    else
    {
        int i = 4;
    }

    if( !ItUsesVertexSkinning )
    {
        int i = 6;
    }
    else if ( !ItUsesDiffuseColor )
    {
        int i = 7;
    }
    else
    {
        int i = 8;
    }
    
    return true;
}