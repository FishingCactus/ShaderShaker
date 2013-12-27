local arguments = {}

function _shader_shaker_main( script_path, argument_table )

    -- if running off the disk (in debug mode), load everything
    -- listed in _manifest.lua; the list divisions make sure
    -- everything gets initialized in the proper order.

    if script_path then
        local scripts  = dofile(script_path .. "/_manifest.lua")
        for _,v in ipairs(scripts) do
            dofile( script_path .. "/" .. v )
        end
    end

    cli:set_name("shader_shaker arguments")
    cli:add_arg("INPUT", "path to the input file")
    cli:optarg("REPLACEMENT_FILES", "Path to a replacement file", nil, 32 )

    cli:add_opt("-o,--output=OUTPUT_FILE", "Output file path", "")
    cli:add_opt("-f,--format=FORCE_LANGUAGE", "Force the output language", "")
    cli:add_opt("-dp,--default_precision=DEFAULT_PRECISION", "Default precision ( OpenGL only )", "highp")
    cli:add_opt("-c,--check=CHECK_FILE", "The file to check with", "" )
    cli:add_opt("-cr,--constants_replacement=CONSTANTS_REPLACEMENT", "Constants replacement", "" )

    cli:add_opt("--ri", "Activate inline replacement", false )
    cli:add_opt("-O,--optimize", "Run optimizer", true )
    cli:add_opt("--dnesfs", "Do Not Export Sampler Filter Semantic ( For XBox 360 )", false )

    arguments = cli:parse( argument_table )
end


function _shaker_shaker_process_files()

    if arguments.error ~= nil then
        decoda_output( arguments.error )
        return
    end

    print( "Processing " .. arguments.INPUT )

    local
        ast = AstProcessor.Process( arguments )

    if arguments.check ~= "" then

        FileChecker.Process( options.check, ast )

        collectgarbage()
        return 0

    else
        local ast_copy = DeepCopy( ast )

        SelectPrinter( arguments.o, arguments.f )

        if arguments.o ~= "console_output" then
            InitializeOutputFile( arguments.o )
        else
            InitializeOutputPrint()
        end

        GetSelectedPrinter().ProcessAst( ast_copy, arguments )
    end

    collectgarbage()
    return 0
end