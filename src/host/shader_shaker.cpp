

extern "C"
{
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}

#include <iostream>

// Embedded scripts ( found in scripts.cpp )
extern const char* builtin_scripts[];

static const char
    * LocalInputFile = 0,
    * LocalOutputFile = 0;

static bool process_command_line( lua_State * L, int argc, const char ** argv );
static void usage();
static bool load_shader_file(lua_State* L, const char * shader_file_name );
static bool load_builtin_scripts(lua_State* L);

int main(int argc, const char** argv)
{
    lua_State* L;
    bool result;
    
    L = luaL_newstate();
    luaL_openlibs(L);

    if( argc < 2 || !process_command_line( L, argc, argv ) )
    {
        usage();
        lua_close( L );
        return -1;
    }
    
	result = load_builtin_scripts(L);
    result = result && load_shader_file( L, argv[ 1 ] );
    

	lua_close(L);
	return result ? 0 : 1;
}


static bool process_command_line( lua_State * L, int argument_count, const char ** argument_table )
{
    for(int argument_index = 1; argument_index < argument_count; ++argument_index )
    {
        const char
            * argument;
            
        argument = argument_table[ argument_index ];
        
        if( argument[ 0 ] == '-' )
        {
            //Process options
            
            switch ( argument[ 1 ] )
            {
                case 'o':
                {
                    if( argument[ 2 ] != 0 )
                    {
                        return false;
                    }
                    else if( LocalOutputFile != 0 )
                    {
                        std::cerr << "Two output file given, aborting\n";
                        return false;
                    }
                    else if( argument_index == ( argument_count - 1 ) 
                        ||  argument_table[ argument_index + 1 ][ 0 ] == '-' 
                        )
                    {
                        std::cerr << "No output file given after '-o', aborting\n\n";
                        return false;
                    }
                    
                    LocalOutputFile = argument_table[ argument_index + 1 ];
                    ++argument_index;
                }
                break;
                
                case '-':
                {
                    lua_pushboolean( L, true );
                    lua_setglobal( L, argument + 1 );
                }
                break;

                default:
                    break;
            }
        }
        else
        {
            if( LocalInputFile )
            {
                std::cerr << "Two input files given, aborting\n\n";
                return false;
            }
            
            LocalInputFile = argument_table[ argument_index ];
        }
    }

    return true;
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
    int
        argument_count;
        
    //:TODO: option to change scripts directory
    filename = "src/_shader_shaker_main.lua";

	if (luaL_dofile(L, filename))
	{
		std::cerr << lua_tostring(L, -1);
		return false;
	}

	lua_getglobal(L, "_shader_shaker_main");
    lua_pushstring(L, "src" );
    argument_count = 1;
    if( LocalOutputFile )
    {
        lua_pushstring( L, LocalOutputFile );
        ++argument_count;
    }
    
	if (lua_pcall(L, argument_count, 1, 0) != 0)
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