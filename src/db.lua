local json = require "dkjson"

local m = {}
local path = "./../db/"
function m.get(k)
	local f = io.open(path..k..".txt", "r")
	local s
	if f then
		s = json.decode(f:read("a"))
		f:close()
	end
	return s
end

function m.set(k, v)
	local f = io.open(path..k..".txt", "w")
	local s = json.encode(v)
	if f and s then 
		f:write(s)
		f:close()	
	end
end

function m.delete(k)
	
end

return m