

extern "C"
{
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}

#include <iostream>

// Embedded scripts ( found in scripts.cpp )
extern const char* builtin_scripts[];

static void usage();
static bool load_shader_file(lua_State* L, const char * shader_file_name );
static bool load_builtin_scripts(lua_State* L);

int main(int argc, const char** argv)
{
	lua_State* L;
    bool result;
    
    if( argc < 2 )
    {
        usage();
        return -1;
    }
	
	L = luaL_newstate();
	luaL_openlibs(L);	
    
	result = load_builtin_scripts(L);
    result = result && load_shader_file( L, argv[ 1 ] );
    

	lua_close(L);
	return result ? 0 : 1;
}

void usage()
{
    std::cout << "shader_shaker [options] shader_file_name" << std::endl;
}

bool load_shader_file(lua_State* L, const char * shader_file_name )
{
	if (luaL_dofile(L, shader_file_name))
	{
		std::cerr << lua_tostring(L, -1);
		return false;
	}

    return true;
}

#if defined(_DEBUG)
/**
 * When running in debug mode, the scripts are loaded from the disk. 
 */
bool load_builtin_scripts(lua_State* L)
{
	const char
        * filename;
        
    //:TODO: option to change scripts directory
    filename = "src/_shader_shaker_main.lua";

	if (luaL_dofile(L, filename))
	{
		std::cerr << lua_tostring(L, -1);
		return false;
	}

	lua_getglobal(L, "_shader_shaker_main");
    lua_pushstring(L, "src" );
    
	if (lua_pcall(L, 1, 1, 0) != 0)
	{
		std::cerr << lua_tostring(L, -1);
		return false;
	}
	else
	{
		return lua_tonumber(L, -1) == 0;
	}
}
#endif


#if defined(NDEBUG)
/**
 * When running in release mode, the scripts are loaded from a static data
 * buffer, where they were stored by a preprocess. To update these embedded
 * scripts, run `premake4 embed` then rebuild.
 */
bool load_builtin_scripts(lua_State* L)
{
	int i;
	for (i = 0; builtin_scripts[i]; ++i)
	{
		if (luaL_dostring(L, builtin_scripts[i]) != 0 )
		{
			std::cerr << lua_tostring(L, -1);
            
			return false;
		}
	}

	/* hand off control to the scripts */
	lua_getglobal(L, "_premake_main");
    
	if (lua_pcall(L, 0, 1, 0) != 0)
	{
		std::cerr << lua_tostring(L, -1);
		return false;
	}
	else
	{
		return lua_tonumber(L, -1) == 0;
	}
}
#endif