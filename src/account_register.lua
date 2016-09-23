 package.path = package.path..";./../src/?.lua"
local skynet = require "skynet"

local config = require "config"
local db = require "db"
local m = {}
local serverid = config.serverid
local index = 0
function m.genplayerid()
	index = index + 1
	return tostring(serverid)..tostring(os.time())..string.format("%05d", index % 10000)-- 5 + 10 + 17
end

function m.register(username, password, email)
	local user = db.get('account.'..username)
	local id = m.genplayerid()
	if not user then
		db.set('account.'..username, {username = username, password = password, email = email, id = id})
		local t = db.get("playerlist")
		if not t then t = {} end 
		t[#t + 1] = id
		db.set("playerlist", t)
		return "true"
	end
	return "false"
end

function m.modify(username, password, email)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = m[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
end)


