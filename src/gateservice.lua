local skynet = require "skynet"
local socket = require "socket"

skynet.start(function()
	local agent = {}
	for i= 1, 5 do
		agent[i] = skynet.newservice("gate")
	end
	local balance = 1
	local id = socket.listen("0.0.0.0", 8080)
	print("Listen web port 8080")
	socket.start(id , function(id, addr)
		--skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
		skynet.send(agent[balance], "lua", id)
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)
end)
