#if !defined( SHADERSHAKER_AS_SOURCE )
extern "C"
{
#endif
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
#if !defined( SHADERSHAKER_AS_SOURCE )
}
#endif

#include <iostream>
#include <vector>
#include <algorithm>
#include <cstring>
#include <cstdio>
#include "HLSLConverter.h"
#include "ShaderShaker.h"

struct ShaderShakerContext
{
    lua_State
        * L;
};

// Embedded scripts ( found in scripts.cpp )
extern const char* builtin_scripts[];
void ( *log_print_callback )( const char * ) = NULL;
void ( *read_file_content_callback )( void * content, size_t & size, const char * ) = NULL;

static bool load_builtin_scripts(lua_State* L, int argc, const char* const * argv );

#if !defined( SHADERSHAKER_IN_DLL ) && !defined( SHADERSHAKER_IN_LIB ) && !defined( SHADERSHAKER_AS_SOURCE )

    static void log( const char * msg )
    {
        printf( msg );
    }

    int main(int argc, const char** argv)
    {
        ShaderShakerContext
            * context;
        bool
            result;

        ShaderShakerSetLogCallback( log );

        context = ShaderShakerCreateContext( argc, argv );

        if( !context )
        {
            if ( log_print_callback )
            {
                log_print_callback( "Unable to load scripts\n" );
            }
            return -1;
        }
        else
        {
            result = ShaderShakerLoadShaderFile( context );
            ShaderShakerDestroyContext( context );

            return result ? 0 : 1;
        }
    }

#endif

void ShaderShakerSetLogCallback( void ( *log_print )( const char * ) )
{
    log_print_callback = log_print;
}

void ShaderShakerSetReadFileContentCallback( void ( *read_file_content )( void * content, size_t & size, const char * ) )
{
    read_file_content_callback = read_file_content;
}

ShaderShakerContext * ShaderShakerCreateContext( int argc, const char* const * argv )
{
    ShaderShakerContext
        * context;

    context = new ShaderShakerContext;

    context->L = luaL_newstate();
    luaL_openlibs( context->L );
    lua_pushcfunction( context->L, &HLSLConverter::ParseAst );
    lua_setglobal( context->L, "ParseHLSL" );

    if( load_builtin_scripts( context->L, argc, argv ) )
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

bool ShaderShakerLoadShaderFile( ShaderShakerContext * context )
{
    lua_getglobal( context->L, "_shaker_shaker_process_files");

    if ( lua_pcall( context->L, 0, 1, 0 ) != 0 )
    {
        if ( log_print_callback )
        {
            log_print_callback( lua_tostring( context->L, -1 ) );
        }
        return false;
    }
    else
    {
        if( lua_isstring( context->L, -1 ) && !lua_isnumber( context->L, -1 ) )
        {
            if ( log_print_callback )
            {
                log_print_callback( lua_tostring( context->L, -1 ) );
            }
            return false;
        }

        return true;
    }
}

// ~~

const char * ShaderShakerGetProcessedCode( ShaderShakerContext * context, int file_index )
{
    const char * code;
    lua_getglobal( context->L, "CodeOutput" );
    lua_rawgeti( context->L, -1, file_index + 1 );
    lua_pushstring( context->L, "text" );
    lua_rawget( context->L, -2 );
    code = lua_tostring( context->L, -1 );
    lua_pop( context->L, 3 );

    return code;
}

#if defined( SHADERSHAKER_EMBEDDED_SCRIPTS )
/**
 * The scripts are loaded from a static data buffer, where they were stored by a preprocess.
 * To update these embedded scripts, run `premake4 embed` then rebuild.
 */
bool load_builtin_scripts(lua_State* L, int argc, const char* const * argv )
{
    int i;
    for (i = 0; builtin_scripts[i]; ++i)
    {
        if (luaL_dostring(L, builtin_scripts[i]) != 0 )
        {
            if ( log_print_callback )
            {
                log_print_callback( lua_tostring( L, -1 ) );
            }

            return false;
        }
    }

    lua_getglobal( L, "_shader_shaker_main" );

    lua_pushnil( L );
    lua_newtable( L );

    for ( int i = 1; i < argc; i++ )
    {
        const char
        * argument;

        argument = argv[ i ];

        lua_pushstring( L, argument );
        lua_rawseti( L, -2, i );
    }

    if (lua_pcall(L, 2, 0, 0) != 0)
    {
        if ( log_print_callback )
        {
            log_print_callback( lua_tostring( L, -1 ) );
        }
        return false;
    }
    else
    {
        return true;
    }
}
#else
/*
 * The scripts are loaded from the disk.
 */
bool load_builtin_scripts(lua_State* L, int argc, const char* const * argv )
{
    char
    source_path[ 1024 ],
    filename[ 1024 ];

    strcpy( source_path,  "" );

    for ( int i = 1; i < argc; i++ )
    {
        const char
        * argument;

        argument = argv[ i ];

        if ( strcmp( argument, "-source_directory" ) == 0 )
        {
            strcat( source_path, argv[ i + 1 ] );
            break;
        }
    }

    strcat( source_path, "src" );

    strcpy( filename, source_path );
    strcat( filename, "/_shader_shaker_main.lua" );

    if ( luaL_dofile( L, filename ) )
    {
        if ( log_print_callback )
        {
            log_print_callback( lua_tostring( L, -1 ) );
        }
        return false;
    }

    lua_getglobal( L, "_shader_shaker_main" );

    lua_pushstring( L, source_path );

    lua_newtable( L );

    for ( int i = 1; i < argc; i++ )
    {
        const char
        * argument;

        argument = argv[ i ];

        lua_pushstring( L, argument );
        lua_rawseti( L, -2, i );
    }

    if ( lua_pcall( L, 2, 1, 0 ) != 0 )
    {
        if ( log_print_callback )
        {
            log_print_callback( lua_tostring( L, -1 ) );
        }
        return false;
    }
    else
    {
        return lua_tonumber( L, -1 ) == 0;
    }
}
#endif
