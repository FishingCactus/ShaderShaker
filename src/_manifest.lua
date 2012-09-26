

return {
    
    -- Intermediate representation
    
    "ir/ast_to_ir.lua",
    
    -- Printer
    
    "printer/printer_manager.lua", -- Must remain first of printer files
    
    -- Code Generator
    
    "generator/ast_generator.lua",
    "generator/hlsl_generator.lua",
    
    -- Utilities
    
    "utilities/output.lua",
    "utilities/debug.lua"

}
