local skynet = require "skynet"
local m = {}
local logname = 'log'
local function send(level, s)
	if type(s) == "string" then 
		s = {s = s}
	end
	s.type = level
	s.time = os.time()
	skynet.send("logger", "lua", s, logname)
end

function m.normal(s)
	send(1, s)
end

function m.warning(s)
	send(2, s)
end

function m.debug(s)
	send(3, s)
end

function m.setloggername(name)
	logname = name
end

return m