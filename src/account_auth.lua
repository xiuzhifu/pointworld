package.path = package.path..";./../src/?.lua"
local skynet = require "skynet"
local db = require "db"
local json = require "dkjson"
local account_register
local command = {}

local function auth(username, password)
	if username and password then
		local user = db.get('account.'..username)
		if user then 
			if password == user.password then return user.id end
		end
	end
	return "0"
end

function command:login_auth()
	local s = auth(self.username, self.password)
	local r = {}
	if s ~= "0" then 
		local token, gate = skynet.call("homemgr", "lua", "login", s)
		r = {token = token, gate = gate}
	end
	r = json.encode(r)
	return r
end

function command:login_register()
	local r = "false"
	if self.username and self.password and self.email then
		r = skynet.call(account_register, 'lua', 'register', self.username, self.password, self.email)
	end
	r = {ret = r}
	s = json.encode(r)
	return s
end



skynet.start(function()
	skynet.dispatch("lua", function(session, address, msg)
		msg = json.decode(msg)		
		if not msg then return end
		local f = command[msg.id]
		if f then skynet.ret(skynet.pack(f(msg))) end
	end)
	account_register = skynet.uniqueservice("account_register")
end)


