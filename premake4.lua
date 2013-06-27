newoption
{
    trigger = "ios",
    description = "generates ios project without native target"
}

--
-- ShaderShaker build configuration script (heavily inspired by Premake's one)
--

--
-- Define the project. Put the release configuration first so it will be the
-- default when folks build using the makefile. That way they don't have to
-- worry about the /scripts argument and all that.
--

    solution "ShaderShaker"
        configurations { "Release", "Debug", "DebugWithEmbeddedScripts" }
        location ( _OPTIONS["to"] )

        if _OPTIONS[ "lua51" ] then
            lua_version = "5.1.5"
            excluded_lua_version = "5.2.0"
        else
            lua_version = "5.2.0"
            excluded_lua_version = "5.1.5"
        end

        targetname  "shader_shaker"
        language    "C++"
        kind        "ConsoleApp"
        flags       { "No64BitChecks", "ExtraWarnings" }
        includedirs { "include", "src/host/lua-" .. lua_version .. "/src", "contrib", "src/hlsl_parser" }

        files
        {
            "*.txt", "**.lua",
            "src/**.h", "src/**.cpp", "src/**.c",
            "src/host/scripts.cpp"
        }

        excludes
        {
            "src/host/lua-" .. lua_version .. "/src/lua.c",
            "src/host/lua-" .. lua_version .. "/src/luac.c",
            "src/host/lua-" .. lua_version .. "/src/print.c",
            "src/host/lua-" .. lua_version .. "/**.lua",
            "src/host/lua-" .. lua_version .. "/etc/*.c",
            "src/host/lua-" .. excluded_lua_version .."/**"
        }

        if _OPTIONS[ "ios" ] then
            platforms { "ios" }

            if deploymenttarget then
                deploymenttarget "5.1"
            end

        end

        configuration "Debug"
            defines     { "_DEBUG" }
            flags       { "Symbols" }

        configuration "DebugWithEmbeddedScripts"
            defines     { "_DEBUG", "SHADERSHAKER_EMBEDDED_SCRIPTS" }
            flags       { "Symbols" }

        configuration "Release"
            defines     { "NDEBUG", "SHADERSHAKER_EMBEDDED_SCRIPTS" }
            flags       { "OptimizeSize" }

        configuration "vs*"
            defines     { "_CRT_SECURE_NO_WARNINGS" }

        configuration "vs2005"
            defines {"_CRT_SECURE_NO_DEPRECATE" }

        configuration "windows"
            links { "ole32" }

        configuration "linux"
            defines     { "LUA_USE_POSIX", "LUA_USE_DLOPEN" }
            links       { "m", "dl" }

        configuration "bsd"
            defines     { "LUA_USE_POSIX", "LUA_USE_DLOPEN" }
            links       { "m" }

        configuration "macosx"
            defines     { "LUA_USE_MACOSX" }
            links       { "CoreServices.framework" }

        configuration { "macosx", "gmake" }
            buildoptions { "-mmacosx-version-min=10.4" }
            linkoptions  { "-mmacosx-version-min=10.4" }

        configuration { "linux", "bsd", "macosx" }
            linkoptions { "-rdynamic" }

        configuration { "solaris" }
            linkoptions { "-Wl,--export-dynamic" }

    project "ShaderShaker"

        configuration "Debug"
            targetdir   "bin/debug"

        configuration "DebugWithEmbeddedScripts"
            targetdir   "bin/debug"

        configuration "Release"
            targetdir   "bin/release"

    project "ShaderShakerDll"
        defines{ "SHADERSHAKER_IN_DLL" }

        configuration "Debug"
            kind "SharedLib"
            targetdir   "bin/debug_dll"

        configuration "DebugWithEmbeddedScripts"
            kind "SharedLib"
            targetdir   "bin/debug_dll"

        configuration "Release"
            kind "SharedLib"
            targetdir   "bin/release_dll"

    project "ShaderShakerLib"

        defines{ "SHADERSHAKER_IN_LIB" }

        configuration "Debug"
            kind "StaticLib"
            targetdir   "bin/debug_lib"

        configuration "DebugWithEmbeddedScripts"
            kind "StaticLib"
            targetdir   "bin/debug_lib"

        configuration "Release"
            kind "StaticLib"
            targetdir   "bin/release_lib"

--
-- A more thorough cleanup.
--

    if _ACTION == "clean" then
        os.rmdir("bin")
        os.rmdir("build")
    end

--
-- Use the --to=path option to control where the project files get generated. I use
-- this to create project files for each supported toolset, each in their own folder,
-- in preparation for deployment.
--

    newoption {
        trigger = "to",
        value   = "path",
        description = "Set the output location for the generated files"
    }

--
-- Use lua 5.1 (instead of 5.2 by default).
-- This is useful for debugging using decoda (https://github.com/unknownworlds/decoda).
--

    newoption
    {
        trigger = "lua51",
        description = "Use lua 5.1 (handy for using decoda)"
    }



--
-- Use the embed action to convert all of the Lua scripts into C strings, which
-- can then be built into the executable. Always embed the scripts before creating
-- a release build.
--

    dofile("scripts/embed.lua")

    newaction {
        trigger     = "embed",
        description = "Embed scripts in scripts.cpp; required before release builds",
        execute     = doembed
    }