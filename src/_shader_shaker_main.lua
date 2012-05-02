function _shader_shaker_main(script_path, output_file)

	-- if running off the disk (in debug mode), load everything 
	-- listed in _manifest.lua; the list divisions make sure
	-- everything gets initialized in the proper order.
		
	if script_path then
		local scripts  = dofile(script_path .. "/_manifest.lua")
		for _,v in ipairs(scripts) do
			dofile(script_path .. "/" .. v)
		end
	end
	
	
	if output_file ~= nil then
		InitializeOutputFile( output_file )
	else
		InitializeOutputPrint()
	end

end