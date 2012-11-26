-- Heavily inspired by http://snippets.luacode.org/?p=snippets/String_Tokenizer_113


local function _tokenizer(str)
	local yield = coroutine.yield
	local i = 1
	local i1,i2
	local function find(pat)
		i1,i2 = str:find(pat,i)
		return i1 ~= nil
	end
	local function token()
		return str:sub(i,i2)
	end
	while true do
		if find '^%s+' then
			-- ignore
		elseif find '^[%+%-]*%d+' then
			local ilast = i
			i = i2+1 -- just after the sequence of digits
			-- fractional part?
			local _,idx = str:find('^%.%d+',i)
			if idx then
				i2 = idx
				i = i2+1
			end
			-- exponent part?
			_,idx = str:find('^[eE][%+%-]*%d+',i)
			if idx then
				i2 = idx
			end
			i = ilast
			yield('number',tonumber(token()))
		elseif find '^[_%a][_%w]*' then
			yield('iden',token())
		elseif find '^"[^"]*"' or find "^'[^']*'" then
			-- strip the quotes
			yield('string',token():sub(2,-2))
		else -- any other character
			local ch = str:sub(i,i)
			if ch == '' then return 'eof','eof' end
			i2 = i
			yield(ch,ch)
		end
	i = i2+1
	end
end
 
function tokenizer(str)
	return coroutine.wrap(function() _tokenizer(str) end)
end