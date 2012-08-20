

extern "C"
{
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}

#include <iostream>
#include <vector>
#include <algorithm>
#include "HLSLConverter.h"
#include "ShaderShaker.h"

struct ShaderShakerContext
{
    lua_State
        * L;
};

// Embedded scripts ( found in scripts.cpp )
extern const char* builtin_scripts[];

static const char
    * LocalInputFile = 0,
    * LocalOutputFile = 0,
    * LocalLanguage = 0;

static bool load_builtin_scripts(lua_State* L, const char * output_file, const char * language);

#ifndef SHADERSHAKER_IN_DLL

    static bool load_shader_file(lua_State* L, const char * shader_file_name );
    static bool process_command_line( int argc, const char ** argv, std::vector<std::string> & flag_table );
    static void usage();

    int main(int argc, const char** argv)
    {
        ShaderShakerContext
            * context;
        int
            return_value;
        std::vector<std::string>
            flag_table;

        if( argc < 2 || !process_command_line( argc, argv, flag_table ) )
        {
            usage();
            return_value = -1;
        }
        else
        {
            bool
                result;

            if( LocalOutputFile ) 
            {
                context = ShaderShakerCreateContext( LocalOutputFile );
            }
            else
            {
                context = ShaderShakerCreateContextWithLanguage( LocalLanguage );
            }

            if( !context )
            {
                std::cerr << "Unable to load scripts\n";
                return_value = -1;
            }
            else
            {
                for( std::vector<std::string>::const_iterator it = flag_table.begin(), end = flag_table.end(); it != end; ++it )
                {
                    ShaderShakerSetFlag( context, (*it).c_str(), true );
                }

                result = context && load_shader_file( context->L, LocalInputFile );

                return_value = result ? 0 : 1;
            }

            ShaderShakerDestroyContext( context );
        }
    

        return return_value;

    }

    static bool process_command_line( int argument_count, const char ** argument_table, std::vector<std::string> & flag_table )
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
                
                    case 'x':
                    {
                        if( argument[ 2 ] != 0 )
                        {
                            return false;
                        }
                        else if( LocalLanguage != 0 )
                        {
                            std::cerr << "Two languages given, aborting\n";
                            return false;
                        }
                        else if( argument_index == ( argument_count - 1 ) 
                            ||  argument_table[ argument_index + 1 ][ 0 ] == '-' 
                            )
                        {
                            std::cerr << "No language given after '-x', aborting\n\n";
                            return false;
                        }
                    
                        LocalLanguage = argument_table[ argument_index + 1 ];
                        ++argument_index;
                    }
                    break;
                
                    case '-':
                    {
                        flag_table.push_back( argument + 1 );
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

#endif

ShaderShakerContext * ShaderShakerCreateContext( const char * output_file )
{
    ShaderShakerContext
        * context;

    context = new ShaderShakerContext;
        
    context->L = luaL_newstate();
    luaL_openlibs( context->L );
    lua_pushcfunction( context->L, &HLSLConverter::ConvertHLSLToSSL );
    lua_setglobal( context->L, "ConvertHLSLToSSL" );

    if( load_builtin_scripts( context->L, output_file, 0 ) )
    {
        return context;
    }
    else
    {
        delete context;
        return 0;
    }

}

ShaderShakerContext * ShaderShakerCreateContextWithLanguage( const char * language )
{
    ShaderShakerContext
        * context;

    context = new ShaderShakerContext;

    context->L = luaL_newstate();
    luaL_openlibs( context->L );
    lua_pushcfunction( context->L, &HLSLConverter::ConvertHLSLToSSL );
    lua_setglobal( context->L, "ConvertHLSLToSSL" );

    if( load_builtin_scripts( context->L, 0, language ) )
    {
        return context;
    }
    else
    {
        delete context;
        return 0;
    }

}

void ShaderShakerDestroyContext( ShaderShakerContext * context )
{
    lua_close( context->L );
}

void ShaderShakerSetFlag( ShaderShakerContext * context, const char * flag, bool value )
{
    lua_pushboolean( context->L, value );
    lua_setglobal( context->L, flag );
}

bool load_shader_file(lua_State* L, const char * shader_file_name )
{
    lua_getglobal(L, "_shaker_shaker_load_shader_file");
    lua_pushstring( L, shader_file_name );
    
    if (lua_pcall(L, 1, 1, 0) != 0)
    {
        std::cerr << lua_tostring(L, -1);
        return false;
    }
    else
    {
        if( lua_isstring( L, -1 ) && !lua_isnumber( L, -1 ) )
        {
            std::cerr << lua_tostring( L, -1 ) << std::endl;
            return false;
        }
        
        return true;
    }
}

#if defined(_DEBUG)
/**
 * When running in debug mode, the scripts are loaded from the disk. 
 */
bool load_builtin_scripts(lua_State* L, const char * output_file, const char * local_language )
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
    
    if( output_file )
    {
        lua_pushstring( L, output_file );
    }
    else
    {
        lua_pushnil( L );
    }
    
    if( local_language )
    {
        lua_pushstring( L, local_language );
    }
    else
    {
        lua_pushnil( L );
    }
    
    if (lua_pcall(L, 3, 1, 0) != 0)
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
    lua_getglobal(L, "_shader_shaker_main");
    lua_pushnil( L );
    
    if( LocalOutputFile )
    {
        lua_pushstring( L, LocalOutputFile );
    }
    else
    {
        lua_pushnil( L );
    }
    
    if( LocalLanguage )
    {
        lua_pushstring( L, LocalLanguage );
    }
    else
    {
        lua_pushnil( L );
    }
    
    if (lua_pcall(L, 3, 1, 0) != 0)
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