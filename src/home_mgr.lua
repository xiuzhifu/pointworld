package.path = package.path..";./../src/?.lua"
local skynet = require "skynet"
local db = require "db"
require "skynet.manager"
local m = {}
local homes = {}
local home = 1
local homecount = 5
local players = {}
local function loadallhomes()
	local db = db.get("playerlist")
	if not db then return end 
	for	k, v in pairs(db) do
		skynet.call(homes[home], "lua", "login", v)
		players[v] = home
		home = (home + 1) % homecount + 1
	end
end

function m.login(id)
	local h = players[id]
	if h then 
		return skynet.call(homes[h], "lua", "login", id), h
	else
		home = (home + 1) % homecount + 1
		players[id] = home
		return skynet.call(homes[home], "lua", "login", id), home
	end
end

function m.unload(id)
	players[id] = nil
	return true
end

function m.gethomes()
	return homes
end

function m.callhome(id, cmd, ...)
	if id and cmd then 
		local h = players[id]
		if h then 
			return skynet.call(homes[h], "lua",	cmd, ...)
		end
	end
	return false
end

skynet.start(function()
	for	i = 1, homecount do
		homes[i] = skynet.newservice("home", i)
	end
	loadallhomes()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = m[command] 
		if f then 
			skynet.ret(skynet.pack(f(...)))
		else
			skynet.error("homemgr error command: "..tostring(command))
		end
		
	end)
	skynet.register "homemgr"
end)