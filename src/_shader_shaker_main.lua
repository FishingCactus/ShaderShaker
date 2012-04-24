function _shader_shaker_main(scriptpath)

	-- if running off the disk (in debug mode), load everything 
	-- listed in _manifest.lua; the list divisions make sure
	-- everything gets initialized in the proper order.
		
	if (scriptpath) then
		local scripts  = dofile(scriptpath .. "/_manifest.lua")
		for _,v in ipairs(scripts) do
			dofile(scriptpath .. "/" .. v)
		end
	end

end