local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local netpack = require "netpack"


local CMD = {}
local SOCKET = {}
local gate
local agent = {}
local waitingagent = {}
local authcount = 10
local authindex = 0
local auth = {}
local watchdog
local maxagent = 0
local minagent = 0

local flag = 9

function SOCKET.open(fd, addr)
	--skynet.error("New client from : " .. addr)
	skynet.call(gate, "lua", "accept", fd)
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
	skynet.send(auth[authindex % authcount + 1], "lua", fd, msg)
	authindex = authindex + 1
end

function CMD.start(conf)
	for i = 1, authcount do
		auth[i] = skynet.newservice("account_auth")
	end
	for i = 1 , maxagent do
		table.insert(waitingagent, skynet.newservice("agent"))
	end
	watchdog = skynet.self()
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

function CMD.open_agent(fd, userid)
	if agent[fd] then return false end
	agent[fd] = 0
	local a = table.remove(waitingagent)
	if not a then a = skynet.newservice("agent") end
	agent[fd] = a
	skynet.call(a, "lua", "start", {fd = fd, gate = gate, watchdog = watchdog, userid = userid})
	return true
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("gate")
	
	skynet.fork(function()
		while true do
			if #waitingagent  >= minagent then return end
			for i = 1, 100 do
				table.insert(waitingagent, skynet.newservice("agent"))
			end
			skynet.sleep(50)
		end
	end
	)
	skynet.register "WATCHDOG"
end)
