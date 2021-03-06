local PrinterTable = {}
local SelectedPrinter

function RegisterPrinter( printer, name, file_extension )

    PrinterTable[ name ] = { printer = printer, extension = file_extension };
end


function GetSelectedPrinter()
    if SelectedPrinter == nil then
        error( "No printer selected" )
    end
    return SelectedPrinter
end

function SelectPrinter( filename, override_name )

    if override_name ~= nil then
        if PrinterTable[ override_name ] == nil then
            error( "Invalid language name" )
        end

        SelectedPrinter = PrinterTable[ override_name ].printer
        return
    end

    if filename == "console_output" then
        error( "Language should be specified when outputing to the console" )
    end

    local
        extension = nil

    for index = string.len( filename ), 1, -1 do
        local character = string.sub( filename, index, index )
        if character == '.' then
            extension = string.sub( filename, index + 1 )
            break
        end
    end

    if extension == nil then
        error( "Unable to extract file extension" );
    end

    for name, description in pairs( PrinterTable ) do

        if description.extension == extension then
            SelectedPrinter = description.printer
            return
        end

    end

    error( "Unable to detect language from file extension" )
end