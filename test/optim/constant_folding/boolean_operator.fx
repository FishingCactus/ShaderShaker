bool and_false_r( bool a, bool b )
{
	return a && b && false;
}

bool and_false_r( bool a, bool b )
{
	return false && a && b;
}

bool and_false_m( bool a, bool b )
{
	return a && false && b;
}

bool and_true_r( bool a, bool b )
{
	return a && b && true;
}

bool and_true_r( bool a, bool b )
{
	return true && a && b;
}

bool and_true_m( bool a, bool b )
{
	return a && true && b;
}

bool or_false_r( bool a, bool b )
{
	return a || b || false;
}

bool or_false_r( bool a, bool b )
{
	return false || a || b;
}

bool or_false_m( bool a, bool b )
{
	return a || false || b;
}

bool or_true_r( bool a, bool b )
{
	return a || b || true;
}

bool or_true_r( bool a, bool b )
{
	return true || a || b;
}

bool or_true_m( bool a, bool b )
{
	return a || true || b;
}