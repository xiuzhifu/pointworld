local skynet = require "skynet"
require "skynet.manager"
local mongo = require "mongo"
local dbcount = 3
local dbindex = 1 
local dbs = {}
local host = "127.0.0.1"
local dbname = "log"
local systime 


skynet.start(function()
	for	i = 1, dbcount do
		dbs[i] = mongo.client({host = host})
	end
	
	skynet.fork(function()
		dbname = "log-"..os.date("%Y%m%d")
		skynet.sleep(100 * 60)
	end)
	
	skynet.dispatch("lua", function(_,_, data, tablename)
		local db = dbs[dbindex][dbname]
		dbindex = (dbindex  + 1) % dbcount + 1
		local ret = db[tablename]:safe_insert(data)
		assert(ret and ret.n == 1)
	end)

	skynet.register "logger"
end)