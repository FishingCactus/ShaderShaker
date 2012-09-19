

function technique( technique_definition )

    local language_printer = GetSelectedPrinter();
    local representation = AstToIR( technique_definition.vs );

    language_printer.PrintFunctionPrologue( representation, technique_definition.name .. "_vs" )
    language_printer.PrintCode( representation )
    language_printer.PrintFunctionEpilogue( representation )
    
    representation = AstToIR( technique_definition.ps );
        
    language_printer.PrintFunctionPrologue( representation, technique_definition.name .. "_ps" )
    language_printer.PrintCode( representation )
    language_printer.PrintFunctionEpilogue( representation )
    
    language_printer.PrintTechnique( technique_definition.name, technique_definition.name .. "_vs", technique_definition.name .. "_ps" )
    
end