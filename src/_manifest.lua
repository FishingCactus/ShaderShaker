

return {

    -- Utilities

    "utilities/copy.lua",
    "utilities/argument_parser.lua",
    "utilities/output.lua",
    "utilities/debug.lua",
    "utilities/iterator.lua",
    "utilities/reflection.lua",
    "utilities/glsl_helper.lua",
    "utilities/string.lua",
    "utilities/tree.lua",

    -- Intermediate representation

    "ir/ast_to_ir.lua",

    -- Printer

    "printer/printer_manager.lua", -- Must remain first of printer files

    -- Code Generator

    "generator/generator_utils.lua",
    "generator/ast_generator.lua",
    "generator/hlsl_generator.lua",
    "generator/glsl_generator.lua",

    -- Process

    "process/semantic/function_collector.lua",
    "process/semantic/shader_generator.lua",

    "process/ast_processor.lua",
    "process/ast_rewrite_if.lua",
    "process/ast_rewrite_constants.lua",
    "process/ast_rewrite_comparison.lua",
    "process/ast_rewriter.lua",
    "process/file_checker.lua",
    --"process/function_replacement.lua",
    "process/function_replacer.lua",
    "process/function_inliner.lua",
    "process/optimizer.lua",
    "process/constants_optimizer.lua",
    "process/shader_parameter_inliner.lua",

    -- Test

    "test/tokenizer.lua"
}
