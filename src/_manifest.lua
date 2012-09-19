

return {

    -- language
    
    "language/types.lua",
    "language/intrinsics.lua",
    "language/input.lua",
    "language/output.lua",
    "language/technique.lua",
    "language/texture.lua",
    "language/constant.lua",
    
    -- Intermediate representation
    
    "ir/ast_to_ir.lua",
    
    -- Printer
    
    "printer/printer_manager.lua", -- Must remain first of printer files
    "printer/hlsl_printer.lua",
    
    -- Utilities
    
    "utilities/output.lua",
    "utilities/debug.lua"

}
