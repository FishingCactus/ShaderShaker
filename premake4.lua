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
		configurations { "Release", "Debug" }
		location ( _OPTIONS["to"] )

		targetname  "shader_shaker"
		language    "C++"
		kind        "ConsoleApp"
		flags       { "No64BitChecks", "ExtraWarnings" }
		includedirs { "include", "src/host/lua-5.2.0/src", "contrib", "src/hlsl_parser" }

		files
		{
			"*.txt", "**.lua",
			"src/**.h", "src/**.cpp", "src/**.c",
			"src/host/scripts.cpp"
		}

		excludes
		{
			"src/host/lua-5.2.0/src/lua.c",
			"src/host/lua-5.2.0/src/luac.c",
			"src/host/lua-5.2.0/src/print.c",
			"src/host/lua-5.2.0/**.lua",
			"src/host/lua-5.2.0/etc/*.c"
		}

		if _OPTIONS[ "ios" ] then
	        platforms { "ios" }
		end

		configuration "DebugWithoutEmbeddedScripts"
			defines     "_DEBUG"
			flags       { "Symbols" }

		configuration "Debug"
			defines		{ "_DEBUG", "SHADERSHAKER_EMBEDDED_SCRIPTS" }
			flags       { "Symbols" }

		configuration "Release"
			defines     { "NDEBUG", "SHADERSHAKER_EMBEDDED_SCRIPTS" }
			flags       { "OptimizeSize" }

		configuration "vs*"
			defines     { "_CRT_SECURE_NO_WARNINGS" }

		configuration "vs2005"
			defines	{"_CRT_SECURE_NO_DEPRECATE" }

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

		configuration { "ios" }
			deploymenttarget "5.1"

	project "ShaderShaker"

		configuration "Debug"
			targetdir   "bin/debug"

		configuration "Release"
			targetdir   "bin/release"

	project "ShaderShakerDll"
		defines{ "SHADERSHAKER_IN_DLL" }

		configuration "Debug"
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

		configuration "DebugWithoutEmbeddedScripts"
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

