local skynet = require "skynet"

skynet.start(function()
	skynet.error("Server start")
	
	skynet.newservice("logger_mongo")
	skynet.newservice("init")
	skynet.newservice("home_mgr")--homemgr started before gateservice 
	skynet.newservice("gateservice")
	skynet.newservice("trade")
	--local console = skynet.newservice("console")
	skynet.newservice("debug_console",8000)
	skynet.exit()
end)
