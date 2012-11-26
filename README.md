ShaderShaker [![Build Status](https://travis-ci.org/FishingCactus/ShaderShaker.png)](https://travis-ci.org/FishingCactus/ShaderShaker)
============

Shader Shaker has bee developed to solve our two main problems with shader development : 

- The multiple languages our engine needs to support
- The combinational number of shader with the supported rendering technique

How it works 
------------

The architecture is simple : 

1. The HLSL files are converted to lua AST using a ANTLR parser.
2. The AST is then processed, cleaned and optimized.
3. Finally, a writer generates code.

The AST conversion is done in C++, but every other process is completely done in lua. We choose lua to allow easy customization of the tool.

How to build
------------

Premake is used as project generator. To build the project, follow those steps : 

	premake embed # generate a script to embed all scripts in release mode
	premake vs2010 # or any target you want to use ( gmake, xcode4, ... )

You now have a valid project to build.

How to use 
----------
The tool comes in 2 forms : a binary or a dynamic library.
The first can be used in asset compilation phase, while the latter can be used for runtime code generation. 

To use the command line tools, here are the arguments :

    shader_shaker [options] input_file
    Options can be any of these :
    	-f language : selects language when no output file is given. Supported for now are hlsl, glsl or ast
    	-o output_file : the output file extension is used to select the language ( .fx, .glfx, .ast)
    	-r replacement_file : provides a file use for replacement ( see Function Replacement )

For the moment, the glfx format is specific to our engine, Mojito. It consists of an xml that contains technique definition, similar to an HLSL effect file. But a generic glsl processor will be written soon. 

Function Replacement
--------------------

To manage the combination of shaders, this tools contains a function replacement mechanism. E.g., the same base shader will be used for all type of rendering ( forward, light prepass and deffered ). Function replacement will be used to specialize the base shader. A function called GetLightContribution() might use light parameter while it use a light buffer in other technique. Using `-r`, you can provided a file that contains replacement functions. Function signature will be used to determine which function to replace. 
