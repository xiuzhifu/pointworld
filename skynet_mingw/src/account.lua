local skynet = require "skynet"
local redis = require "redis"
local CMD = {}

function CMD.auth(username, password)
end

function CMD.register(username, password, email)
end
skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(subcmd, ...)))
	end)
end)