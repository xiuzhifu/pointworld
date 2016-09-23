local skynet = require "skynet"
local redis = require "redis"
local dbcount = 10
local dbindex = 1 
local dbs = {}
local conf = {
	host = "127.0.0.1" ,
	port = 6379 ,
	db = 0
}

skynet.start(function()
	for	i = 1, dbcount do
		dbs[i] = redis.connect(conf)
	end
	skynet.dispatch("lua", function(_,_, command, k, v)
		local db = dbs[dbindex]
		dbindex = (dbindex  + 1) % 10
		if command == "set" then 
			db:set(k, v)
		else		
			skynet.ret(skynet.pack(db:get(k)))	
		end	
	end)

end)