float if_true( bool a )
{
	if( true )
	{
		return 1.0f;
	}
	else if( a )
	{
		return 2.0f;
	}
	else
	{
		return 3.0f;
	}
}

float else_if_true( bool a, bool b )
{
	if( a )
	{
		return 1.0f;
	}
	else if( true )
	{
		return 2.0f;
	}
	else if( b )
	{
		return 3.0f;
	}
	else
	{
		return 4.0f;
	}
}

float else_if_2_true( bool a, bool b )
{
	if( a )
	{
		return 1.0f;
	}
	else if( b )
	{
		return 2.0f;
	}
	else if( true )
	{
		return 3.0f;
	}
	else
	{
		return 4.0f;
	}
}

float if_false( bool a )
{
	if( false )
	{
		return 1.0f;
	}
	else if( a )
	{
		return 2.0f;
	}
	else
	{
		return 3.0f;
	}
}

float else_if_false( bool a, bool b )
{
	if( a )
	{
		return 1.0f;
	}
	else if( false )
	{
		return 2.0f;
	}
	else if( b )
	{
		return 3.0f;
	}
	else
	{
		return 4.0f;
	}
}

float else_if_2_false( bool a, bool b )
{
	if( a )
	{
		return 1.0f;
	}
	else if( b )
	{
		return 2.0f;
	}
	else if( false )
	{
		return 3.0f;
	}
	else
	{
		return 4.0f;
	}
}
